function ADCmean = diff_analysis_bids(bidsfold)
%%
if nargin < 1
    bidsfold = uigetdir([],'Select the bids format folder for the participant');
end
%% Read in images and b values
diff_path = struct2cell(dir(fullfile(bidsfold,'xedwi')));
myind = find(contains(diff_path(1,:),'.nii.gz'));

% Some niftis write out as single slices, so need to handle that here.
if length(myind) > 9
    slice_ind = zeros(length(myind),1);
    for i = 1:length(myind)
        tmp = diff_path{1,myind(i)};
        uscores = strfind(tmp,'_');
        dot = strfind(tmp,'.nii.gz');
        my_n = tmp((uscores(end)+1):(dot-1));
        slice_ind(i) = str2double(my_n);
    end
    
    [~,sort_ind] = sort(slice_ind);
else
    sort_ind = 1:length(myind);
end


I_Diff = double(niftiread(fullfile(diff_path{2,myind(sort_ind(1))},diff_path{1,myind(sort_ind(1))})));
for i = 2:length(myind)
    tmpim = double(niftiread(fullfile(diff_path{2,myind(sort_ind(i))},diff_path{1,myind(sort_ind(i))})));
    I_Diff = cat(3,I_Diff,tmpim);
end

if ndims(I_Diff) > 3
    I_Diff = cat(3,I_Diff(:,:,:,:,2),I_Diff(:,:,:,:,1));
    I_Diff = flip(rot90(I_Diff,2),3);
end

newind = find(contains(diff_path(1,:),'.bval'));
fileID = fopen(fullfile(diff_path{2,newind},diff_path{1,newind}),'r');
bval = fscanf(fileID,'%f');



%% Images are rotated funny in matlab - rotate for correct matlab orientation
I_Diff = fliplr(rot90(I_Diff));

%% Separate into b0 and b12 images; calculate ADC
Ntot = size(I_Diff,3);

b0 = I_Diff(:,:,1:(Ntot/2));
b12 = I_Diff(:,:,(Ntot/2+1):end);

ADC = -1/bval(2)*log(b12./b0);

%% Mask
try
   load(fullfile(bidsfold,'xedwi','Diffusion_Analysis.mat'),'mask')
catch
    try
        [tmp_fold,~,~] = fileparts(bidsfold);
        load(fullfile(tmp_fold,'DiffMask_Manual'),'mask');
        mask = imresize3(mask,[size(ADC)]);
        mask = flip(mask,3);
    catch 
        [~,mask] = ImTools.erode_dilate(b12,2,20);
    end
end
mask = ImTools.gen_mask_itk(b0,mask,ADC);
mask = double(mask);
%% Display
Cmap = parula(256);
Cmap(1,:) = [0 0 0];
figure('Name','ADC Map')
montage(ADC.*mask)
colormap(Cmap);
caxis([0 0.14]);

tmp = ADC(mask==1);
tmp(isnan(tmp)) = [];
tmp(isinf(tmp)) = [];
tmp(tmp<0) = [];
ADCmean = mean(tmp);

%% Save Results
save(fullfile(bidsfold,'xedwi','Diffusion_Analysis.mat'));

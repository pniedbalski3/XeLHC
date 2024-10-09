function ADCmean = diff_analysisDICOM_bids(bidsfold)
%%
if nargin < 1
    bidsfold = uigetdir([],'Select the bids format folder for the participant');
end
%% Read in images and b values
diff_path = struct2cell(dir(fullfile(bidsfold,'xedwi')));
myind = find(contains(diff_path(1,:),'.nii.gz'));

Ims = double(niftiread(fullfile(diff_path{2,myind(1)},diff_path{1,myind(1)})));
for i = 2:length(myind)
    tmpim = double(niftiread(fullfile(diff_path{2,myind(i)},diff_path{1,myind(i)})));
    Ims = cat(3,Ims,tmpim);
end

newind = find(contains(diff_path(1,:),'.bval'));
fileID = fopen(fullfile(diff_path{2,newind},diff_path{1,newind}));
bvals = fscanf(fileID);
% 
% try
%     mrd_files = ReadData.get_mrd(mypath);
%     if isempty(mrd_files.diff)
%         error('No Diff');
%     end
% catch
%     %% Get files
%     files = dir(fullfile(mypath,'Raw'));
%     Cell_files = struct2cell(files);
%     file_names = Cell_files(1,:);
%     folder_names = Cell_files(2,:);
% 
%     %% Find Diffusion File
%     xeprot = 'HPG_Diffusion';
%     xe_file = file_names{find(contains(file_names,xeprot),1,'last')};
%     xe_fold = folder_names{find(contains(file_names,xeprot),1,'last')};
% 
%     xe_file = fullfile(xe_fold,xe_file);
%     %% Find Subject ID
%     Subj_ID = get_subject(mypath);
% 
%     %% Convert to MRD
%     diff2mrd(Subj_ID,xe_file);
%     %% Find the MRD that was just written
%     mrd_files = ReadData.get_mrd(mypath);
% end
% 
% %% Reconstruct Diffusion Images
% [~,~,bval] = Reconstruct.gre_recon(mrd_files.diff{1});
% 
% %% Perhaps pull DICOMs instead
% I_Diff = ImTools.DICOM_Load();
% 
% b0 = I_Diff(:,:,1:7);
% b12 = I_Diff(:,:,8:end);
% 
% %% Get b-val images and ADC
% %b0 = squeeze(I_Diff(:,:,1,:));
% %b12 = squeeze(I_Diff(:,:,2,:));
% try
%     ADC = -1/bval(2)*log(b12./b0);
% catch
%     b0 = I_Diff(:,:,1:6);
%     b12 = I_Diff(:,:,7:end);
%     ADC = -1/bval(2)*log(b12./b0);
% end
% 
% %% Mask
% try
%    load(fullfile(mypath,'Diffusion_Analysis_DICOM.mat'),'mask')
% catch
%     try
%         load(fullfile(mypath,'Diffusion_Analysis.mat'),'mask')
%         mask = imresize3(mask,size(ADC));
%     catch
%         [~,mask] = ImTools.erode_dilate(b12,2,20);
%     end
% end
% mask = ImTools.gen_mask_itk(b0,mask);
% mask = double(mask);
% %% Display
% Cmap = parula(256);
% Cmap(1,:) = [0 0 0];
% figure('Name','ADC Map')
% montage(ADC.*mask)
% colormap(Cmap);
% caxis([0 0.14]);
% 
% ADCmean = mean(ADC(mask==1));
% 
% %% Save Results
% save(fullfile(mypath,'Diffusion_Analysis_DICOM.mat'));

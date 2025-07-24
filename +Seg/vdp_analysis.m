function VDP_N4 = vdp_analysis(bidsfold,checkmask)
%% Get folder if none is provided
if nargin < 1
    bidsfold = uigetdir([],'Select the bids format folder for the participant');
    checkmask = 1;
end
if nargin < 2
    checkmask = 1;
end
%% Load in Images
vent_path = struct2cell(dir(fullfile(bidsfold,'xevent')));
myindv = find(contains(vent_path(1,:),'vent.nii.gz'));
if length(myindv) > 1
    myindv = myindv(1);
end

vent_full_path = fullfile(vent_path{2,myindv},vent_path{1,myindv});
vent = squeeze(double(niftiread(fullfile(vent_path{2,myindv},vent_path{1,myindv}))));

anat_path = struct2cell(dir(fullfile(bidsfold,'anat')));
myinda = find(contains(anat_path(1,:),'T1w.nii.gz'));

anat_full_path = fullfile(anat_path{2,myinda},anat_path{1,myinda});
anat = double(niftiread(fullfile(anat_path{2,myinda},anat_path{1,myinda})));

if size(anat,1) ~= size(vent,1) | size(anat,2) ~= size(vent,2) | size(anat,3) ~= size(vent,3)
    anat = permute(anat,[1 3 2]);
    anat = flip(anat,3);
    anat = imresize3(anat,size(vent));
end

%% Mask image (if needed)
maskpath = fullfile(anat_path{2,myinda},strrep(anat_path{1,myinda},'T1w.nii.gz','ventmask.nii.gz'));

if ~isfile(maskpath)
    try
        mask = Seg.docker_segment(abs(anat));
        %Need to write Mask to bids:
        writemask = ReadData.mat2canon(mask);
        niftiwrite(mask,fullfile(anat_path{2,myinda},strrep(anat_path{1,myinda},'T1w.nii.gz','ventmask')),'Compressed',true);
    catch
        [~,mask] = erode_dilate(vent,1,7);
        % writemask = ReadData.mat2canon(mask);
        niftiwrite(mask,fullfile(anat_path{2,myinda},strrep(anat_path{1,myinda},'T1w.nii.gz','ventmask')),'Compressed',true);
    end
end
%% Now, I should be able to load these files into ITK-snap for checking:
if checkmask
    itk_path = ImTools.get_itk_path();
    ITKSNAP_Path = ['"C:\Program Files\' itk_path '\bin\ITK-SNAP.exe"'];

    mycommand = [ITKSNAP_Path ' -g "' vent_full_path '" -o "' anat_full_path '" -s "' maskpath '"'];
    system(mycommand);
end
mask = niftiread(maskpath);
%% Image scaling and Bias Correction

vent = vent/prctile(vent(mask==1),99);
vent_N4 = double(Seg.strong_N4(vent,mask));
vent_N4 = vent_N4/prctile(vent_N4(mask==1),99);

%% This should pause until the user closes ITK-Snap.
%Now, I should have a decent mask, and I can calculate VDP. For now, use
%60% threshold... In the future, expand.
for j = 1:size(vent,3)
    imseg(:,:,j) = Seg.vdp60(vent(:,:,j),mask(:,:,j));
end

VDP = (nnz(imseg ==1) + nnz(imseg==2))./nnz(mask) * 100;

for j = 1:size(vent,3)
    imseg_N4(:,:,j) = Seg.vdp60(vent_N4(:,:,j),mask(:,:,j));
end

VDP = (nnz(imseg ==1) + nnz(imseg==2))./nnz(mask) * 100;
VDP_N4 = (nnz(imseg_N4 ==1) + nnz(imseg_N4==2))./nnz(mask) * 100;

%% Display a summary image:
vent2 = fliplr(rot90(vent_N4));
imseg2 = fliplr(rot90(imseg_N4));

tilevent = imtile(vent2);
tileseg = imtile(imseg2);

CMap = [1 0 0;1 0.7143 0; 0 1 0;0 0 1];
figure('Name','Ventilition Defect Analysis','Position',[515 62 855 878])
ImTools.imoverlay(tilevent,tileseg,[1 4],[0,prctile(vent(mask==1),99)],CMap,0.5,gca);
colormap(CMap);

%% Copy files to Ventilation_Analysis Folder and run some additional analysis
[newpath,~,~]=fileparts(bidsfold);

analysis_fold = fullfile(newpath,'Ventilation_Analysis');

if ~isfolder(analysis_fold)
    mkdir(analysis_fold);
end

[~,ventname,ventext] = fileparts(vent_full_path);
[~,maskname,maskext] = fileparts(maskpath);

myinfo = niftiinfo(vent_full_path);
myinfo.Datatype = 'double';
niftiwrite(vent_N4,fullfile(analysis_fold,strrep([ventname,ventext],'vent','ventn4')),myinfo,'Compressed',true)
copyfile(vent_full_path,analysis_fold);
copyfile(maskpath,analysis_fold);

Seg.docker_vdp(fullfile(analysis_fold,[ventname ventext]),fullfile(analysis_fold,[maskname,maskext]));
Seg.docker_vdp(fullfile(analysis_fold,strrep([ventname,ventext],'vent','ventn4')),fullfile(analysis_fold,[maskname,maskext]));

%% Need k-means as well
mask = double(mask);
[~,kmeans_seg] = API.VDP_calculation(vent,mask);
[~,n4kmeans_seg] = API.VDP_calculation(vent_N4,mask);

%% Linear binning - Fix these thresholds
[path1,~,~] = fileparts(bidsfold);
[Data_Path,Participant,~] = fileparts(path1);
load(fullfile(Data_Path,'QC','Vent_LB_Ref.mat'));
vent_bin = Reconstruct.bin_images(vent,vent_thresh);
vent_bin = vent_bin.*mask;
ventn4_bin = Reconstruct.bin_images(vent_N4,ventn4_thresh);
ventn4_bin = ventn4_bin.*mask;

%% Create loops for ease:
%1 = 60%, 2 = linear binning, 3 = k-means, 4 = c-means, 5 = atropos, 6 = el
%bicho
segs(:,:,:,1) = imseg;
segs(:,:,:,2) = vent_bin;
segs(:,:,:,3) = kmeans_seg;
segs(:,:,:,4) = double(niftiread(fullfile(analysis_fold,strrep([ventname,ventext],'vent','vent_cmeans'))));
segs(:,:,:,5) = double(niftiread(fullfile(analysis_fold,strrep([ventname,ventext],'vent','vent_atropos'))));
segs(:,:,:,6) = double(niftiread(fullfile(analysis_fold,strrep([ventname,ventext],'vent','vent_elbicho'))));
segsn4(:,:,:,1) = imseg_N4;
segsn4(:,:,:,2) = ventn4_bin;
segsn4(:,:,:,3) = n4kmeans_seg;
segsn4(:,:,:,4) = double(niftiread(fullfile(analysis_fold,strrep([ventname,ventext],'vent','ventn4_cmeans'))));
segsn4(:,:,:,5) = double(niftiread(fullfile(analysis_fold,strrep([ventname,ventext],'vent','ventn4_atropos'))));
segsn4(:,:,:,6) = double(niftiread(fullfile(analysis_fold,strrep([ventname,ventext],'vent','ventn4_elbicho'))));

%% Write to excel


excel_file = fullfile(Data_Path,'QC','Vent_Analysis.xlsx');
matfile = fullfile(Data_Path,'QC','Vent_Analysis.mat');

mymatch = [];
% No bias correction
try 
    load(matfile,'AllAnalysis');
    mymatch = find(strcmpi(AllAnalysis.Participant,Participant));
catch
    headers = {'Participant',...
        'Thresh1','Thresh2','Thresh3','Thresh4','Thresh5','Thresh6',...
    'LinBin1','LinBin2','LinBin3','LinBin4','LinBin5','LinBin6',...
    'kmeans1','kmeans2','kmeans3','kmeans4','kmeans5','kmeans6',...
    'cmeans1','cmeans2','cmeans3','cmeans4','cmeans5','cmeans6',...
    'atropos1','atropos2','atropos3','atropos4','atropos5','atropos6',...
    'elbicho1','elbicho2','elbicho3','elbicho4','elbicho5','elbicho6',...
    };
    AllAnalysis = cell2table(cell(0,size(headers,2)));
    AllAnalysis.Properties.VariableNames = headers;
end

NewData{1,1} = Participant;
for i = 1:size(segs,4)
    for j = 1:6 
        tmp = segs(:,:,:,i);
        NewData{1,1+(i-1)*size(segs,4)+j} = nnz(tmp == j)/nnz(mask==1)*100;
    end
end

if isempty(mymatch)
    AllAnalysis = [AllAnalysis;NewData];
else
    AllAnalysis(mymatch,:) = NewData;
end

AllAnalysis = sortrows(AllAnalysis);

save(matfile,'AllAnalysis')
writetable(AllAnalysis,excel_file,'Sheet',1)



% N4 Corrected data
clear NewData;
excel_file = fullfile(Data_Path,'QC','Vent_Analysis_N4.xlsx');
matfile = fullfile(Data_Path,'QC','Vent_Analysis_N4.mat');

mymatch = [];
try 
    load(matfile,'AllAnalysisN4');
    mymatch = find(strcmpi(AllAnalysisN4.Participant,Participant));
catch
    headers = {'Participant',...
        'Thresh1','Thresh2','Thresh3','Thresh4','Thresh5','Thresh6',...
    'LinBin1','LinBin2','LinBin3','LinBin4','LinBin5','LinBin6',...
    'kmeans1','kmeans2','kmeans3','kmeans4','kmeans5','kmeans6',...
    'cmeans1','cmeans2','cmeans3','cmeans4','cmeans5','cmeans6',...
    'atropos1','atropos2','atropos3','atropos4','atropos5','atropos6',...
    'elbicho1','elbicho2','elbicho3','elbicho4','elbicho5','elbicho6',...
    };
    AllAnalysisN4 = cell2table(cell(0,size(headers,2)));
    AllAnalysisN4.Properties.VariableNames = headers;
end

NewData{1,1} = Participant;
for i = 1:size(segs,4)
    for j = 1:6 
        tmp = segsn4(:,:,:,i);
        NewData{1,1+(i-1)*size(segs,4)+j} = nnz(tmp == j)/nnz(mask==1)*100;
    end
end

if isempty(mymatch)
    AllAnalysisN4 = [AllAnalysisN4;NewData];
else
    AllAnalysisN4(mymatch,:) = NewData;
end

AllAnalysisN4 = sortrows(AllAnalysisN4);

save(matfile,'AllAnalysisN4')
writetable(AllAnalysisN4,excel_file,'Sheet',1)






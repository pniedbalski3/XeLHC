function disp_images(participant_folder)

%% Get BIDS folder
folders = dir(participant_folder);
folders = struct2cell(folders);
getnames = folders(1,:);
myfolderind = find(contains(getnames,'sub-'));
bidsfolder = getnames{myfolderind};

%% Find Ventilation Image and Display
ventfiles = dir(fullfile(participant_folder,bidsfolder,'xevent'));
ventfiles = struct2cell(ventfiles);
myventfiles = ventfiles(1,:);
myventind = find(contains(myventfiles,'.nii'));
myventfile = fullfile(participant_folder,bidsfolder,'xevent',myventfiles{myventind});
vent_Im = double(niftiread(myventfile));

vent_Im = fliplr(rot90(vent_Im));
figure('Name','Ventilation_Image')
montage(vent_Im./max(vent_Im(:)));

%% Find Diffusion Image and Display
load(fullfile(participant_folder,'Diffusion_Analysis.mat'));

figure('Name','Diffusion_Image')
montage(ADC.*mask);
CMAP = parula(256);
CMAP(1,:) = [0 0 0];
colormap(CMAP)
clim([0 0.14])

%% Display Gas Exchange Images
ventfiles = dir(fullfile(participant_folder,bidsfolder,'xegx'));
ventfiles = struct2cell(ventfiles);
myventfiles = ventfiles(1,:);
myventind = find(contains(myventfiles,'.nii') & contains(myventfiles,'dis'));
myventfile = fullfile(participant_folder,bidsfolder,'xegx',myventfiles{myventind});
dis_Im = double(niftiread(myventfile));

dis_Im = ReadData.canon2mat(dis_Im);
figure('Name','Dissolved Image');
montage(dis_Im/max(abs(dis_Im(:))));


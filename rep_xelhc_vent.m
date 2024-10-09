function vent_fig_handle = rep_xelhc_vent(participant_folder)

if nargin < 1
    participant_folder = uigetdir();
end

%% Change this to pull the n4 corrected folder
sub_folds = dir(fullfile(participant_folder,'Ventilation_Analysis'));
sub_folds = struct2cell(sub_folds);
names = sub_folds(1,:);
vent_ind = find(contains(names,'ventn4.nii.gz'));
%vent_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'xevent');

%vent_files = dir(vent_fold);
%vent_files = struct2cell(vent_files);
%vent_files = vent_files(1,:);
%vent_ind = find(contains(vent_files,'_vent.nii.gz'));
%vent_ind = vent_ind(1);

%mask_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'anat');
%mask_files = dir(mask_fold);
%mask_files = struct2cell(mask_files);
%mask_files = mask_files(1,:);
mask_ind = find(contains(names,'ventmask.nii.gz'));

%vent_path = fullfile(vent_fold,vent_files{1,vent_ind});
vent_path = fullfile(participant_folder,'Ventilation_Analysis',names{vent_ind(1)});
vent = double(niftiread(vent_path));

%mask_path = fullfile(mask_fold,mask_files{1,mask_ind});
mask_path = fullfile(participant_folder,'Ventilation_Analysis',names{mask_ind(1)});
mask = double(niftiread(mask_path));

vent = vent/prctile(vent(mask==1),99);

figure('Name','Representative_Vent')
imagesc(fliplr(rot90(squeeze(vent(:,:,floor(size(vent,3)/2))))));
axis off
colormap("gray");
axis square;
clim([0 1]);

vent_fig_handle = gca; %= myax.Children;
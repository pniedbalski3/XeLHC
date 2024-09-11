function vent_fig_handle = rep_xelhc_vent(participant_folder)

if nargin < 1
    participant_folder = uigetdir();
end


sub_folds = dir(participant_folder);
sub_folds = struct2cell(sub_folds);
names = sub_folds(1,:);
fold_ind = find(contains(names,'sub-'));
vent_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'xevent');

vent_files = dir(vent_fold);
vent_files = struct2cell(vent_files);
vent_files = vent_files(1,:);
vent_ind = find(contains(vent_files,'.nii.gz'));

mask_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'anat');
mask_files = dir(mask_fold);
mask_files = struct2cell(mask_files);
mask_files = mask_files(1,:);
mask_ind = find(contains(mask_files,'ventmask.nii.gz'));

vent_path = fullfile(vent_fold,vent_files{1,vent_ind});
vent = double(niftiread(vent_path));

mask_path = fullfile(mask_fold,mask_files{1,mask_ind});
mask = double(niftiread(mask_path));

vent = vent/prctile(vent(mask==1),97);

figure('Name','Representative_Vent')
imagesc(fliplr(rot90(squeeze(vent(:,:,floor(size(vent,3)/2))))));
axis off
colormap("gray");
axis square;
clim([0 1]);

vent_fig_handle = gca; %= myax.Children;
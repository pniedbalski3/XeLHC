function review_vent(participant_folder)

sub_folds = dir(participant_folder);

sub_folds = struct2cell(sub_folds);

names = sub_folds(1,:);

fold_ind = find(contains(names,'sub-'));

vent_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'xevent');

vent_files = dir(vent_fold);
vent_files = struct2cell(vent_files);
vent_files = vent_files(1,:);
vent_ind = find(contains(vent_files,'.nii.gz'));

vent_path = fullfile(vent_fold,vent_files{1,vent_ind});

itk_path =  ImTools.get_itk_path;%'"C:\Program Files\ITK-SNAP 4.0\bin\ITK-SNAP.exe"';
ITKSNAP_Path = ['"C:\Program Files\' itk_path '\bin\ITK-SNAP.exe"'];
mycommand = [ITKSNAP_Path ' -g "' vent_path '"'];
system(mycommand);




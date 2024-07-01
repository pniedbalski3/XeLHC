function review_dwi(participant_folder)

sub_folds = dir(participant_folder);

sub_folds = struct2cell(sub_folds);

names = sub_folds(1,:);

fold_ind = find(contains(names,'sub-'));

diff_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'xedwi');

diff_files = dir(diff_fold);
diff_files = struct2cell(diff_files);
diff_files = diff_files(1,:);
diff_ind = find(contains(diff_files,'.nii.gz'));

diff_path{1} = fullfile(diff_fold,diff_files{1,diff_ind(1)});
diff_path{2} = fullfile(diff_fold,diff_files{1,diff_ind(2)});

ITKSNAP_Path = '"C:\Program Files\ITK-SNAP 4.0\bin\ITK-SNAP.exe"';

mycommand = [ITKSNAP_Path ' -g "' diff_path{1} '" -o "' diff_path{2} '"'];
system(mycommand);

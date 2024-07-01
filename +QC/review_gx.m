function review_gx(participant_folder)

sub_folds = dir(participant_folder);

sub_folds = struct2cell(sub_folds);

names = sub_folds(1,:);

fold_ind = find(contains(names,'sub-'));

gx_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'xegx');

gx_files = dir(gx_fold);
gx_files = struct2cell(gx_files);
gx_files = gx_files(1,:);
gas_ind1 = find(contains(gx_files,'sgas.nii.gz'));
gas_ind = find(contains(gx_files,'bgas.nii.gz'));
dis_ind = find(contains(gx_files,'dis.nii.gz'));
mem_ind = find(contains(gx_files,'gxmem.nii.gz'));
rbc_ind = find(contains(gx_files,'gxrbc.nii.gz'));

gx_path{1} = fullfile(gx_fold,gx_files{1,gas_ind1});
gx_path{2} = fullfile(gx_fold,gx_files{1,gas_ind});
gx_path{3} = fullfile(gx_fold,gx_files{1,dis_ind});
gx_path{4} = fullfile(gx_fold,gx_files{1,mem_ind});
gx_path{5} = fullfile(gx_fold,gx_files{1,rbc_ind});

ITKSNAP_Path = '"C:\Program Files\ITK-SNAP 4.0\bin\ITK-SNAP.exe"';

% Need to add mem and RBC, but first need to run code to do all that
% analysis.
mycommand = [ITKSNAP_Path ' -g "' gx_path{1} '" -o "' gx_path{2} '" "' gx_path{3} '"'];
system(mycommand);
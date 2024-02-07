function [Vent_Fold,Vent_Anat_Fold,Diff_Fold] = find_dicoms(participant_folder)

% if ispc
%     All_files = dir(fullfile(participant_folder,'**\*'));
% else
%     All_files = dir(fullfile(participant_folder,'**/*'));
% end

All_files = dir(fullfile(participant_folder,'DICOM'));

All_files = struct2cell(All_files);

filenames = All_files(1,:);
folders = All_files(2,:);

dcm_indx = find(contains(filenames,'.dcm'));

if isempty(dcm_indx)
    dcm_indx = find(contains(filenames,'.IMA'));
end


%% Read DICOM Headers
series_no = zeros(length(dcm_indx),1);
ProtName{length(dcm_indx),1} = '';
Nucleus{length(dcm_indx),1} = '';

for i = 1:length(dcm_indx)
    tmpinfo = dicominfo(fullfile(folders{dcm_indx(i)},filenames{dcm_indx(i)}));
    series_no(i) = tmpinfo.SeriesNumber;
    ProtName{i,1} = tmpinfo.ProtocolName;
    Nucleus{i,1} = tmpinfo.ImagedNucleus;
end

%% Find the latest Ventilation Series:
try
    Vent_GRE_ind = contains(ProtName,'vent','IgnoreCase',true) & contains(Nucleus,'Xe','IgnoreCase',true);
    
    last_vent_series = max(series_no(Vent_GRE_ind));
    
    Vent_target_ind = contains(ProtName,'vent','IgnoreCase',true) & contains(Nucleus,'Xe','IgnoreCase',true) & series_no == last_vent_series;
    
    Vent_target_index = find(Vent_target_ind);
    
    %% Make folder for ventilation images and copy DICOMS to there
    Vent_Fold = fullfile(folders{dcm_indx(Vent_target_index(1))},'Vent');
    if ~isfolder(Vent_Fold)
        mkdir(Vent_Fold);
    
    
        for i = 1:length(Vent_target_index)
            copyfile(fullfile(folders{dcm_indx(Vent_target_index(i))},filenames{dcm_indx(Vent_target_index(i))}),Vent_Fold);
        end
    end
catch
    disp('Failed to find Ventilation Image')
    Vent_Fold = [];
end
%% Find the latest Ventilation Anatomic Series:
try
    Anat_GRE_ind = contains(ProtName,'vent','IgnoreCase',true) & contains(Nucleus,'H','IgnoreCase',true);
    
    last_anat_series = max(series_no(Anat_GRE_ind));
    
    Anat_target_ind = contains(ProtName,'vent','IgnoreCase',true) & contains(Nucleus,'H','IgnoreCase',true) & series_no == last_anat_series;
    Anat_target_index = find(Anat_target_ind);
    
    %% Make folder for ventilation anatomic images and copy DICOMS to there
    Vent_Anat_Fold = fullfile(folders{dcm_indx(Anat_target_index(1))},'Vent_Anat');
    if ~isfolder(Vent_Anat_Fold)
        mkdir(Vent_Anat_Fold);
    
    
        for i = 1:length(Anat_target_index)
            copyfile(fullfile(folders{dcm_indx(Anat_target_index(i))},filenames{dcm_indx(Anat_target_index(i))}),Vent_Anat_Fold);
        end
    end
catch
    disp('Failed to find Ventilation Anatomic Image');
    Vent_Anat_Fold = [];
end
%% Find the latest Diffusion Series:
try
    Diff_ind = contains(ProtName,'Diff','IgnoreCase',true) & contains(Nucleus,'Xe','IgnoreCase',true);
    
    last_diff_series = max(series_no(Diff_ind));
    
    diff_target_ind = contains(ProtName,'Diff','IgnoreCase',true) & contains(Nucleus,'Xe','IgnoreCase',true) & series_no == last_diff_series;
    diff_target_index = find(diff_target_ind);
    
    %% Make folder for ventilation anatomic images and copy DICOMS to there
    Diff_Fold = fullfile(folders{dcm_indx(diff_target_index(1))},'Diff');
    if ~isfolder(Diff_Fold)
        mkdir(Diff_Fold);
    
    
        for i = 1:length(diff_target_index)
            copyfile(fullfile(folders{dcm_indx(diff_target_index(i))},filenames{dcm_indx(diff_target_index(i))}),Diff_Fold);
        end
    end
catch
    disp('Failed to find Diffusion Image')
    Diff_Fold = [];
end
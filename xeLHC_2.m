function xeLHC_2(participant_folder)
%%
[~,subj,~] = fileparts(participant_folder);
while subj(1) ~= 'C'
    subj(1) = [];
end

%% write raw data to P-drive location
P_loc_raw = 'P:\IRB_STUDY00149906_XeLHC\XeLHC_CLEAN\sourcedata';
Raw_locA = fullfile(P_loc_raw,['sub-' subj]);
if ~isfolder(Raw_locA)
    mkdir(Raw_locA);
end
Raw_locB = fullfile(P_loc_raw,['sub-' subj],'mrd');
if ~isfolder(Raw_locB)
    mkdir(Raw_locB);
end
Raw_locC = fullfile(P_loc_raw,['sub-' subj],'dicom');
if ~isfolder(Raw_locC)
    mkdir(Raw_locC);
end

mrd_files = ReadData.get_mrd(participant_folder);
fields = fieldnames(mrd_files);
for iField = 1:numel(fields)
    f = fields{iField};
    values = mrd_files.(f);
    for idx = 1:numel(values)
        value = values{idx};
        copyfile(value,Raw_locB);
    end
end

DICOM_fold = fullfile(participant_folder,'DICOM');
if ~isfolder(DICOM_fold)
    DICOM_fold = fullfile(participant_folder,'dicom');
end
if isfolder(DICOM_fold)
    copyfile(DICOM_fold,Raw_locC);
end


%% write data to bids format in the P-Drive
P_loc = 'P:\IRB_STUDY00149906_XeLHC\XeLHC_CLEAN\rawdata';
bids_path = xebids(participant_folder,P_loc);

%% Check that Raw data is in good shape
R2M = rawdata_check(participant_folder);

%% Run ventilation analysis
P_loc2 = 'P:\IRB_STUDY00149906_XeLHC\XeLHC_CLEAN\derivatives\Ventilation';
Vent_analysis_fold = fullfile(P_loc2,['sub-' subj]);
if ~isfolder(Vent_analysis_fold)
    mkdir(Vent_analysis_fold)
end

batch_XIPLine(bids_path,Vent_analysis_fold);

%% Run Diffusion Analysis
P_loc3 = 'P:\IRB_STUDY00149906_XeLHC\XeLHC_CLEAN\derivatives\Diffusion';
DWI_analysis_fold = fullfile(P_loc3,['sub-' subj]);
if ~isfolder(DWI_analysis_fold)
    mkdir(DWI_analysis_fold)
end

batch_Raw_ADC_XIPLine(participant_folder,DWI_analysis_fold);

%% Write out Config File for Duke GX pipeline
P_loc4 = 'P:\IRB_STUDY00149906_XeLHC\XeLHC_CLEAN\derivatives\GX_Config_Files';

mrd_files = ReadData.get_mrd(Raw_locB);
vals.make = [];
if isempty(mrd_files.ute) || contains(subj,'CACB')
    vals.no1H = true;
end
if contains(subj,'CACB') || contains(subj,'CAAA')
    [vals.r2m,~,~,~,~,~,~,~,~,~] = quick_cal(my_mrd.cal{1});
    close
end
gx_data_path = Raw_locB;
gx_data_path = strrep(gx_data_path,'\','/');
gx_data_path(1:2) = [];
gx_data_path = ['/Volumes/data/ProtectedData' gx_data_path];

config_name = fullfile(P_loc4,['config_' subj '.py']);

template = char("C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\Duke_Config_Template.py");
write_config_2(template, config_name, gx_data_path, subj, vals);






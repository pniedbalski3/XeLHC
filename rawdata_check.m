function R2M = rawdata_check(participant_folder)

%% Option to have User select folder
if nargin < 1
    participant_folder = uigetdir();
end

%% Clean up all windows before we get started
close all;

%% Find Files
mrd_files = ReadData.get_mrd(participant_folder);

QC.scans_present(mrd_files);

%% Check Dates and Participants
try
    QC.check_name_date(mrd_files);
catch
    disp('Error in Checking Participant IDs and Acquisition Dates')
end

%% Check all the protocols:
%Ventilation
try
    vent_prot = QC.check_vent_prot(mrd_files.vent{1});
catch
    vent_prot = {'NA','NA'};
    disp('Error in Checking Ventilation Protocol')
end
%Diffusion
try
    diff_prot = QC.check_diff_prot(mrd_files.diff{1});
catch
    diff_prot = {'NA','NA','NA'};
    disp('Error in Checking Diffusion Protocol')
end
%Gas Exchange
try
    gx_prot = QC.check_gx_prot(mrd_files.dixon{1});
catch
    gx_prot = {'NA','NA','NA','NA','NA','NA','NA','NA','NA'};
    disp('Error in Checking Gas Exchange Protocol')
end
%Calibration
try
    cal_prot = QC.check_cal_prot(mrd_files.cal{1});
catch
    cal_prot = {'NA','NA','NA','NA','NA','NA','NA'};
    disp('Error in Checking Calibration Protocol')
end

%% Write protocol information to excel file
QC.write_prot(cal_prot,vent_prot,diff_prot,gx_prot,participant_folder);

%% Reconstruct Images
%Ventilation
try
    [I_Vent,K_Vent] = Reconstruct.gre_recon(mrd_files.vent{1});
catch
    disp('Error Reconstructing Ventilation Image');
end
%Diffusion
try
    [I_Diff,K_Diff,bval] = Reconstruct.gre_recon(mrd_files.diff{1});
catch
    disp('Error Reconstructing Diffusion Image');
end
%Gas Exchange
try
    [I_Gas_Sharp,I_Gas_Broad,I_Dissolved,K_Gas,K_Dissolved] = Reconstruct.xpdixon_recon(mrd_files.dixon{1},3.5);
catch
    disp('Error Reconstructing Gas Exchange Image');
end
%Gas Exchange Anatomic
try
    [anat,anat_k] = Reconstruct.gxanat_recon(mrd_files.ute{1});
catch
    disp('Error Reconstructing Gas Exchange Image');
end

%% Calculating SNR for Images
SNR_Fail = 0;
%Ventilation
try
    SNR_Vent = QC.basic_snr(I_Vent,'Ventilation');
catch
    disp('Error calculating SNR of Ventilation Image');
    SNR_Vent = -1;
end
%Diffusion
try
    SNR_Diff = zeros(1,length(bval));
    for i = 1:length(bval)
        SNR_Diff(i) = QC.basic_snr(squeeze(I_Diff(:,:,i,:)),['Diffusion-b' num2str(bval(i))]);
    end
catch
    disp('Error calculating SNR of Diffusion Image');
    SNR_Diff(1) = -1;
    SNR_Diff(2) = -1;
end
%Gas Exchange
try
    SNR_Gas_Sharp = QC.basic_snr(I_Gas_Sharp,'Gas Exchange - Sharp Gas');
    SNR_Gas_Broad = QC.basic_snr(I_Gas_Broad,'Gas Exchange - Broad Gas');
    SNR_Dissolved = QC.basic_snr(I_Dissolved,'Gas Exchange - Dissolved');
catch
    disp('Error calculating SNR of Gas Exchange Image');
    SNR_Gas_Sharp = -1;
    SNR_Gas_Broad = -1;
    SNR_Dissolved = -1;
end

%% Analyze Calibration
try
    [R2M,Cal_SNR] = Reconstruct.analyze_cal(mrd_files.cal{1});
catch
    disp('Error analyzing calibration');
    Cal_SNR = -1;
end
%% Generate Mask 
try
    mask = Seg.docker_segment(abs(anat));
catch
    disp('Failed to generate Mask');
end

%% Separate Membrane and RBC
try
    [mem,rbc] = Reconstruct.dixon_sep(I_Dissolved,R2M,I_Gas_Broad,logical(mask));
catch
    disp('Dixon Separation of Membrane and RBC failed');
end
%% RBC and Membrane SNR
try
    SNR_Mem = QC.basic_snr(mem,'Membrane');
    SNR_RBC = QC.basic_snr(rbc,'RBC');
catch
    disp('Error calculating SNR of Membrane and RBC Images');
    SNR_Mem = -1;
    SNR_RBC = -1;
end
%% Write out SNR to excel File
SNR = {Cal_SNR,SNR_Vent,SNR_Diff(1),SNR_Diff(2),SNR_Gas_Sharp,SNR_Gas_Broad,SNR_Dissolved,SNR_Mem,SNR_RBC};
QC.write_snr(SNR,participant_folder);

%% Write out all figures to a QC folder
QA_fold = fullfile(participant_folder,'QA_Output');
if ~isfolder(QA_fold)
    mkdir(QA_fold);
end
QC.save_figures(QA_fold)

%% Now that we're done with QC, deidentify all data
deid_all(participant_folder);





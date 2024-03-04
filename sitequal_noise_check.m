function sitequal_noise_check(participant_folder)

%% Option to have User select folder
if nargin < 1
    participant_folder = uigetdir();
end

%% Clean up all windows before we get started
close all;

%% Find Files
mrd_files = ReadData.get_mrd(participant_folder);

%% Check all the protocols:
%Ventilation
try
    QC.check_vent_prot(mrd_files.vent{1});
catch
    disp('Error in Checking Ventilation Protocol')
end
%Diffusion
try
    QC.check_diff_prot(mrd_files.diff{1});
catch
    disp('Error in Checking Diffusion Protocol')
end
%Gas Exchange
try
    QC.check_gx_prot(mrd_files.dixon{1});
catch
    disp('Error in Checking Gas Exchange Protocol')
end
%Calibration
try
    QC.check_cal_prot(mrd_files.cal{1});
catch
    disp('Error in Checking Calibration Protocol')
end

%% Reconstruct Images
%Ventilation
try
    [I_Vent,K_Vent] = Reconstruct.gre_recon(mrd_files.vent{1});
catch
    disp('Error Reconstructing Ventilation Image');
end
%Diffusion
try
    [I_Diff,K_Diff] = Reconstruct.gre_recon(mrd_files.diff{1});
catch
    disp('Error Reconstructing Diffusion Image');
end
%Gas Exchange
try
    [I_Gas_Sharp,I_Gas_Broad,I_Dissolved,K_Gas,K_Dissolved] = Reconstruct.gx_recon(mrd_files.dixon{1});
catch
    disp('Error Reconstructing Gas Exchange Image');
end

%% Noise Checks - I don't really want to do this with every scan.
%Ventilation
try
    QC.check_noise(I_Vent,K_Vent,'Ventilation-from Raw');
catch
    disp('Error Checking Noise of Ventilation Image');
end
%Diffusion
try
    QC.check_noise(I_Diff,K_Diff,'Diffusion-from Raw');
catch
    disp('Error Checking Noise of Diffusion Image');
end
%Gas Exchange
try
    QC.check_noise(I_Gas_Broad(:,:,:,1),K_Gas(:,:,1),'Gas Exchange - Gas');
    QC.check_noise(I_Dissolved(:,:,:,1),K_Dissolved(:,:,1),'Gas Exchange - Dissolved');
catch
    disp('Error Checking Noise of Gas Exchange Image');
end

%% Alternatively, Load DICOM Images
try
    dicom_vent = ImTools.DICOM_Load('Select Ventilation DICOMs');
    QC.check_noise(dicom_vent,NaN,'Ventilation-from DICOM');
catch
    disp('Error checking noise of DICOM Ventilation image');
end
try
    dicom_diff = ImTools.DICOM_Load('Select Diffusion DICOMs');
    QC.check_noise(dicom_diff,NaN,'Diffusion-from DICOM');
catch
    disp('Error checking noise of DICOM Diffusion image');
end

%% Save Figures
QC.save_figures(participant_folder);
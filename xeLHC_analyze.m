function xeLHC_analyze(participant_folder)
%% get folder if none present
if nargin < 1
    participant_folder = uigetdir();
end
%% Check that Raw data is in good shape
R2M = rawdata_check(participant_folder);

%% Write data out to bids format:
bids_path = xebids(participant_folder);

%% Perform Ventilation Analysis
VDP = Seg.vdp_analysis(bids_path);

%% Perform Diffusion Analysis
ADC = diff_analysis(participant_folder);

%% Perform Calibration Analysis
cal_analysis(participant_folder);

msgbox(['ADC = ' num2str(ADC,3);'VDP = ' num2str(VDP,3);'RBC/Membrane = ' num2str(R2M,2)]);

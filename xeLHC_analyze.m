function xeLHC_analyze(participant_folder)
%% get folder if none present
if nargin < 1
    participant_folder = uigetdir();
end

%% Write data out to bids format:
bids_path = xebids(participant_folder);

%% Check that Raw data is in good shape
R2M = rawdata_check(participant_folder);

%% Perform Ventilation Analysis
try
    VDP = Seg.vdp_analysis(bids_path);
catch
    VDP = NaN;
end

%% Perform Diffusion Analysis
try
    ADC = diff_analysis_bids(bids_path);
catch
    ADC = diff_analysis(participant_folder);
end
%% Perform Calibration Analysis
Osc_Amp = cal_analysis(participant_folder);

%% Perform Gas Exchange Analysis
Seg.gx_analyze(participant_folder,false);
%%
msgbox([{['ADC = ' num2str(ADC,3)]};{['VDP = ' num2str(VDP,3)]};{['RBC/Membrane = ' num2str(R2M,3)]}]);

%%
QC.write_basic_analysis(VDP,ADC,R2M,Osc_Amp,participant_folder);

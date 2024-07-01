function ChangeVDP(participant_folder,bids_path)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%% Perform Ventilation Analysis

VDP = Seg.vdp_analysis(bids_path);

[Data_Path,Participant,~] = fileparts(participant_folder);
sub_ind = strfind(Participant,'CAQA');
Participant = Participant(sub_ind:end);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','Basic_Analysis.xlsx');
matfile = fullfile(Data_Path,'QC','Basic_Analysis.mat');

mymatch = [];

try 
    load(matfile,'AllAnalysis');
    mymatch = find(strcmpi(AllAnalysis.Participant,Participant));
catch
    disp("Doesn't exist")
end

if isempty(mymatch)
    disp("Participant Doesn't exist");
else
    ADC = AllAnalysis.ADC(mymatch);
    R2M = AllAnalysis.R2M(mymatch);
    Osc_Amp = AllAnalysis.Osc_Amp(mymatch);
end

QC.write_basic_analysis(VDP,ADC,R2M,Osc_Amp,participant_folder);

close all;
clear;
end
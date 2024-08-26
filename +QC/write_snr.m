function write_snr(SNR,participant_folder)

[Data_Path,Participant,~] = fileparts(participant_folder);
sub_ind = strfind(Participant,'CA');
Participant = Participant(sub_ind:end);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','SNR.xlsx');
matfile = fullfile(Data_Path,'QC','SNR.mat');

mymatch = [];

try 
    load(matfile,'AllSNR');
    mymatch = find(strcmpi(AllSNR.Participant,Participant));
catch
    headers = {'Participant',...
        'Calibration SNR_1','Calibration SNR_2','Calibration SNR_3','Ventilation SNR','Diffusion b = 0 SNR','Diffusion b = 12 SNR','Gas Exchange Gas Sharp Kernel SNR','Gas Exchange Gas Broad Kernel SNR','Gas Exchange Dissolved SNR','Membrane SNR','RBC SNR'};
    AllSNR = cell2table(cell(0,size(headers,2)));
    AllSNR.Properties.VariableNames = headers;
end
NewData = [Participant,SNR];

if isempty(mymatch)
    AllSNR = [AllSNR;NewData];
else
    AllSNR(mymatch,:) = NewData;
end

AllSNR = sortrows(AllSNR);

save(matfile,'AllSNR')
writetable(AllSNR,excel_file,'Sheet',1)
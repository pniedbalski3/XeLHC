function write_snr(SNR,participant_folder)

[Data_Path,Participant,~] = fileparts(participant_folder);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','SNR.xlsx');
matfile = fullfile(Data_Path,'QC','SNR.mat');

mymatch = [];

try 
    load(matfile,'AllSNR');
    mymatch = strcmpi(AllSNR.Participant,Participant);
catch
    headers = {'Participant',...
        'Cal TR (15)','Cal TE (0.45)','Gas FA (20)','Dis FA (20)','Dwell (39)','Points (256)','Number Spectra (520)',...
        'Vent Res (4 4 15)','Vent Slices (>=12)',...
        'Diff Res (6 6 25)','Diff Slices (<9)','Diff bval (0 12)',...
        'Gx Res (6.25 6.25 6.25)','TR (TBD)','TE (0.45-0.5)','Gas FA (0.5)','Dis FA (TBD)','Dwell (20)','Points (64)','Projections (TBD)'};
    AllSNR = cell2table(cell(0,size(headers,2)));
    AllSNR.Properties.VariableNames = headers;
end
NewData = [Participant,SNR];

if isempty(mymatch)
    AllSNR = [AllSNR;NewData];
else
    AllSNR(mymatch,:) = NewData;
end
save(matfile,'AllSNR')
writetable(AllSNR,excel_file,'Sheet',1)
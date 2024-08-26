function write_basic_analysis(VDP,ADC,R2M,Osc_Amp,participant_folder)

[Data_Path,Participant,~] = fileparts(participant_folder);
sub_ind = strfind(Participant,'CA');
Participant = Participant(sub_ind:end);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','Basic_Analysis2.xlsx');
matfile = fullfile(Data_Path,'QC','Basic_Analysis2.mat');

mymatch = [];

try 
    load(matfile,'AllAnalysis');
    mymatch = find(strcmpi(AllAnalysis.Participant,Participant));
catch
    headers = {'Participant',...
        'VDP','ADC','R2M','Osc_Amp',...
        'Analyzed By','Date Analyzed','Analysis Version'};
    AllAnalysis = cell2table(cell(0,size(headers,2)));
    AllAnalysis.Properties.VariableNames = headers;
end

[Parent_path,~,~] = fileparts(mfilename('fullpath'));
[Parent_path,~,~] = fileparts(Parent_path);
fileID = fopen(fullfile(Parent_path,'Pipeline_Version.txt'),'r');
Version = fscanf(fileID,'%s');

NewData = [Participant,VDP,ADC,R2M,Osc_Amp,getenv('username'),{string(datetime("today"))},Version];

if isempty(mymatch)
    AllAnalysis = [AllAnalysis;NewData];
else
    AllAnalysis(mymatch,:) = NewData;
end

AllAnalysis = sortrows(AllAnalysis);

save(matfile,'AllAnalysis')
writetable(AllAnalysis,excel_file,'Sheet',1)
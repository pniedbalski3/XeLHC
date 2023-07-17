function write_prot(cal,vent,diff,gx,participant_folder)

[Data_Path,Participant,~] = fileparts(participant_folder);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','Protocol_QC.xlsx');
matfile = fullfile(Data_Path,'QC','Protocol_QC.mat');

mymatch = [];

try 
    load(matfile,'Prot_QC');
    mymatch = strcmpi(Prot_QC.Participant,Participant);
catch
    headers = {'Participant',...
        'Cal TR (15)','Cal TE (0.45)','Gas FA (20)','Dis FA (20)','Dwell (39)','Points (256)','Number Spectra (520)',...
        'Vent Res (4 4 15)','Vent Slices (>=12)',...
        'Diff Res (6 6 25)','Diff Slices (<9)','Diff bval (0 12)',...
        'Gx Res (6.25 6.25 6.25)','TR (TBD)','TE (0.45-0.5)','Gas FA (0.5)','Dis FA (TBD)','Dwell (20)','Points (64)','Projections (TBD)'};
    Prot_QC = cell2table(cell(0,size(headers,2)));
    Prot_QC.Properties.VariableNames = headers;
end
NewData = [Participant,cal,vent,diff,gx];

if mymatch ==0
    Prot_QC = [Prot_QC;NewData];
else
    Prot_QC(mymatch,:) = NewData;
end
save(matfile,'Prot_QC')
writetable(Prot_QC,excel_file,'Sheet',1)
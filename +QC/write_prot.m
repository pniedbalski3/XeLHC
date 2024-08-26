function write_prot(cal,vent,diff,gx,participant_folder)

[Data_Path,Participant,~] = fileparts(participant_folder);
sub_ind = strfind(Participant,'CAQA');
if isempty(sub_ind)
    sub_ind = strfind(Participant,'CACB');
end
if isempty(sub_ind)
    sub_ind = strfind(Participant,'CABA');
end
Participant = Participant(sub_ind:end);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','Protocol_QC.xlsx');
matfile = fullfile(Data_Path,'QC','Protocol_QC.mat');

mymatch = [];
cal{1} = cal{1}(1);
try 
    load(matfile,'Prot_QC');
    mymatch = strcmpi(Prot_QC.Participant,Participant);
catch
    headers = {'Participant',...
        'Cal TR (15)','Cal TE (0.45)','Cal Gas FA (20)','Cal Dis FA (20)','Dwell (39)','Points (256)','Number Spectra (520)',...
        'Vent Res (4 4 15)','Vent Slices (>=12)',...
        'Diff Res (6 6 30)','Diff Slices (<9)','Diff bval (0 12)',...
        'Gx Res (6.25 6.25 6.25)','TR (15)','TE (0.45-0.5)','Gas FA (0.5)','Dis FA (20)','Dwell (20)','Points (64)','Projections (1000)','Chemical Shift (208)'};
    Prot_QC = cell2table(cell(0,size(headers,2)));
    Prot_QC.Properties.VariableNames = headers;
end
NewData = [Participant,cal,vent,diff,gx];

if any(mymatch ==0) || isempty(mymatch)
    Prot_QC = [Prot_QC;NewData];
else
    Prot_QC(mymatch,:) = NewData;
end
save(matfile,'Prot_QC')
writetable(Prot_QC,excel_file,'Sheet',1)
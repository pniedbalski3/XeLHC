function check_name_date(mrd_files)

%% Prep
mrd_files1 = struct2cell(mrd_files);

names{length(mrd_files1)} = [];
dates{length(mrd_files1)} = [];
%% Read Participant IDs and Date of acquisition
for i = 1:length(mrd_files1)
    try    
        tmp_file = mrd_files1{i}{1};
        dset = ismrmrd.Dataset(tmp_file,'dataset');
        hdr = ismrmrd.xml.deserialize(dset.readxml);
        dates{i} = hdr.studyInformation.studyDate;
        names{i} = hdr.subjectInformation.patientID;
    catch
        dates{i} = 'No MRD file Found';
        names{i} = 'No MRD file Found';
    end
end
%% Display 
myfield = fieldnames(mrd_files);
%Write out to screen - Blanks empirically determined to justify within the
%message box.
outnamestrs = {[myfield{1} ': ' blanks(20 - length(myfield{1})) names{1}],...
     [myfield{2} ': ' blanks(19 - length(myfield{2})) names{2}],...
     [myfield{3} ': ' blanks(16 - length(myfield{3})) names{3}],...
     [myfield{4} ': ' blanks(21 - length(myfield{4})) names{4}],...
     [myfield{5} ': ' blanks(18 - length(myfield{5})) names{5}],...
     [myfield{6} ': ' blanks(20 - length(myfield{6})) names{6}]};

outdatestrs = {[myfield{1} ': ' blanks(20 - length(myfield{1})) dates{1}],...
     [myfield{2} ': ' blanks(19 - length(myfield{2})) dates{2}],...
     [myfield{3} ': ' blanks(16 - length(myfield{3})) dates{3}],...
     [myfield{4} ': ' blanks(21 - length(myfield{4})) dates{4}],...
     [myfield{5} ': ' blanks(18 - length(myfield{5})) dates{5}],...
     [myfield{6} ': ' blanks(20 - length(myfield{6})) dates{6}]};

msgbox(outnamestrs,'Check Participant IDs');
msgbox(outdatestrs,'Check Date of Scan Acquisition');

%% Automated Name Check
nagree = 1;
dagree = 1;
for i = 1:length(names)
    for j = i:length(names)
        nagree = nagree * strcmp(names{i},names{j});
        dagree = dagree * strcmp(dates{i},dates{j});
    end
end

if ~nagree
    msgbox("Participant IDs do not agree across all sequences",'Participant IDs Do Not Agree','error');
end
if ~dagree 
    msgbox("Acquisition Dates do not agree across all sequences",'Acquisition Dates Do Not Agree','error');
end


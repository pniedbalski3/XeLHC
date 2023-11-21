function deid_all(participant_folder)

%% create folder to hold deidentified data
newdir = fullfile(participant_folder,'Deidentified_Imaging_Data');
if ~isfolder(newdir)
    mkdir(newdir);
end

%% Find all the images
mrd_files = ReadData.get_mrd(participant_folder);

%% deidentify all data
mrd_files = struct2cell(mrd_files);
for i = 1:length(mrd_files)
    try
        tmp_name = mrd_files{i}{1}; %this updates as nested cells... weird
        deid_mrd(tmp_name);
        %% move deidentified data all to the same place
        [mypath,myfile,myext] = fileparts(tmp_name);
        deidfile = fullfile(mypath,['DeID_' myfile myext]);
        movefile(deidfile,newdir);
    catch
    end
end

function mrd_files = get_mrd(participant_folder)

if ispc
    All_files = dir(fullfile(participant_folder,'**\*'));
else
    All_files = dir(fullfile(participant_folder,'**/*'));
end

All_files = struct2cell(All_files);

filenames = All_files(1,:);

% Need to find cali.h5, vent.h5, ventanat.h5 diff.h5, dixon.h5, ute.h5 

cal_indx = find(contains(filenames,'calibration.h5'));
vent_indx = find(contains(filenames,'vent.h5'));
ventanat_indx = find(contains(filenames,'ventanat.h5'));
diff_indx = find(contains(filenames,'diff.h5'));
dixon_indx = find(contains(filenames,'dixon.h5'));
ute_indx = find(contains(filenames,'proton.h5'));

mrd_files.cal = fullfile(All_files(2,cal_indx),All_files(1,cal_indx));
mrd_files.vent = fullfile(All_files(2,vent_indx),All_files(1,vent_indx));
mrd_files.ventanat = fullfile(All_files(2,ventanat_indx),All_files(1,ventanat_indx));
mrd_files.diff = fullfile(All_files(2,diff_indx),All_files(1,diff_indx));
mrd_files.dixon = fullfile(All_files(2,dixon_indx),All_files(1,dixon_indx));
mrd_files.ute = fullfile(All_files(2,ute_indx),All_files(1,ute_indx));
function mrd_files = get_mrd(participant_folder)

if ispc
    All_files = dir(fullfile(participant_folder,'**\*'));
else
    All_files = dir(fullfile(participant_folder,'**/*'));
end

All_files = struct2cell(All_files);

filenames = All_files(1,:);

% Need to find cali.h5, vent.h5, ventanat.h5 diff.h5, dixon.h5, ute.h5 

cal_indx = find(contains(filenames,'calibration.'));
if isempty(cal_indx)
    cal_indx = find(contains(filenames,'Calibration.'));
end
vent_indx = find(contains(filenames,'vent.'));
if isempty(vent_indx)
    vent_indx = find(contains(filenames,'gre.'));
end
ventanat_indx = find(contains(filenames,'ventanat.'));
diff_indx = find(contains(filenames,'diff.'));
dixon_indx = find(contains(filenames,'dixon.'));
if isempty(dixon_indx)
    dixon_indx = find(contains(filenames,'dissolved.'));
end
if isempty(dixon_indx)
    dixon_indx = find(contains(filenames,'Dissolved.'));
end
ute_indx = find(contains(filenames,'proton.'));

mrd_files.cal = fullfile(All_files(2,cal_indx),All_files(1,cal_indx));
mrd_files.vent = fullfile(All_files(2,vent_indx),All_files(1,vent_indx));
mrd_files.ventanat = fullfile(All_files(2,ventanat_indx),All_files(1,ventanat_indx));
mrd_files.diff = fullfile(All_files(2,diff_indx),All_files(1,diff_indx));
mrd_files.dixon = fullfile(All_files(2,dixon_indx),All_files(1,dixon_indx));
mrd_files.ute = fullfile(All_files(2,ute_indx),All_files(1,ute_indx));

cal_indx = find(contains(mrd_files.cal,'DeID'));
vent_indx = find(contains(mrd_files.vent,'DeID'));
ventanat_indx = find(contains(mrd_files.ventanat,'DeID'));
diff_indx = find(contains(mrd_files.diff,'DeID'));
dixon_indx = find(contains(mrd_files.dixon,'DeID'));
ute_indx = find(contains(mrd_files.ute,'DeID'));

mrd_files.cal(cal_indx) = []; 
mrd_files.vent(vent_indx) = [];
mrd_files.ventanat(ventanat_indx) = []; 
mrd_files.diff(diff_indx) = [];
mrd_files.dixon(dixon_indx) = [];
mrd_files.ute(ute_indx) = [];
function [myTable,MissingIms] = check_completeness(Parent_folder,N_enrolled)
MissingIms.Calibration = [];
MissingIms.Ventilation = [];
MissingIms.DWI = [];
MissingIms.GX = [];

%% Get list of participants to look through
myfolds = dir(Parent_folder);

del_line = zeros(length(myfolds),1);
for i = 1:length(myfolds)
    if myfolds(i).isdir == 0
        del_line(i) = 1;
    end
    myname = myfolds(i).name;
    if length(myname) < 3
        del_line(i) = 1;
        continue
    end
    last_3 = myname((end-2:end));
    TF = isstrprop(last_3,'digit');
    if sum(TF) ~= 3
        del_line(i) = 1;
    end
end

myfolds(logical(del_line)) = [];
%% Look in each participant for calibration and gas exchange raw data, ventilation and diffusion nifti's
% We should be able to estimate the BIDs folder name
VentYN = zeros(length(myfolds),1);
DiffYN = zeros(length(myfolds),1);
CalYN = zeros(length(myfolds),1);
GXYN = zeros(length(myfolds),1);
Vent_Count = 1;
Diff_Count = 1;
Cal_Count = 1;
GX_Count = 1;
for i = 1:length(myfolds)
    tmp_dir = fullfile(myfolds(i).folder,myfolds(i).name,['sub-' myfolds(i).name((end-6):end)]);
    VentYN(i) = isfile(fullfile(tmp_dir,'xevent',['sub-' myfolds(i).name((end-6):end) '_vent.nii.gz']));
    Diff1 = isfile(fullfile(tmp_dir,'xedwi',['sub-' myfolds(i).name((end-6):end) '_xedwi_1.nii.gz']));
    Diff2 = isfile(fullfile(tmp_dir,'xedwi',['sub-' myfolds(i).name((end-6):end) '_xedwi.nii.gz']));
    DiffYN(i) = Diff1 | Diff2;
    Cal1 = isfile(fullfile(tmp_dir,'xegx',[myfolds(i).name((end-6):end) '_calibration.h5']));
    Cal2 = isfile(fullfile(tmp_dir,'xegx',['DeID_' myfolds(i).name((end-6):end) '_calibration.h5']));
    CalYN(i) = Cal1 | Cal2;
    GX1 = isfile(fullfile(tmp_dir,'xegx',[myfolds(i).name((end-6):end) '_dixon.h5']));
    GX2 = isfile(fullfile(tmp_dir,'xegx',['DeID_' myfolds(i).name((end-6):end) '_dixon.h5'])); 
    GXYN(i) = GX1 | GX2;
    
    if VentYN(i) == 0
        MissingIms.Ventilation{Vent_Count} = myfolds(i).name((end-6):end);
        Vent_Count = Vent_Count + 1;
    end
    if DiffYN(i) == 0
        MissingIms.DWI{Diff_Count} = myfolds(i).name((end-6):end);
        Diff_Count = Diff_Count + 1;
    end
    if CalYN(i) == 0
        MissingIms.Calibration{Cal_Count} = myfolds(i).name((end-6):end);
        Cal_Count = Cal_Count + 1;
    end
    if GXYN(i) == 0
        MissingIms.GX{GX_Count} = myfolds(i).name((end-6):end);
        GX_Count = GX_Count + 1;
    end
end

if nargin < 2
    Enrolled = length(myfolds);
else
    Enrolled = N_enrolled;
end
Calibration = {[num2str(sum(double(CalYN))) ' (' num2str(sum(double(CalYN))/Enrolled *100) ')' ]};
Ventilation = {[num2str(sum(double(VentYN))) ' (' num2str(sum(double(VentYN))/Enrolled *100) ')' ]};
Diffusion = {[num2str(sum(double(DiffYN))) ' (' num2str(sum(double(DiffYN))/Enrolled *100) ')' ]};
Gas_Exchange = {[num2str(sum(double(GXYN))) ' (' num2str(sum(double(GXYN))/Enrolled *100) ')' ]};

myTable = table(Enrolled,Calibration,Ventilation,Diffusion,Gas_Exchange);
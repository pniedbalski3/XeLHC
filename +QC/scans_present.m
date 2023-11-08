function scans_present(mrd_files)

count = 1;

if isempty(mrd_files.cal)
    output(count,1) = "Calibration";
    count = count + 1;
end

if isempty(mrd_files.vent)
    output(count,1) = "Ventilation";
    count = count + 1;
end

if isempty(mrd_files.ventanat)
    output(count,1) = "Vent Anatomic";
    count = count + 1;
end

if isempty(mrd_files.diff)
    output(count,1) = "Diffusion Weighted";
    count = count + 1;
end

if isempty(mrd_files.dixon)
    output(count,1) = "Gas Exchange";
    count = count + 1;
end

if isempty(mrd_files.ute)
    output(count,1) = "Gas Exchange Anatomic";
    count = count + 1;
end

if exist('output','var')
    msgbox([output;"Image(s) not found"],"Sequence not found");
end
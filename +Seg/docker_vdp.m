function docker_vdp(Image_Path,Mask_Path)

parent_path = which('Seg.docker_vdp');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

if nargin < 2
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Ventilation Image');
    Image_Path = fullfile(path,filename);
    
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Image Mask');
    Mask_Path = fullfile(path,filename);
end

idcs = strfind(Image_Path,filesep);%determine location of file separators
ImPath = Image_Path(1:idcs(end)-1);%remove file
ImName = Image_Path((idcs(end)+1):end);
idcs = strfind(Mask_Path,filesep);%determine location of file separators
MskPath = Mask_Path(1:idcs(end)-1);%remove file
MskName = Mask_Path((idcs(end)+1):end);

Code_Path = parent_path;

if ispc
    Orig_ImPath = ImPath;
    local_path = 'C:/Users/pniedbalski/OneDrive - University of Kansas Medical Center/Documents/local_tmp';
    Code_Path = ['"' Code_Path '"'];
    copyfile(Image_Path,local_path);
    copyfile(Mask_Path,local_path);
    ImPath = '"C:/Users/pniedbalski/OneDrive - University of Kansas Medical Center/Documents/local_tmp"';
end

mapping = ['-v ' Code_Path ':/mnt/mycode -v ' ImPath ':/mnt/mydata'];

dockercommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/python_vdp.py /mnt/mydata/' ImName ' /mnt/mydata/' MskName];

status = system(dockercommand);

%If on a PC, sending images through the docker from a local drive, so need
%to move back to P drive.
if ispc
    Atropos_Name = strrep(ImName,'.nii.gz','_atropos.nii.gz');
    cmeans_Name = strrep(ImName,'.nii.gz','_cmeans.nii.gz');
    elbicho_Name = strrep(ImName,'.nii.gz','_elbicho.nii.gz');
    try
        copyfile(fullfile(local_path,Atropos_Name),Orig_ImPath);
    catch
    end
    try
        copyfile(fullfile(local_path,cmeans_Name),Orig_ImPath);
    catch
    end
    try
        copyfile(fullfile(local_path,elbicho_Name),Orig_ImPath);
    catch
    end
end
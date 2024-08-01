function mask = docker_segment(Image)
%%
parent_path = which('Seg.docker_segment');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

% Write Image to Nifti - need to properly orient image
Image = ReadData.mat2canon(Image);
niftiwrite(Image,fullfile(parent_path,'Tmp','tmp_seg_image'),'Compressed',true);

ImPath = fullfile(parent_path,'Tmp');

% If spaces in the path fix here:
if contains(ImPath,' ')
    ImPath = insertBefore(ImPath,1,'"');
    ImPath = insertAfter(ImPath,length(ImPath),'"');
end
if contains(parent_path,' ')
    CodePath = insertBefore(parent_path,1,'"');
    CodePath = insertAfter(CodePath,length(CodePath),'"');
else
    CodePath = parent_path;
end

ImName = 'tmp_seg_image.nii.gz';

mapping = ['-v ' CodePath ':/mnt/mycode -v ' ImPath ':/mnt/mydata'];

dockercommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/+Seg/segment_lungs.py /mnt/mydata/' ImName ' &'];

status = system(dockercommand);pause(30)

% Read in mask - rotate image back to matlab orientation
mask = niftiread(fullfile(parent_path,'Tmp','tmp_seg_image_mask.nii.gz'));
mask = ReadData.canon2mat(mask);

%delete tmp files
delete(fullfile(parent_path,'Tmp','tmp_seg_image.nii.gz'))
delete(fullfile(parent_path,'Tmp','tmp_seg_image_mask.nii.gz'))
delete(fullfile(parent_path,'Tmp','tmp_seg_image_probability_mask.nii.gz'))


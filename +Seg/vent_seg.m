function vent_seg(mypath)

[~,part,~] = fileparts(mypath);
part_start = strfind(part,'CA');
bidsfold = fullfile(mypath,['sub-' part(part_start:end)]);


%% Load in Images
vent_path = struct2cell(dir(fullfile(bidsfold,'xevent')));
myindv = find(contains(vent_path(1,:),'vent.nii.gz'));
if length(myindv) > 1
    myindv = myindv(1);
end

vent_full_path = fullfile(vent_path{2,myindv},vent_path{1,myindv});
vent = squeeze(double(niftiread(fullfile(vent_path{2,myindv},vent_path{1,myindv}))));

anat_path = struct2cell(dir(fullfile(bidsfold,'anat')));
myinda = find(contains(anat_path(1,:),'T1w.nii.gz'));

anat_full_path = fullfile(anat_path{2,myinda},anat_path{1,myinda});
anat = double(niftiread(fullfile(anat_path{2,myinda},anat_path{1,myinda})));

if size(anat,1) ~= size(vent,1) | size(anat,2) ~= size(vent,2) | size(anat,3) ~= size(vent,3)
    anat = permute(anat,[1 3 2]);
    anat = flip(anat,3);
    anat = imresize3(anat,size(vent));
end

maskpath = fullfile(anat_path{2,myinda},strrep(anat_path{1,myinda},'T1w.nii.gz','ventmask.nii.gz'));
itk_path = ImTools.get_itk_path();
ITKSNAP_Path = ['"C:\Program Files\' itk_path '\bin\ITK-SNAP.exe"'];

mycommand = [ITKSNAP_Path ' -g "' vent_full_path '" -o "' anat_full_path '" -s "' maskpath '"'];
system(mycommand);
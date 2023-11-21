function VDP = vdp_analysis(bidsfold)
%% Get folder if none is provided
if nargin < 1
    bidsfold = uigetdir([],'Select the bids format folder for the participant');
end
%% Load in Images
vent_path = struct2cell(dir(fullfile(bidsfold,'xevent')));
myindv = find(contains(vent_path(1,:),'vent.nii.gz'));

vent_full_path = fullfile(vent_path{2,myindv},vent_path{1,myindv});
vent = double(niftiread(fullfile(vent_path{2,myindv},vent_path{1,myindv})));

anat_path = struct2cell(dir(fullfile(bidsfold,'anat')));
myinda = find(contains(anat_path(1,:),'T1w.nii.gz'));

anat_full_path = fullfile(anat_path{2,myinda},anat_path{1,myinda});
anat = double(niftiread(fullfile(anat_path{2,myinda},anat_path{1,myinda})));

%% Mask image (if needed)
maskpath = fullfile(anat_path{2,myinda},strrep(anat_path{1,myinda},'T1w.nii.gz','ventmask.nii.gz'));
if ~isfile(maskpath)
    mask = Seg.docker_segment(abs(anat));
    %Need to write Mask to bids:
    writemask = ReadData.mat2canon(mask);
    niftiwrite(mask,fullfile(anat_path{2,myinda},strrep(anat_path{1,myinda},'T1w.nii.gz','ventmask')),'Compressed',true);
end

%% Now, I should be able to load these files into ITK-snap for checking:
ITKSNAP_Path = '"C:\Program Files\ITK-SNAP 3.8\bin\ITK-SNAP.exe"';

mycommand = [ITKSNAP_Path ' -g "' vent_full_path '" -o "' anat_full_path '" -s "' maskpath '"'];
system(mycommand);

%% This should pause until the user closes ITK-Snap.
%Now, I should have a decent mask, and I can calculate VDP. For now, use
%60% threshold... In the future, expand.
mask = niftiread(maskpath);
imseg = Seg.vdp60(vent,mask);

VDP = (nnz(imseg ==1) + nnz(imseg==2))./nnz(mask) * 100;

%% Display a summary image:
vent2 = fliplr(rot90(vent));
imseg2 = fliplr(rot90(imseg));

tilevent = imtile(vent2);
tileseg = imtile(imseg2);

CMap = [1 0 0;1 0.7143 0; 0 1 0;0 0 1];
figure('Name','Ventilition Defect Analysis')
Tools.imoverlay(tilevent,tileseg,[1 4],[0,prctile(vent(mask==1),99)],CMap,0.5,gca);
colormap(CMap);








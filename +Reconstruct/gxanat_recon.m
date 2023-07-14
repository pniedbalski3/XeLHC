function [anat,anat_k] = gxanat_recon(filename)

dset = ismrmrd.Dataset(filename,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);

ImSize = [hdr.encoding.reconSpace.matrixSize.x hdr.encoding.reconSpace.matrixSize.y hdr.encoding.reconSpace.matrixSize.z];

%% Read in all data
D = dset.readAcquisition();

%% Ignore noise scans
% TODO add a pre-whitening example
% Find the first non-noise scan
% This is how to check if a flag is set in the acquisition header
isNoise = D.head.flagIsSet('ACQ_IS_NOISE_MEASUREMENT');
firstScan = find(isNoise==0,1,'first');
if firstScan > 1
    noise = D.select(1:firstScan-1);
else
    noise = [];
end
meas  = D.select(firstScan:D.getNumber);
clear D;

%% All data points should contribute to image

%Need to extract data from cell and put into an array
FID_Array = zeros(length(meas.data{1}),length(meas.data),size(meas.data{1},2));
Traj_Array = zeros(3,length(meas.data{1}),length(meas.data));

for i = 1:length(meas.data)
    FID_Array(:,i,:) = meas.data{i};
    Traj_Array(:,:,i) = meas.traj{i};
end

anat_k = FID_Array;

%% Reconstruct Images
%Reshape to column vectors
Trajr = [reshape(Traj_Array(1,:,:),1,[])' reshape(Traj_Array(2,:,:),1,[])' reshape(Traj_Array(3,:,:),1,[])'];
Img = zeros([ImSize size(FID_Array,3)]);
for i = 1:size(FID_Array,3)
    tmp = FID_Array(:,:,i);
    tmpr = reshape(tmp,1,[])';
    Img(:,:,:,i) = Reconstruct.h1_recon(ImSize,tmpr,Trajr);
end
    
anat = sqrt(sum(Img.^2,4));




function [gas_hires,gas_lores,dis,gas_k,dis_k] = gx_recon(filename)

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

%% Get Gas Data
Gas_ind = find(meas.head.idx.contrast == 1 & meas.head.measurement_uid == 0);

Gas_FID = meas.data(Gas_ind);
Gas_Traj = meas.traj(Gas_ind);

%Need to extract data from cell and put into an array
Gas_FID_Array = zeros(length(Gas_FID{1}),length(Gas_FID));
Gas_Traj_Array = zeros(3,length(Gas_FID{1}),length(Gas_FID));

for i = 1:length(Gas_FID)
    Gas_FID_Array(:,i) = Gas_FID{i};
    Gas_Traj_Array(:,:,i) = Gas_Traj{i};
end

%Kill the first 20 points to get to steady state (and avoid any first
%projection weirdness)
Gas_FID_Array(:,1:20) = [];
Gas_Traj_Array(:,:,1:20) = [];

gas_k = Gas_FID_Array;

%% Get Dissolved Data
Dis_ind = find(meas.head.idx.contrast == 2 & meas.head.measurement_uid == 0);

Dis_FID = meas.data(Dis_ind);
Dis_Traj = meas.traj(Dis_ind);

%Need to extract data from cell and put into an array
Dis_FID_Array = zeros(length(Dis_FID{1}),length(Dis_FID));
Dis_Traj_Array = zeros(3,length(Dis_FID{1}),length(Dis_FID));

for i = 1:length(Dis_FID)
    Dis_FID_Array(:,i) = Dis_FID{i};
    Dis_Traj_Array(:,:,i) = Dis_Traj{i};
end

%Kill the first 20 points to get to steady state (and avoid any first
%projection weirdness)
Dis_FID_Array(:,1:20) = [];
Dis_Traj_Array(:,:,1:20) = [];
dis_k = Dis_FID_Array;


%% Reconstruct Images
%Reshape to column vectors
Gas_FIDr = reshape(Gas_FID_Array,1,[])';
Gas_Trajr = [reshape(Gas_Traj_Array(1,:,:),1,[])' reshape(Gas_Traj_Array(2,:,:),1,[])' reshape(Gas_Traj_Array(3,:,:),1,[])'];

Dis_FIDr = reshape(Dis_FID_Array,1,[])';
Dis_Trajr = [reshape(Dis_Traj_Array(1,:,:),1,[])' reshape(Dis_Traj_Array(2,:,:),1,[])' reshape(Dis_Traj_Array(3,:,:),1,[])'];

gas_hires = Reconstruct.sharp_kern_recon(ImSize,Gas_FIDr,Gas_Trajr);
gas_lores = Reconstruct.broad_kern_recon(ImSize,Gas_FIDr,Gas_Trajr);

dis = Reconstruct.broad_kern_recon(ImSize,Dis_FIDr,Dis_Trajr);


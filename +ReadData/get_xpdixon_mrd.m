function [fid,traj] = get_xpdixon_mrd(meas,indx)

FID = meas.data(indx);
Traj = meas.traj(indx);

%Need to extract data from cell and put into an array
fid = zeros(length(FID{1}),length(FID));
traj = zeros(3,length(FID{1}),length(FID));

for i = 1:length(FID)
    fid(:,i) = FID{i};
    traj(:,:,i) = Traj{i};
end

%Kill the first 20 points to get to steady state (and avoid any first
%projection weirdness)
fid(:,1:20) = [];
traj(:,:,1:20) = [];
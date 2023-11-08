function newtraj = traj_delay_correction(traj,Delay)

%% Function to adjust trajectories for a delay
%Pass trajectory matrix and the Desired Trajectory delay in units of Dwell
%Times

Dwell = 1;

if numel(Delay) == 1
    Delay = [Delay Delay Delay];
elseif numel(Delay)~= 3
    error('Delay needs to be either a scalar or 3-vector')
end
%Get the number of points to look at
Npts = size(traj,2);
Nproj = size(traj,3);

%Actually, let's just try an interpolation - Need some extra 0's in the
%trajectory to make sure that I can interpolate:
% Almost certainly won't need more than 3 dwells - Really, probably won't
% even need 1 dwell, but let's use 10 just to make sure there's plenty.
traj_big = zeros(size(traj,1),size(traj,2)+10,size(traj,3));
traj_big(:,11:(size(traj,2)+10),:) = traj;

TimeArray = (-10*Dwell):Dwell:((Npts-1)*Dwell);
newtraj = zeros(size(traj));

%xfig = figure('Name','x Trajectory');
%yfig = figure('Name','y Trajectory');
%zfig = figure('Name','z Trajectory');

for i = 1:Nproj
    TimeArrayx = TimeArray-Delay(1);
    TimeArrayy = TimeArray-Delay(2);
    TimeArrayz = TimeArray-Delay(3);
    
    Newtrajx = interp1(TimeArray,traj_big(1,:,i),TimeArrayx,'linear','extrap');
    Newtrajy = interp1(TimeArray,traj_big(2,:,i),TimeArrayy,'linear','extrap');
    Newtrajz = interp1(TimeArray,traj_big(3,:,i),TimeArrayz,'linear','extrap');
    
%     figure(xfig)
%     plot(TimeArray,traj_big(1,:,i),'*b',TimeArrayx,Newtrajx,'*r')
%     legend('Original','New')
%     
%     figure(yfig)
%     plot(TimeArray,traj_big(2,:,i),'*b',TimeArrayy,Newtrajy,'*r')
%     legend('Original','New')
%     
%     figure(zfig)
%     plot(TimeArray,traj_big(3,:,i),'*b',TimeArrayz,Newtrajz,'*r')
%     legend('Original','New')
    
    Newtrajx(1:10) = [];
    Newtrajy(1:10) = [];
    Newtrajz(1:10) = [];
    
    newtraj(1,:,i) = Newtrajx;
    newtraj(2,:,i) = Newtrajy;
    newtraj(3,:,i) = Newtrajz;
end


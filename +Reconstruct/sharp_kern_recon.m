function Image_Out = sharp_kern_recon(ImageSize,data,traj)
%% A Function written to reconstruct Images when K-space data and trajectories are passed to it
% Uses Scott Robertson's reconstruction code - This just makes it more
% modular and easy to implement - This is for 3D data
% 
% ImageSize - Scalar: Output image matrix size
%
% data - KSpace Data in (N_ro x N_Proj)
%
% traj - point in kspace corresponding to the data vector - columns for
% x,y, and z. (3 x N_ro x N_Proj)

%Let's kill all points too large to be included
rad = sqrt(traj(:,1).^2+traj(:,2).^2+traj(:,3).^2);
toobig = find(rad>0.5);
data(toobig) = [];
traj(toobig,:) = [];

%  Settings
kernel.sharpness = 0.32;
kernel.extent = 9*kernel.sharpness;
overgrid_factor = 3;
output_image_size = ImageSize;
nDcfIter = 15;
deapodizeImage = true();
cropOvergriddedImage = true();
verbose = false();

%  Transform Data/Traj to Nx1 and Nx3
traj_redim = traj;%[reshape(traj(1,:,:),1,[])' reshape(traj(2,:,:),1,[])' reshape(traj(3,:,:),1,[])'];
data_redim = data;%reshape(data(:,:),1,[])';
    
%  Choose kernel, proximity object, and then create system model
kernelObj = Reconstruct.Recon.SysModel.Kernel.Gaussian(kernel.sharpness, kernel.extent, verbose);
proxObj = Reconstruct.Recon.SysModel.Proximity.L2Proximity(kernelObj, verbose);
clear kernelObj;
systemObj = Reconstruct.Recon.SysModel.MatrixSystemModel(traj_redim, overgrid_factor, ...
    output_image_size, proxObj, verbose);

% Choose density compensation function (DCF)
dcfObj = Reconstruct.Recon.DCF.Iterative(systemObj, nDcfIter, verbose);

% Choose Reconstruction Model
reconObj = Reconstruct.Recon.ReconModel.LSQGridded(systemObj, dcfObj, verbose);
clear modelObj;
clear dcfObj;
%reconObj.PixelShift = PixelShift;
reconObj.crop = cropOvergriddedImage;
reconObj.deapodize = deapodizeImage;

% Reconstruct image
Image_Out = reconObj.reconstruct(data_redim, traj_redim);







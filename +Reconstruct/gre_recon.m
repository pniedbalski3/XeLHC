function [recon_image,K_space,b] = gre_recon(filename)

dset = ismrmrd.Dataset(filename,'dataset');

hdr = ismrmrd.xml.deserialize(dset.readxml);

%% Read in various parameters from the header.
% Matrix size
enc_Nx = hdr.encoding.encodedSpace.matrixSize.x;
enc_Ny = hdr.encoding.encodedSpace.matrixSize.y;
enc_Nz = hdr.encoding.encodedSpace.matrixSize.z;
rec_Nx = hdr.encoding.reconSpace.matrixSize.x;
rec_Ny = hdr.encoding.reconSpace.matrixSize.y;
rec_Nz = hdr.encoding.reconSpace.matrixSize.z;

% Field of View
enc_FOVx = hdr.encoding.encodedSpace.fieldOfView_mm.x;
enc_FOVy = hdr.encoding.encodedSpace.fieldOfView_mm.y;
enc_FOVz = hdr.encoding.encodedSpace.fieldOfView_mm.z;
rec_FOVx = hdr.encoding.reconSpace.fieldOfView_mm.x;
rec_FOVy = hdr.encoding.reconSpace.fieldOfView_mm.y;
rec_FOVz = hdr.encoding.reconSpace.fieldOfView_mm.z;

try
    nSlices = hdr.encoding.encodingLimits.slice.maximum + 1;
catch
    nSlices = 1;
end

try 
    nCoils = hdr.acquisitionSystemInformation.receiverChannels;
catch
    nCoils = 1;
end

try
    nReps = hdr.encoding.encodingLimits.repetition.maximum + 1;
catch
    nReps = 1;
end

try
    nContrasts = hdr.encoding.encodingLimits.contrast.maximum + 1;
catch
    nContrasts = 1;
end
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

%% Reconstruct
allpts = [];
reconImages = {};
nimages = 0;
b = zeros(1,nContrasts);
for i = 1:nContrasts
    acqs = find(meas.head.idx.contrast == i-1);
    b(i) = meas.head.user_float(1,acqs(1));
end
recon_image = zeros(rec_Nx/2,rec_Ny,nContrasts,nSlices);
K_space = zeros(enc_Nx,enc_Ny*2,enc_Nz,nContrasts,nSlices,nCoils);
for rep = 1:nReps
    for contrast = 1:nContrasts
        for slice = 1:nSlices
            % Initialize the K-space storage array
            K = zeros(enc_Nx, enc_Ny, enc_Nz, nCoils);
            % Select the appropriate measurements from the data
            acqs = find(  (meas.head.idx.contrast==(contrast-1)) ...
                        & (meas.head.idx.repetition==(rep-1)) ...
                        & (meas.head.idx.slice==(slice-1)));
            for p = 1:length(acqs)
                ky = meas.head.idx.kspace_encode_step_1(acqs(p)) + 1;
                kz = meas.head.idx.kspace_encode_step_2(acqs(p)) + 1;
                K(:,ky,kz,:) = meas.data{acqs(p)};
            end
            %Zero Pad along the y direction
            myim = zeros(rec_Nx,rec_Ny,rec_Nz,nCoils);

            col_center = hdr.encoding.encodingLimits.kspace_encoding_step_0.center;
            phs_center = hdr.encoding.encodingLimits.kspace_encoding_step_1.center;

            cenx = floor(rec_Nx/2);
            ceny = floor(rec_Ny/2);

            myim((cenx-col_center+1):(cenx-col_center+enc_Nx),(ceny-phs_center+1):(ceny-phs_center+enc_Ny),:,:) = K;
            K_space(:,(ceny-phs_center+1):(ceny-phs_center+enc_Ny),:,contrast,slice,:) = K;
            %myim((ceny-phs_center):(ceny-phs_center+enc_Ny-1),(cenx-col_center):(cenx-col_center+enc_Nx-1),:,:) = K';

            myim = fftshift(ifft(fftshift(myim,1),[],1),1);
            myim = fftshift(ifft(fftshift(myim,2),[],2),2);
            
            % Reconstruct in x
            % K = fftshift(ifft(fftshift(K,1),[],1),1);
            
            myim = sqrt(sum(abs(myim).^2,4));
            myim = rot90(myim,2);
            nimages = nimages + 1;
            recon_image(:,:,contrast,slice) = myim((rec_Nx/4+1):(3*rec_Nx/4),:);
        end
    end
end
recon_image = squeeze(recon_image);
K_space = squeeze(K_space);

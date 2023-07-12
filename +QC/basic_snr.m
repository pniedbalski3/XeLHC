function SNR = basic_snr(Im,figname)

if nargin < 2
    figname = 'Basic SNR';
else
    figname = ['Basic SNR - ' figname];
end
Im = abs(Im);

% Get a tiled image containing all slices
Ims_tiled = imtile(Im);
%Normalize Image
Ims_tiled = Ims_tiled/max(Ims_tiled(:));

%Generate a mask using Otsu's method
Mask_tiled = imbinarize(Ims_tiled,graythresh(Ims_tiled));
%Dilate mask to avoid partial volume/artifacts at edge of the signal
Mask_dilate = imdilate(Mask_tiled,strel('disk',5));
Noise_Mask = ~Mask_dilate;

Noise = Ims_tiled(Noise_Mask==1);
% Some of the Ims_tiled noise voxels might = 0 due to filling the matrix
% for display. Get rid of those before calculating standard deviation
Noise(Noise==0) = [];

SNR = mean(Ims_tiled(Mask_tiled==1))/std(Noise);

%Output Figure as a sanity check
SNR_Fig = figure('Name',figname);
set(SNR_Fig,'color','white','Units','inches','Position',[0.25 0.25  8 8])
TwoBinMap =  [1 0 0; 0 1 0];
ImMax = max(Ims_tiled(:));
Seg = Mask_tiled*2 + Noise_Mask;
Tools.imoverlay(squeeze(Ims_tiled),squeeze(Seg),[1,2],[0,0.99*ImMax],TwoBinMap,0.5,gca);
colormap(TwoBinMap);

snr_label = ['SNR = ' num2str(SNR,3)];

textColor = 'white';
textBackground = 'black';
text(.90*size(Ims_tiled,1),0.90*size(Ims_tiled,2), ...
     snr_label, ...
     'Color', textColor, ...
     'BackgroundColor', textBackground, ...
     'HorizontalAlignment', 'Center'); 
function diff_fig_handle = rep_xelhc_diff(participant_folder)

if nargin < 1
    participant_folder = uigetdir();
end

load(fullfile(participant_folder,'Diffusion_Analysis.mat'),'ADC','mask');
try
    load(fullfile(participant_folder,'DiffMask_Manual.mat'),'mask');
catch
end

mask = double(mask);
CMap = parula(256);
CMap(1,:) = [0 0 0];

ADC = ADC.*mask;
ADC(ADC < 0) = 0;

myslice = 1;
most_pts = 0;
for i = 1:size(mask,3)
    tmp = sum(squeeze(mask(:,:,i)),'all');
    if tmp>most_pts
        most_pts = tmp;
        myslice = i;
    end
end

figure('Name','Representative_Diff')
imagesc(ADC(:,:,myslice));
axis off
colormap(CMap);
axis square;

clim([0 0.06])
diff_fig_handle = gca; 
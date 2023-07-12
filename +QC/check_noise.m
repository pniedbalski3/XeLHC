function check_noise(Im,kspace,figname)
if nargin < 3
    figname = 'Check Noise Characteristics';
else
    figname = ['Check Noise Characteristics - ' figname];
end
%% First do Image
ImNoise = Im(:);

figure('Name',figname)
tiledlayout(1,2)

data_pnts = length(ImNoise);
std_real = std(real(ImNoise));
sim_real = normrnd(0,std_real,1,data_pnts); % simulate gaussian noise

std_img = std(imag(ImNoise));
sim_img = normrnd(0,std_img,1,data_pnts);
sim_mag = abs(complex(sim_real,sim_img)); % simulate magnitude noise data
mag_data = abs(ImNoise);% experimental noise data
nexttile;
qqplot(sim_mag,mag_data);
title('Collected vs Simulated Magnitude Q-Q Plot - Image Data');
xlim([0 max(sim_mag)]);
ylim([0 max(mag_data)]);

%% Now, do k-space
ImNoise = kspace(:);

data_pnts = length(ImNoise);
std_real = std(real(ImNoise));
sim_real = normrnd(0,std_real,1,data_pnts); % simulate gaussian noise

std_img = std(imag(ImNoise));
sim_img = normrnd(0,std_img,1,data_pnts);
sim_mag = abs(complex(sim_real,sim_img)); % simulate magnitude noise data
mag_data = abs(ImNoise);% experimental noise data
nexttile;
qqplot(sim_mag,mag_data);
title('Collected vs Simulated Magnitude Q-Q Plot - kspace Data');
xlim([0 max(sim_mag)]);
ylim([0 max(mag_data)]);

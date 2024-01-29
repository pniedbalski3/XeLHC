function [gas_hires,gas_lores,dis,gas_k,dis_k] = xpdixon_recon(filename,delay_cor)
%%
if nargin < 2
    delay_cor = 0;
end
%%
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

%% Get Data
Gas_ind1 = find(meas.head.idx.contrast == 1 & meas.head.measurement_uid == 0 & meas.head.idx.set == 1);
[fid(:,:,1),traj(:,:,:,1)] = ReadData.get_xpdixon_mrd(meas,Gas_ind1);

Gas_ind2 = find(meas.head.idx.contrast == 1 & meas.head.measurement_uid == 0 & meas.head.idx.set == 2);
[fid(:,:,2),traj(:,:,:,2)] = ReadData.get_xpdixon_mrd(meas,Gas_ind2);

Dis_ind1 = find(meas.head.idx.contrast == 2 & meas.head.measurement_uid == 0 & meas.head.idx.set == 1);
[fid(:,:,3),traj(:,:,:,3)] = ReadData.get_xpdixon_mrd(meas,Dis_ind1);

Dis_ind2 = find(meas.head.idx.contrast == 2 & meas.head.measurement_uid == 0 & meas.head.idx.set == 2);
[fid(:,:,4),traj(:,:,:,4)] = ReadData.get_xpdixon_mrd(meas,Dis_ind2);

Dis_ind3 = find(meas.head.idx.contrast == 2 & meas.head.measurement_uid == 0 & meas.head.idx.set == 3);
[fid(:,:,5),traj(:,:,:,5)] = ReadData.get_xpdixon_mrd(meas,Dis_ind3);

DisCal = find(meas.head.idx.contrast == 2 & meas.head.measurement_uid == 1);
DisCal_Data =meas.data(DisCal);
discal = zeros(length(DisCal_Data{1}),length(DisCal_Data));
for i = 1:length(DisCal_Data)
    discal(:,i) = DisCal_Data{i};
end

FACal = find(meas.head.idx.contrast == 1 & meas.head.measurement_uid == 2);
FACal_Data =meas.data(FACal);
facal = zeros(length(FACal_Data{1}),length(FACal_Data));
for i = 1:length(FACal_Data)
    facal(:,i) = FACal_Data{i};
end
%% Reconstruct Images

SharpIms = zeros([ImSize 5]);
BroadIms = zeros([ImSize 5]);

for i = 1:size(fid,3)
    tmpfid = reshape(fid(:,:,i),1,[])';
    traj(:,:,:,i) = Reconstruct.traj_delay_correction(traj(:,:,:,i),delay_cor);
    tmptraj = [reshape(traj(1,:,:,i),1,[])' reshape(traj(2,:,:,i),1,[])' reshape(traj(3,:,:,i),1,[])'];
    
    SharpIms(:,:,:,i) = Reconstruct.sharp_kern_recon(ImSize,tmpfid,tmptraj);
    BroadIms(:,:,:,i) = Reconstruct.broad_kern_recon(ImSize,tmpfid,tmptraj);
end


%% TODO: Add Post-dissolved spectra analysis, Flip Cal analysis
dsclim = [0 max(max(max(abs(SharpIms(:,:,:,3)))))];
dbclim = [0 max(max(max(abs(BroadIms(:,:,:,3)))))];
gsclim = [0 max(max(max(abs(SharpIms(:,:,:,1)))))];
gbclim = [0 max(max(max(abs(BroadIms(:,:,:,1)))))];
% % 
for i = 1:5
    figure('Name',['Image_' num2str(i) '_sharp_recon']);
    montage(abs(squeeze(SharpIms(:,:,:,i))))
    if i<3
        clim(gsclim);
    else
        clim(dsclim);
    end

    figure('Name',['Image_' num2str(i) '_broad_recon']);
    montage(abs(squeeze(BroadIms(:,:,:,i))))
    if i<3
        clim(gbclim);
    else
        clim(dbclim);
    end
end

%% Dissolved spectra analysis
discal_ave = double(mean(discal,2));
Dw = double(meas.head.sample_time_us(DisCal(1)));

t = (0:(length(discal_ave)-1))*Dw;

GasFreq = hdr.userParameters.userParameterLong(1).value;
DisFreq = hdr.userParameters.userParameterLong(2).value;

DisFreq = DisFreq+GasFreq;

chem_shift = (DisFreq-GasFreq)/GasFreq * 1e6;

Rfreq_guess = GasFreq*218*1e-6 - GasFreq*chem_shift*1e-6;
Mfreq_guess = GasFreq*197*1e-6 - GasFreq*chem_shift*1e-6;
Gfreq_guess = GasFreq - DisFreq;

disfitObj = SpecFit.NMR_TimeFit_v(discal_ave,t,[1 1 1],[Rfreq_guess Mfreq_guess Gfreq_guess],[250 200 30],[0 200 0],[0 0 0],0,length(t)); % first widths lorenzian, 2nd are gauss
disfitObj = disfitObj.fitTimeDomainSignal();

disfitFinal = Dw*fftshift(fft(disfitObj.calcComponentTimeDomainSignal(t),[],1),1);

RBCspec = disfitObj.area(1);
Memspec = disfitObj.area(2);

R2M = RBCspec/Memspec;

figure('Name','Calibration Check');
plot(disfitObj.f,abs(disfitObj.spectralDomainSignal),'k');
hold on
plot(disfitObj.f,abs(sum(disfitFinal,2)),'Color',[0 0 1 0.33],'LineWidth',3)
xlabel('Frequency (Hz)')
ylabel('NMR Signal (a.u.)')
title(['RBC/Membrane = ' num2str(R2M,3)]);

%% Gas Flip Cal Analysis
Amps = max(abs(facal));

fitfunct = @(coefs,xdata)coefs(1)*cos(coefs(2)).^(xdata-1);   % cos theta decay
guess(1)=max(Amps);
guess(2)=20*pi/180;       % just guess 10 degrees

xdata=1:length(Amps);
ydata = Amps;

fitoptions = optimoptions('lsqcurvefit','Display','off');
[fitparams,resnorm,residual,exitflag,output,lambda,jacobian]  = lsqcurvefit(fitfunct,guess,xdata,ydata,[],[],fitoptions);
ci = nlparci(fitparams,residual,jacobian);  % returns 95% conf intervals on fitparams by default
param_err=fitparams-ci(:,1)';
flip_angle=abs(fitparams(2)*180/pi);
flip_err=param_err(2)*180/pi;

%% Gas Contamination Correction
%Code adapted from Andrew Hahn/Sean Fain

Dw = meas.head.sample_time_us(1)*1e-6;
t_arm = double(0:Dw:((size(fid,1)-1)*Dw));

%t_thresh = 0.003;  % use the data collected after 3ms for correction
GasFreq = hdr.userParameters.userParameterLong(1).value;
DisFreq = hdr.userParameters.userParameterLong(2).value;

DisFreq = GasFreq+DisFreq;

demod_freq = GasFreq-DisFreq;  % acquisistion frequency difference between gas and dissolved

% tC = double((1:size(d,2)).*t(1));   % acquisition times for correction 
% tF = tC(tC >= t_thresh);     % acquisition times for fitting
% gas_views = d(gpv,tC >= t_thresh);  % gas phase data valid for fitting
% dissolved_views = d(dpv,tC >= t_thresh);    % dissolved phase data valid for fitting

t_gas1 = hdr.sequenceParameters.TE(1)*1e-3 + t_arm';
t_gas2 = hdr.sequenceParameters.TE(2)*1e-3 + t_arm';
t_dis1 = hdr.sequenceParameters.TE(3)*1e-3 + t_arm';
t_dis2 = hdr.sequenceParameters.TE(4)*1e-3 + t_arm';
t_dis3 = hdr.sequenceParameters.TE(5)*1e-3 + t_arm';

% nonlinear optimization options
fitOptions = optimoptions('lsqcurvefit');
fitOptions.Display = 'iter';
fitOptions.MaxIter = 10000;
fitOptions.TolFun=1E-16;
fitOptions.TolX = 1E-15;
fitOptions.FinDiffType = 'central';
fitOptions.Algorithm = 'trust-region-reflective';
fitOptions.MaxFunEvals = 5000;

% Objective function for data after echo 1, used for estimation of
% correction parameters
fun = @(beta,X) X.*exp(2i.*pi.*(beta - repmat(t_dis3, [1 size(fid,2)]).*(demod_freq)));
beta0 = 1i.*log(2)/2/pi + 1-2*rand(1);
beta_fit = lsqcurvefit(fun,beta0,double(fid(:,:,2)), double(fid(:,:,5)),[],[],fitOptions);

% Objective funcion for all data, used for applying the correction
fun = @(beta,X) X.*exp(2i.*pi.*(beta - repmat(t_dis1, [1 size(fid,2)]).*(demod_freq)));
disfid_corrected = fid(:,:,3) - fun(beta_fit,fid(:,:,1));   % The variable d now contains contamination corrected data

%% Reconstruct Corrected:
tmpfid = reshape(disfid_corrected,1,[])';
tmptraj = [reshape(traj(1,:,:,1),1,[])' reshape(traj(2,:,:,1),1,[])' reshape(traj(3,:,:,1),1,[])'];

SharpDis_Cor = Reconstruct.sharp_kern_recon(ImSize,tmpfid,tmptraj);
BroadDis_Cor = Reconstruct.broad_kern_recon(ImSize,tmpfid,tmptraj);

%% See how this changes
% SNR_Dis = QC.basic_snr(squeeze(BroadIms(:,:,:,3)),'Uncorrected Dissolved');
% SNR_DisCor = QC.basic_snr(squeeze(BroadDis_Cor),'Corrected Dissolved');


%%
gas_hires = SharpIms(:,:,:,1);
gas_lores = BroadIms(:,:,:,1);
dis = BroadIms(:,:,:,3);
gas_k = fid(:,:,1);
dis_k = fid(:,:,3);

Gas_FA = hdr.sequenceParameters.flipAngle_deg(1);
Dis_FA = hdr.sequenceParameters.flipAngle_deg(2);
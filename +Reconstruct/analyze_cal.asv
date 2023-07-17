function [R2M,SNR] = analyze_cal(cal_file)

% Read in MRD data
dset = ismrmrd.Dataset(cal_file,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);

TR = hdr.sequenceParameters.TR;
GasFA = hdr.sequenceParameters.flipAngle_deg(1);
DisFA = hdr.sequenceParameters.flipAngle_deg(2);
TE = hdr.sequenceParameters.TE;

Dw = hdr.encoding.trajectoryDescription.userParameterDouble(1).value;

DisFreq = hdr.encoding.trajectoryDescription.userParameterDouble(3).value;
GasFreq = hdr.encoding.trajectoryDescription.userParameterDouble(2).value;

chem_shift = (DisFreq-GasFreq)/GasFreq * 1e6;

Rfreq_guess = GasFreq*218*1e-6 - GasFreq*chem_shift*1e-6;
Mfreq_guess = GasFreq*197*1e-6 - GasFreq*chem_shift*1e-6;
Gfreq_guess = GasFreq - DisFreq;

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

%% For now, I don't think I really care about the gas, so I can just get the dissolved spectra
Dis_ind = find(meas.head.idx.contrast == 1);

Dis_Spec = meas.data(Dis_ind);

%Throw out first 100 spectra
Dis_Spec(1:100) = [];

Dis_Avg = zeros(size(Dis_Spec(1)));

for i = 1:length(Dis_Spec)
    Dis_Avg = Dis_Avg + Dis_Spec{i};
end
% Need to make sure we have doubles:
Dis_Avg = double(Dis_Avg);

%% Fit spectra
Dw = Dw*1e-6; %Convert dwell from us to s.
t = (0:(length(Dis_Avg)-1))*Dw;

%Fit data. Element 1 is RBC, Element 2 is Membrane, Element 3 is Gas
disfitObj = SpecFit.NMR_TimeFit_v(Dis_Avg,t,[1 1 1],[Rfreq_guess Mfreq_guess Gfreq_guess],[250 200 30],[0 200 0],[0 0 0],0,length(t)); % first widths lorenzian, 2nd are gauss
disfitObj = disfitObj.fitTimeDomainSignal();

disfitFinal = Dw*fftshift(fft(disfitObj.calcComponentTimeDomainSignal(t),[],1),1);

%% Get a rough SNR calculation - take with a grain of salt since it's 400 spectra averaged
%Use end of spectrum opposite gas peak to get noise
Fin_Spectra = disfitObj.spectralDomainSignal;
Noise = std(Fin_Spectra((end-50):end));
RBC = disfitObj.area(1);
Mem = disfitObj.area(2);

SNR = disfitObj.area/Noise;

R2M = RBC/Mem;

%% Display Calibration

figure('Name','Calibration Check');
plot(disfitObj.f,abs(disfitObj.spectralDomainSignal),'k');
hold on
plot(disfitObj.f,abs(sum(disfitFinal,2)),'Color',[0 0 1 0.33],'LineWidth',3)
xlabel('Frequency (Hz)')
ylabel('NMR Signal (a.u.)')
title(['RBC/Membrane = ' num2str(R2M,3)]);




function [R2M,T2Star] = analyze_post_cal(filename)


dset = ismrmrd.Dataset(filename,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);

ImSize = [hdr.encoding.reconSpace.matrixSize.z hdr.encoding.reconSpace.matrixSize.z hdr.encoding.reconSpace.matrixSize.z];

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
elseramp
    noise = [];
end
meas  = D.select(firstScan:D.getNumber);
clear D;

Post_ind = zeros(1,length(meas.head.idx.set));
Post_ind(1,:) = meas.head.idx.contrast == 2 & meas.head.measurement_uid == 1;

Spec_FID(1,:) = meas.data(logical(Post_ind(1,:)));

TR = hdr.sequenceParameters.TR;
GasFA = hdr.sequenceParameters.flipAngle_deg(1);
DisFA = hdr.sequenceParameters.flipAngle_deg(2);
TE = hdr.sequenceParameters.TE;
Dw = meas.head.sample_time_us(find(Post_ind,1,"first"));


DisFreqoffset = hdr.userParameters.userParameterLong(2).value;
GasFreq = hdr.userParameters.userParameterLong(1).value;

chem_shift = DisFreqoffset/GasFreq * 1e6;

Rfreq_guess = GasFreq*218*1e-6 - GasFreq*chem_shift*1e-6;
Mfreq_guess = GasFreq*197*1e-6 - GasFreq*chem_shift*1e-6;
Gfreq_guess = -DisFreqoffset;

Dis_Avg = zeros(size(Spec_FID(1)));

for i = 1:length(Spec_FID)
    Dis_Avg = Dis_Avg + Spec_FID{i};
end

Dis_Avg = double(Dis_Avg);

%Should be safe to normalize data:
Dis_Avg = Dis_Avg/max(abs(Dis_Avg));

%% Fit spectra
%Dw = double(Dw*1e-6); %Convert dwell from us to s.
Dw = double(Dw);
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


T2Star(1) = 1/(pi * disfitObj.fwhm(3))*1000; %in ms
T2Star(2) = 1/(pi * max([disfitObj.fwhm(2),disfitObj.fwhmG(2)]))*1000; %in ms
T2Star(3) = 1/(pi * disfitObj.fwhm(1))*1000; %in ms


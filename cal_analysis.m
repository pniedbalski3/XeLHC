function Osc_Amp = cal_analysis(cal_file)

[mypath,myname,myext] = fileparts(cal_file);


if isempty(myext)
    write_path = cal_file;
    if ispc
        files = struct2cell(dir(fullfile(cal_file,'**\*')));
    else
        files = struct2cell(dir(fullfile(cal_file,'**/*')));
    end
    % files = struct2cell(dir(cal_file));
    names = files(1,:);
    myfile = names{find(contains(names,'calibration.'),1,'last')};
    cal_file = fullfile(files(2,find(contains(names,'calibration.'),1,'last')),myfile);
    cal_file = cal_file{1};
    myext = '.h5';

    [mypath,~,~] = fileparts(cal_file);
else
    write_path = my_path;
end



if strcmp(myext,'.dat')
    twix = DataImport.mapVBVD(cal_file);
    dwell_time = twix.hdr.MeasYaps.sRXSPEC.alDwellTime{1,1};
    dwell_time=dwell_time*1E-9; 
    nFids = twix.hdr.Config.NRepMeas;
    nPts = twix.hdr.Config.VectorSize;
    nDis = twix.hdr.Phoenix.sWipMemBlock.alFree{3};

    theFID = squeeze(double(twix.image()));
    te = twix.hdr.Phoenix.alTE{1}; 

    disData = theFID(:,1:nDis);

    %Kill the first and last 100 points (gets us 4.5s of data and avoids descent to steady state and low snr at end)?)
    disData(:,1:100) = [];
    disData(:,(end-100):end) = [];
    t = double((0:(length(disData)-1))*dwell_time');

    GasFreq = twix.hdr.Dicom.lFrequency;
    DisFreq = twix.hdr.MeasYaps.sWipMemBlock.alFree{5}+GasFreq;

    chem_shift = (DisFreq-GasFreq)/GasFreq * 1e6;

    Rfreq_guess = GasFreq*218*1e-6 - GasFreq*chem_shift*1e-6;
    Mfreq_guess = GasFreq*197*1e-6 - GasFreq*chem_shift*1e-6;
    Gfreq_guess = GasFreq - DisFreq;

elseif strcmp(myext,'.h5')
    dset = ismrmrd.Dataset(cal_file,'dataset');
    hdr = ismrmrd.xml.deserialize(dset.readxml);

    TR = hdr.sequenceParameters.TR;
    GasFA = hdr.sequenceParameters.flipAngle_deg(1);
    DisFA = hdr.sequenceParameters.flipAngle_deg(2);
    TE = hdr.sequenceParameters.TE;

    DisFreqoffset = hdr.userParameters.userParameterLong(2).value;
    GasFreq = hdr.userParameters.userParameterLong(1).value;
    
    chem_shift = DisFreqoffset/GasFreq * 1e6;
    
    Rfreq_guess = GasFreq*218*1e-6 - GasFreq*chem_shift*1e-6;
    Mfreq_guess = GasFreq*197*1e-6 - GasFreq*chem_shift*1e-6;
    Gfreq_guess = -DisFreqoffset;

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
    Dw = meas.head.sample_time_us(1);
    %% For now, I don't think I really care about the gas, so I can just get the dissolved spectra
    Dis_ind = find(meas.head.idx.contrast == 2);
    
    Dis_Spec = meas.data(Dis_ind);
    
    %Throw out first 100 spectra
    Dis_Spec(1:100) = [];
    Dis_Spec((end-100):end) = [];
    disData = zeros(length(Dis_Spec{1}),length(Dis_Spec));

    for i = 1:length(Dis_Spec)
        disData(:,i) = Dis_Spec{i};
    end
    if contains(hdr.acquisitionSystemInformation.institutionName,'Iowa')
        disData = conj(disData)/max(abs(disData(:)));
    end

    t = double((0:(length(disData)-1))*Dw')*1e-6;
end

Gas = zeros(140,1);
RBC = zeros(140,1);
Mem = zeros(140,1);
RBC_Shift = zeros(140,1);
Mem_Shift = zeros(140,1);
parfor j = 1:size(disData,2)
    disfitObj = SpecFit.NMR_TimeFit_v(disData(:,j),t',[1 1 1],[Rfreq_guess Mfreq_guess Gfreq_guess],[250 200 30],[0 200 0],[0 0 0],2,length(t)*2); % first widths lorenzian, 2nd are gauss
    disfitObj = disfitObj.fitTimeDomainSignal();
%    figure;disfitObj.plotTimeAndSpectralFit;
    Gas(j) = disfitObj.area(3);
    RBC(j) = disfitObj.area(1);
    Mem(j) = disfitObj.area(2);
    Mem_Shift(j) = disfitObj.freq(2);
    RBC_Shift(j) = disfitObj.freq(1);
end
save(fullfile(write_path,'Spectra_fittings.mat'),'Gas','RBC','Mem','Mem_Shift','RBC_Shift');

xdata = 0:0.015:(0.015*(size(RBC,1)-1));
myfit = fit(xdata',smooth(RBC),'exp2');

det_RBC = RBC./myfit(xdata);
det_RBC = det_RBC-1;

sinfit = fit(xdata',det_RBC,'sin1');
RBCfit = fit(xdata',det_RBC,'sin5');
RBCfitdata = RBCfit(xdata);

[max_valAll,maxlocs] = findpeaks(RBCfitdata,xdata,'MinPeakDistance',0.7);
[min_valAll,minlocs] = findpeaks(-RBCfitdata,xdata,'MinPeakDistance',0.7);
min_valAll = -min_valAll;

RBCsmooth = smooth(det_RBC);
[max2_valAll,max2locs] = findpeaks(RBCsmooth,xdata,'MinPeakDistance',0.7);
[min2_valAll,min2locs] = findpeaks(-RBCsmooth,xdata,'MinPeakDistance',0.7);
min2_valAll = -min2_valAll;

Amp_sinfit = 2*sinfit.a1*100;
Phase_sinfit = sinfit.c1;
Rate_sinfit = sinfit.b1/2/pi*60;

Amp_diffmeans = (mean(max2_valAll) - mean(min2_valAll))*100;
if length(max2_valAll) > length(min2_valAll)
max2_valAll = max2_valAll(1:length(min2_valAll));
max2locs = max2locs(1:length(min2_valAll));
elseif length(max2_valAll) < length(min2_valAll)
min2_valAll = min2_valAll(1:length(max2_valAll));
min2locs = min2locs(1:length(max2_valAll));
end
Amp_meandiffs = mean(max2_valAll - min2_valAll)*100;

Amp_fitdiffmeans = (mean(max_valAll) - mean(min_valAll))*100;
if length(max_valAll) > length(min_valAll)
max_valAll = max_valAll(1:length(min_valAll));
maxlocs = maxlocs(1:length(min_valAll));
elseif length(max_valAll) < length(min_valAll)
min_valAll = min_valAll(1:length(max_valAll));
minlocs = minlocs(1:length(max_valAll));
end
Amp_fitmeandiffs = mean(max_valAll - min_valAll)*100;

myfig = figure('Name','Spectra Fitting');
tiledlayout(1,2)
%figure('Name','How Much Data');
%plot(abs(disData(1,:)));
nexttile;
plot(xdata,det_RBC,xdata,sinfit(xdata));
title(['Osc Amp = ',num2str(Amp_sinfit,3)]);
nexttile;
plot(xdata,det_RBC,xdata,RBCfitdata); hold on
plot(maxlocs,max_valAll,'ok','MarkerFaceColor','k')
plot(minlocs,min_valAll,'ok','MarkerFaceColor','k')
title(['Fit Diff Means Osc Amp = ',num2str(Amp_fitdiffmeans,3)]);


Osc_Amp = Amp_fitdiffmeans;
% sinfit2 = fit(xdata',smooth(R2M),'sin1');
% R2MAmp_sinfit(i) = 2*sinfit2.a1;
% subplot(1,2,2)
% plot(xdata,R2M,xdata,sinfit2(xdata));
% title(['R2M Osc Amp = ',num2str(R2MAmp_sinfit(i),3)]);

set(gcf,'Position',[285 164 1368 754]);

saveas(myfig,fullfile(write_path,'Wiggle_Spectra_Figs_QC.png'))

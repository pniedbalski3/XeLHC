function results = check_cal_prot(cal_file)

% Read in MRD data
dset = ismrmrd.Dataset(cal_file,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);

TR = hdr.sequenceParameters.TR;
GasFA = hdr.sequenceParameters.flipAngle_deg(1);
DisFA = hdr.sequenceParameters.flipAngle_deg(2);
TE = hdr.sequenceParameters.TE;


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
Dw = meas.head.sample_time_us(1);

clear D;

Spectra = length(meas.data);
Pts = length(meas.data{1});

%Display to a table
Headings = {'Parameter','Prescribed','Acquired'};
MyData = {'TR','15', [num2str(TR)];...
            'TE','0.45',num2str(TE);...
            'Gas FA','20',num2str(GasFA);...
            'Dis FA','20',num2str(DisFA);...
            'Dwell Time','39',num2str(Dw);...
            'Spectral Pts','256',num2str(Pts);...
            'Total Spectra','520',num2str(Spectra)};

Out_Table = cell2table(MyData);
Out_Table.Properties.VariableNames = Headings;

%Out_Table = table(Headings,slice,Res);
Test = uifigure('Name','Check Calibration Protocol','HandleVisibility','on');
mytab = uitable(Test,'Data',Out_Table,'FontSize',20,'Position',[10 10 500 330]);
set(Test,'Position',[500 700 520 350]);

results = {TR,TE,GasFA,DisFA,Dw,Pts,Spectra};

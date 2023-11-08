function results = check_gx_prot(gx_file)

% Read in MRD data
dset = ismrmrd.Dataset(gx_file,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);
% Get Resolution and Slice Information
rec_Nx = hdr.encoding.reconSpace.matrixSize.x;
rec_Ny = hdr.encoding.reconSpace.matrixSize.y;
rec_Nz = hdr.encoding.reconSpace.matrixSize.z;

rec_FOVx = hdr.encoding.reconSpace.fieldOfView_mm.x;
rec_FOVy = hdr.encoding.reconSpace.fieldOfView_mm.y;
rec_FOVz = hdr.encoding.reconSpace.fieldOfView_mm.z;

TR = hdr.sequenceParameters.TR/1000;
GasFA = hdr.sequenceParameters.flipAngle_deg(2); %PJN will need to check GE data to make sure gas/dissolved are properly flagged
DisFA = hdr.sequenceParameters.flipAngle_deg(1);
TE = hdr.sequenceParameters.TE(1);
Dw = hdr.encoding.trajectoryDescription.userParameterDouble(1).value;

GasFreq = hdr.encoding.trajectoryDescription.userParameterDouble(3).value;
DisFreq = hdr.encoding.trajectoryDescription.userParameterDouble(4).value;

chem_shift = (DisFreq-GasFreq)/GasFreq * 1e6;

Resolution = [rec_FOVx/rec_Nx rec_FOVy/rec_Ny rec_FOVz/rec_Nz];

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

%% PJN - probably will need to adjust this once I have the multi-echo code. Will also need to test with GE data.
nacq = length(meas.data);

Dis_ind1 = find(meas.head.idx.contrast == 1 & meas.head.measurement_uid == 0 & meas.head.idx.set == 1);

nProj = length(Dis_ind1);
Pts = length(meas.data{1});

%%
%Display to a table
Headings = {'Parameter','Prescribed','Acquired'};
MyData = {'Resolution','6.25 x 6.25 x 6.25',[num2str(Resolution(1)) ' x ' num2str(Resolution(2)) ' x ' num2str(Resolution(3))]; ...
            'TR','15', [num2str(TR)];...
            'TE','0.45-0.5',num2str(TE);...
            'Gas FA','0.5',num2str(GasFA);...
            'Dis FA','20',num2str(DisFA);...
            'Dwell Time','20',num2str(Dw);...
            'Radial Pts','64',num2str(Pts);...
            'Projections','1000',num2str(nProj);...
            'Chemical Shift','208',num2str(chem_shift)};

Out_Table = cell2table(MyData);
Out_Table.Properties.VariableNames = Headings;

%Out_Table = table(Headings,slice,Res);
Test = uifigure('Name','Check Gas Exchange Protocol','HandleVisibility','on');
mytab = uitable(Test,'Data',Out_Table,'FontSize',20,'Position',[10 10 500 330]);
set(Test,'Position',[37 290 520 350]);

%% Save relevant results
results = {[num2str(Resolution(1)) ' x ' num2str(Resolution(2)) ' x ' num2str(Resolution(3))],TR,TE,GasFA,DisFA,Dw,Pts,nProj,chem_shift};

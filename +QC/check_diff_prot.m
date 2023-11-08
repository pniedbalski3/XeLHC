function results = check_diff_prot(diff_file)

% Read in MRD data
dset = ismrmrd.Dataset(diff_file,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);
% Get Resolution and Slice Information
rec_Nx = hdr.encoding.reconSpace.matrixSize.x;
rec_Ny = hdr.encoding.reconSpace.matrixSize.y;
rec_Nz = hdr.encoding.reconSpace.matrixSize.z;

rec_FOVx = hdr.encoding.reconSpace.fieldOfView_mm.x;
rec_FOVy = hdr.encoding.reconSpace.fieldOfView_mm.y;
rec_FOVz = hdr.encoding.reconSpace.fieldOfView_mm.z;

nSlices = hdr.encoding.encodingLimits.slice.maximum + 1;
nContrasts = hdr.encoding.encodingLimits.contrast.maximum + 1;

%% Need to pull data so that I can get b values:
D = dset.readAcquisition();
isNoise = D.head.flagIsSet('ACQ_IS_NOISE_MEASUREMENT');
firstScan = find(isNoise==0,1,'first');
if firstScan > 1
    noise = D.select(1:firstScan-1);
else
    noise = [];
end
meas  = D.select(firstScan:D.getNumber);
clear D;

%loop though contrasts and pull out b value
b = zeros(1,nContrasts);
for i = 1:nContrasts
    acqs = find(meas.head.idx.contrast == i-1);
    b(i) = meas.head.user_float(1,acqs(1));
end

Resolution = [rec_FOVx/rec_Nx rec_FOVy/rec_Ny rec_FOVz/rec_Nz];


%%
%Display to a table
Headings = {'Parameter','Prescribed','Acquired'};
MyData = {'Slices','<=9',num2str(nSlices); ...
            'Resolution','6 x 6 x 30',[num2str(Resolution(1)) ' x ' num2str(Resolution(2)) ' x ' num2str(Resolution(3))]; ...
            'b-Values','0 12', [num2str(b)]};

Out_Table = cell2table(MyData);
Out_Table.Properties.VariableNames = Headings;

%Out_Table = table(Headings,slice,Res);
Test = uifigure('Name','Check Diff Protocol','HandleVisibility','on');
mytab = uitable(Test,'Data',Out_Table,'FontSize',20,'Position',[10 10 337 162]);
set(Test,'Position',[37 679 357 182]);

%% Save results:
results = {[num2str(Resolution(1)) ' x ' num2str(Resolution(2)) ' x ' num2str(Resolution(3))],nSlices,[num2str(b)]};

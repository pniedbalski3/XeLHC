function results = check_vent_prot(vent_file)

% Read in MRD data
dset = ismrmrd.Dataset(vent_file,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);
% Get Resolution and Slice Information
rec_Nx = hdr.encoding.reconSpace.matrixSize.x;
rec_Ny = hdr.encoding.reconSpace.matrixSize.y;
rec_Nz = hdr.encoding.reconSpace.matrixSize.z;

rec_FOVx = hdr.encoding.reconSpace.fieldOfView_mm.x;
rec_FOVy = hdr.encoding.reconSpace.fieldOfView_mm.y;
rec_FOVz = hdr.encoding.reconSpace.fieldOfView_mm.z;

nSlices = hdr.encoding.encodingLimits.slice.maximum + 1;

Resolution = [rec_FOVx/rec_Nx rec_FOVy/rec_Ny rec_FOVz/rec_Nz];
%%
%Display to a table
Headings = {'Parameter','Prescribed','Acquired'};
MyData = {'Slices','>=12',num2str(nSlices); ...
            'Resolution','4 x 4 x 15',[num2str(Resolution(1)) ' x ' num2str(Resolution(2)) ' x ' num2str(Resolution(3))]};

Out_Table = cell2table(MyData);
Out_Table.Properties.VariableNames = Headings;

%Out_Table = table(Headings,slice,Res);
Test = uifigure('Name','Check Vent Protocol','HandleVisibility','on');
mytab = uitable(Test,'Data',Out_Table,'FontSize',20,'Position',[10 10 319 122]);
set(Test,'Position',[37 895 339 142]);

results = {Resolution,nSlices};
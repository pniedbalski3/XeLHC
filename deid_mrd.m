function deid_mrd(filename)
%% Get filename info and copy data file

[mypath,myfile,ext] = fileparts(filename);

deid_file = fullfile(mypath,[myfile '_deid' ext ]);

copyfile(filename,deid_file);

%% Read in dataset
dset = ismrmrd.Dataset(deid_file,'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);
if isfield(hdr.acquisitionSystemInformation,'systemVendor')
    %hdr.acquisitionSystemInformation.systemVendor = []; % I think it's
    %probably okay to have the Vendor in here, so that other people know
    %what type of scanner was used.
    hdr.acquisitionSystemInformation.systemModel = [];
    hdr.acquisitionSystemInformation.institutionName =[];
end
hdr.studyInformation.studyDate = [];
hdr.studyInformation.patientPosition = '';

if isfield(hdr.encoding.trajectoryDescription,'identifier')
    hdr.encoding.trajectoryDescription.userParameterLong = [];
end

xmlstring = ismrmrd.xml.serialize(hdr);
dset.writexml(xmlstring);

dset.close();

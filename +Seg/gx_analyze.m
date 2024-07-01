function gx_analyze(participant_folder,mask_okay)

if nargin < 2
    mask_okay = false;
end

GX_Version = '20240213_V1.0';

%% Read Files
mrd_files = ReadData.get_mrd(participant_folder);

folders = dir(participant_folder);
folders = struct2cell(folders);
getnames = folders(1,:);
myfolderind = find(contains(getnames,'sub-'));
bidsfolder = getnames{myfolderind};

%% Reconstruct Images
% Gas and Dissolved - don't need to write nifti
[I_Gas_Sharp,I_Gas_Broad,I_Dissolved,~,~] = Reconstruct.gx_recon(mrd_files.dixon{1},0,true);
I_Gas_Sharp = I_Gas_Sharp(:,:,:,1);
I_Gas_Broad = I_Gas_Broad(:,:,:,1);
I_Dissolved = I_Dissolved(:,:,:,1);
% 
[anat,~] = Reconstruct.gxanat_recon(mrd_files.ute{1},true);

%% Mask Anatomic Image

anat_name = [bidsfolder '_anat.nii.gz'];
maskpath = fullfile(participant_folder,bidsfolder,'xegx',strrep(anat_name,'anat.nii.gz','gxmask.nii.gz'));
if ~isfile(maskpath)
    mask = Seg.docker_segment(abs(anat));
    %Need to write Mask to bids:
    writemask = ReadData.mat2canon(mask);
    niftiwrite(writemask,fullfile(participant_folder,bidsfolder,'xegx',strrep(anat_name,'anat.nii.gz','gxmask')),'Compressed',true);
end

gxanat_fullpath = fullfile(participant_folder,bidsfolder,'xegx',anat_name);
gx_fullpath = fullfile(participant_folder,bidsfolder,'xegx',[bidsfolder '_sgas.nii.gz']);
%% Now, I should be able to load these files into ITK-snap for checking:
% Add logic so that this can be skipped for ease of re-analyzing after mask
% has been developed.
if ~mask_okay
    ITKSNAP_Path = '"C:\Program Files\ITK-SNAP 3.8\bin\ITK-SNAP.exe"';

    mycommand = [ITKSNAP_Path ' -g "' gx_fullpath '" -o "' gxanat_fullpath '" -s "' maskpath '"'];
    system(mycommand);
end

mask = double(niftiread(maskpath));
mask = ReadData.canon2mat(mask);

%%

dset = ismrmrd.Dataset(mrd_files.dixon{1},'dataset');
hdr = ismrmrd.xml.deserialize(dset.readxml);
Gas_FA = hdr.sequenceParameters.flipAngle_deg(1);
Dis_FA = hdr.sequenceParameters.flipAngle_deg(2);
TE = hdr.sequenceParameters.TE(3);
FOV = hdr.encoding.encodedSpace.fieldOfView_mm.z;

%% We can get Lung Volume here:
lung_vol = nnz(double(mask))*((FOV/size(I_Gas_Broad,1)).^3)*1e-6;
%%TODO: Recon and Masking done. Now run analysis and bin.
%% Analyze Calibration:
[R2M,~,T2Star] = Reconstruct.analyze_cal(mrd_files.cal{1});

%% Separate RBC and Membrane
[mem,rbc] = Reconstruct.dixon_sep(I_Dissolved(:,:,:,1),R2M,I_Gas_Broad(:,:,:,1),logical(mask));

%% Quantitative Corrections:
gas_scaled = abs(I_Gas_Broad)/(exp(-TE/T2Star(1)));
mem_cor = mem/(exp(-TE/T2Star(2)));
rbc_cor = rbc/(exp(-TE/T2Star(3)));

gas_scaled = gas_scaled*sind(Dis_FA)/sind(Gas_FA);
rbc2gas = abs(rbc_cor)./abs(gas_scaled).*mask*100;
mem2gas = abs(mem_cor)./abs(gas_scaled).*mask*100;

ventmax = prctile(abs(I_Gas_Sharp(mask==1)),99);
vent_scaled = abs(I_Gas_Sharp)/ventmax;
vent_scaled(vent_scaled>1) = 1;

%% Binning Images
%(Placeholders until I can get some good thresholds for 208 ppm excitation)

try
    [Data_Path,~,~] = fileparts(participant_folder);
    load(fullfile(Data_Path,'QC','Healthy_Reference.mat'));
catch
    vent_thresh = [0.1 0.3 0.5 0.7 0.9];
    rbc_thresh = [0.1 0.2 0.3 0.4 0.5];
    mem_thresh = [0.5 0.7 0.9 1.1 1.3 1.5 1.7];

    vent_edges = [-0.5, linspace(0,1,100) 1.5];
    mem_edges = [-100, linspace(0,mem_thresh(3)*3,100) 100];
    rbc_edges = [-100, linspace(0,rbc_thresh(3)*3,100) 100];

    vent_fit = nan;
    mem_fit = nan;
    rbc_fit = nan;
end


vent_bin = Reconstruct.bin_images(vent_scaled,vent_thresh);
vent_bin = vent_bin.*mask;
vent_mask = vent_bin;
vent_mask(vent_bin == 1) = 0;
vent_mask(vent_bin>1) = 1;
vent_mask = vent_mask.*mask;

%Get ventilated volume
vent_vol = nnz(double(vent_mask))*((FOV/size(I_Gas_Broad,1)).^3)*1e-6;

mem_bin = Reconstruct.bin_images(mem2gas,mem_thresh);
mem_bin = mem_bin.*vent_mask;

rbc_bin = Reconstruct.bin_images(rbc2gas,rbc_thresh);
rbc_bin = rbc_bin.*vent_mask;

%% Can make prettier pictures later. For now, just simple montages:
sixbinCmap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
eightbinCmap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for Membrane

RawFig = figure('Name','Raw Images');
set(gcf,'Position',[345 64 1226 800])
tiledlayout(4,1,'TileSpacing','none');
[~,firstslice,lastslice] = ImTools.getimcenter(mask);

nexttile;
montage(imtile(vent_scaled,'Frames',firstslice:lastslice,'GridSize',[2 NaN]));
clim(gca,[0 1]);ylabel('High Res Vent')

nexttile;
montage(imtile(gas_scaled,'Frames',firstslice:lastslice,'GridSize',[2 NaN]));
clim(gca,[0 max(gas_scaled(:))]);ylabel('Low Res Vent')

nexttile;
montage(imtile(mem_cor,'Frames',firstslice:lastslice,'GridSize',[2 NaN]));
clim(gca,[0 max(mem_cor(:))]);ylabel('Membrane');

nexttile
montage(imtile(rbc_cor,'Frames',firstslice:lastslice,'GridSize',[2 NaN]));
clim(gca,[0 max(rbc_cor(:))]);ylabel('RBC');

%% Histograms of Images

%We can see if one mega-figure will work for displaying histograms and
%images
SumFig = figure('Name','Gas Exchange Summary Histograms and Images','Position',[199 189 1466 689],'Color','white');
tiledlayout(3,5,'TileSpacing','compact');
nexttile;
%gas histogram first
QC.dis_hist(vent_scaled(mask==1),vent_edges,vent_thresh,sixbinCmap,vent_edges,vent_fit);
ylabel('Ventilation')
%then binned gas image
nexttile([1 4])
QC.overlay_montage(anat,vent_bin,mask,sixbinCmap,[1 6],1);
%and so on
nexttile
QC.dis_hist(mem2gas(mask==1),mem_edges,mem_thresh,eightbinCmap,mem_edges,mem_fit);
ylabel('Membrane')
nexttile([1 4])
QC.overlay_montage(anat,mem_bin,mask,eightbinCmap,[1 8],1);
nexttile
QC.dis_hist(rbc2gas(mask==1),rbc_edges,rbc_thresh,sixbinCmap,rbc_edges,rbc_fit);
ylabel('RBC')
nexttile([1 4])
QC.overlay_montage(anat,rbc_bin,mask,sixbinCmap,[1 6],1);

%% Save results
results_path = fullfile(participant_folder,'GX_Analysis');
if ~isfolder(results_path)
    mkdir(results_path);
end
save(fullfile(results_path,'GX_Results.mat'),'rbc2gas','mem2gas','vent_scaled','lung_vol','vent_vol','vent_bin','mem_bin','rbc_bin','gas_scaled','mask','vent_mask')

saveas(RawFig,fullfile(results_path,'Raw_GX_Images'),'jpg');
saveas(SumFig,fullfile(results_path,'Summary_GX_Images'),'jpg');

vent_D = nnz(vent_bin == 1)/nnz(mask)*100;
vent_L = nnz(vent_bin == 2)/nnz(mask)*100;
vent_H = nnz(vent_bin >4)/nnz(mask)*100;

mem_D = nnz(mem_bin == 1)/nnz(mask)*100;
mem_L = nnz(mem_bin == 2)/nnz(mask)*100;
mem_H = nnz(mem_bin > 5)/nnz(mask)*100;

rbc_D = nnz(rbc_bin == 1)/nnz(mask)*100;
rbc_L = nnz(rbc_bin == 2)/nnz(mask)*100;
rbc_H = nnz(rbc_bin >4)/nnz(mask)*100;

R2G = mean(rbc2gas(vent_mask==1));
M2G = mean(mem2gas(vent_mask==1));

[Data_Path,Participant,~] = fileparts(participant_folder);
sub_ind = strfind(Participant,'CAQA');
Participant = Participant(sub_ind:end);

if ~isfolder(fullfile(Data_Path,'QC'))
    mkdir(fullfile(Data_Path,'QC'))
end

excel_file = fullfile(Data_Path,'QC','GX_Analysis.xlsx');
matfile = fullfile(Data_Path,'QC','GX_Analysis.mat');

mymatch = [];

try 
    load(matfile,'AllAnalysis');
    mymatch = find(strcmpi(AllAnalysis.Participant,Participant));
catch
    headers = {'Participant',...
        'Lung Volume','Ventilated Volume',...
        'RBC/Mem','Mem/Gas','RBC/Gas',...
        'Vent Defect','Vent Low','Vent High',...
        'Mem Defect','Mem Low','Mem High',...
        'RBC Defect','RBC Low','RBC High',...
        'Analyzed By','Date Analyzed','Analysis Version'};
    AllAnalysis = cell2table(cell(0,size(headers,2)));
    AllAnalysis.Properties.VariableNames = headers;
end


NewData = [Participant,...
    lung_vol,vent_vol,...
    R2M,M2G,R2G,...
    vent_D,vent_L,vent_H,...
    mem_D,mem_L,mem_H,...
    rbc_D,rbc_L,rbc_H,...
    getenv('username'),{string(datetime("today"))},GX_Version];

if isempty(mymatch)
    AllAnalysis = [AllAnalysis;NewData];
else
    AllAnalysis(mymatch,:) = NewData;
end

AllAnalysis = sortrows(AllAnalysis);

save(matfile,'AllAnalysis')
writetable(AllAnalysis,excel_file,'Sheet',1)


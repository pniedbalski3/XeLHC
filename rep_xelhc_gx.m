function [mem_fig_handle,rbc_fig_handle] = rep_xelhc_gx(participant_folder)

if nargin < 1
    participant_folder = uigetdir();
end

load(fullfile(participant_folder,'GX_Analysis','GX_Results.mat'),'mem_bin','rbc_bin');

sub_folds = dir(participant_folder);
sub_folds = struct2cell(sub_folds);
names = sub_folds(1,:);
fold_ind = find(contains(names,'sub-'));
anat_fold = fullfile(participant_folder,sub_folds{1,fold_ind},'xegx');
anat_files = dir(anat_fold);
anat_files = struct2cell(anat_files);
anat_files = anat_files(1,:);
anat_ind = find(contains(anat_files,'anat.nii.gz'));
anat_path = fullfile(anat_fold,anat_files{1,anat_ind});
try
    anat = ReadData.canon2mat(double(niftiread(anat_path)));
catch
    anat = zeros(size(mem_bin));
end

% myslice = 1;
% most_pts = 0;
% for i = 1:size(rbc_bin,3)
%     tmp = nnz(squeeze(rbc_bin(:,:,i)));
%     if tmp>most_pts
%         most_pts = tmp;
%         myslice = i;
%     end
% end
mask = mem_bin;
mask(mask>0) = 1;

[myslice,~,~] = ImTools.getimcenter(mask);

sixbinCmap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
eightbinCmap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for Membrane

myslice_anat = squeeze(anat(:,:,myslice));
myslice_mem = squeeze(mem_bin(:,:,myslice));
myslice_rbc = squeeze(rbc_bin(:,:,myslice));

undermax = prctile(myslice_anat(:),99);

figure('Name','Representative_Mem')
ImTools.imoverlay(myslice_anat,myslice_mem,[1 8],[0 undermax],eightbinCmap,1,gca)
colormap(eightbinCmap);
mem_fig_handle = gca;

figure('Name','Representative_RBC')
ImTools.imoverlay(myslice_anat,myslice_rbc,[1 6],[0 undermax],sixbinCmap,1,gca)
colormap(sixbinCmap);
rbc_fig_handle = gca;
function diff_analysis(mypath)

%% Get files
files = dir(fullfile(mypath,'Raw'));
Cell_files = struct2cell(files);
file_names = Cell_files(1,:);
folder_names = Cell_files(2,:);

%% Find Diffusion File
xeprot = 'HPG_Diffusion';
xe_file = file_names{find(contains(file_names,xeprot),1,'last')};
xe_fold = folder_names{find(contains(file_names,xeprot),1,'last')};

xe_file = fullfile(xe_fold,xe_file);
%% Find Subject ID
Subj_ID = get_subject(mypath);

%% Convert to MRD
diff2mrd(Subj_ID,xe_file);

%% Find the MRD that was just written
mrd_files = ReadData.get_mrd(mypath);

%% Reconstruct Diffusion Images
[I_Diff,K_Diff,bval] = Reconstruct.gre_recon(mrd_files.diff{1});

%% Get b-val images and ADC
b0 = squeeze(I_Diff(:,:,1,:));
b12 = squeeze(I_Diff(:,:,2,:));

ADC = -1/bval(2)*log(b12./b0);

%% Mask
[~,mask] = erode_dilate(b12,2,5);

%% Display
Cmap = parula;
Cmap(1,:) = [0 0 0];
figure('Name','ADC Map')
montage(ADC.*mask)
colormap(Cmap);
caxis([0 0.14]);

%% Save Results
save(fullfile(mypath,'Diffusion_Analysis.mat'));

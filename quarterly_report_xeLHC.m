function uploaded_table = quarterly_report_xeLHC()

%% Generate Table
mypaths = {'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\XeLHC\MDAnderson_XeLHC_Upload',...
'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\XeLHC\Duke_XeLHC_Upload',...    
'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\XeLHC\UIC_XeLHC_Upload',...
'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\XeLHC\KUMC',...
'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\XeLHC\Iowa_XeLHC_Upload',...
};

headers = {'Enrolled','Calibration Uploaded','Ventilation Uploaded','Diffusion Uploaded','GX Uploaded'};
RowNames = {'BCM/MDAnderson','DUKE','UIC','KUMC','IOWA','Total'};
VarTypes = {'string','string','string','string','string'};
uploaded_table = table('Size',[6 5],'VariableTypes',VarTypes,'VariableNames',headers,'RowNames',RowNames);


n_enrolled = inputdlg({'BCM/MDA','DUKE','UIC','KUMC','IOWA'},'Enrolled Participants',[1 10;1 10;1 10;1 10;1 10],{'0','9','0','61','13'});

uploaded_table("BCM/MDAnderson","Enrolled") = n_enrolled(1);
uploaded_table("DUKE","Enrolled") = n_enrolled(2);
uploaded_table("UIC","Enrolled") = n_enrolled(3);
uploaded_table("KUMC","Enrolled") = n_enrolled(4);
uploaded_table("IOWA","Enrolled") = n_enrolled(5);

mycell{1,1} = num2str(str2double(n_enrolled{1})+str2double(n_enrolled{2})+str2double(n_enrolled{3})+str2double(n_enrolled{4})+str2double(n_enrolled{5}));

uploaded_table('Total','Enrolled') = mycell;

%% Look for Data
N_Cal = zeros(5,1);
N_Vent = zeros(5,1);
N_Diff = zeros(5,1);
N_GX = zeros(5,1);

for i = 1:length(mypaths)
    myfiles = dir(mypaths{i});
    myfiles = struct2cell(myfiles);
    part_fold = myfiles(1,:);
    part_path = myfiles(2,:);

    for j = 1:length(part_fold)
        if ~(contains(part_fold{j},'CAQA') || contains(part_fold{j},'CABA') || contains(part_fold{j},'CACB') || contains(part_fold{j},'CADD') || contains(part_fold{j},'BAAA')) || contains(part_fold{j},'_2')  
            continue
        else
            mrd_files = ReadData.get_mrd(fullfile(part_path{j},part_fold{j}));
            [Vent,~,Diff] = ReadData.find_dicoms(fullfile(part_path{j},part_fold{j}),false);
            subj = part_fold{j};
            subj = subj((end-6):end);

            if Vent
                
                %Check - if it has been analyzed (there is a bids folder)
                %but no ventilation_analysis folder, don't count it. If it
                %hasn't been analyzed (no bids folder) count it.
                if isfolder(fullfile(part_path{j},part_fold{j},['sub-' subj])) && isfolder(fullfile(part_path{j},part_fold{j},'Ventilation_Analysis'))
                    N_Vent(i) = N_Vent(i) + 1;
                elseif ~isfolder(fullfile(part_path{j},part_fold{j},['sub-' subj]))
                    N_Vent(i) = N_Vent(i) + 1;
                end
            else
                %There is at least one participant reconstructed using ICE,
                %so DICOM doesn't have all the metadata I need. Check for
                %analysis folders here:
                if isfolder(fullfile(part_path{j},part_fold{j},['sub-' subj])) && isfolder(fullfile(part_path{j},part_fold{j},'Ventilation_Analysis'))
                    N_Vent(i) = N_Vent(i) + 1;
                end
            end
            if Diff
                N_Diff(i) = N_Diff(i) + 1;
            else
                %There is at least one participant reconstructed using ICE,
                %so DICOM doesn't have all the metadata I need. Check for
                %analysis folders here:
                if isfolder(fullfile(part_path{j},part_fold{j},['sub-' subj],'xedwi')) 
                    N_Diff(i) = N_Diff(i) + 1;
                end
            end

            if ~isempty(mrd_files.dixon)
                N_GX(i) = N_GX(i) + 1;
            end
            if ~isempty(mrd_files.cal)
                N_Cal(i) = N_Cal(i) + 1;
            end
        end
    end
end

%% Write out to table
Cal_Cell = cell(6,1);
Vent_Cell = cell(6,1);
Diff_Cell = cell(6,1);
GX_Cell = cell(6,1);

for i = 1:5            
    Cal_Cell{i} = [num2str(N_Cal(i)) ' (' num2str(N_Cal(i)/str2double(n_enrolled(i))*100,'%.0f') ')' ];
    Vent_Cell{i} = [num2str(N_Vent(i)) ' (' num2str(N_Vent(i)/str2double(n_enrolled(i))*100,'%.0f') ')' ];
    Diff_Cell{i} = [num2str(N_Diff(i)) ' (' num2str(N_Diff(i)/str2double(n_enrolled(i))*100,'%.0f') ')' ];
    GX_Cell{i} = [num2str(N_GX(i)) ' (' num2str(N_GX(i)/str2double(n_enrolled(i))*100,'%.0f') ')' ];
end
total_enrolled = str2double(n_enrolled{1})+str2double(n_enrolled{2})+str2double(n_enrolled{3})+str2double(n_enrolled{4})+str2double(n_enrolled{5});
Cal_Cell{6} = [num2str(sum(N_Cal)) ' (' num2str(sum(N_Cal)/total_enrolled*100,'%.0f') ')' ];
Vent_Cell{6} = [num2str(sum(N_Vent)) ' (' num2str(sum(N_Vent)/total_enrolled*100,'%.0f') ')' ];
Diff_Cell{6} = [num2str(sum(N_Diff)) ' (' num2str(sum(N_Diff)/total_enrolled*100,'%.0f') ')' ];
GX_Cell{6} = [num2str(sum(N_GX)) ' (' num2str(sum(N_GX)/total_enrolled*100,'%.0f') ')' ];

uploaded_table(:,2) = Cal_Cell;
uploaded_table(:,3) = Vent_Cell;
uploaded_table(:,4) = Diff_Cell;
uploaded_table(:,5) = GX_Cell;

uploaded_table("IOWA","Enrolled") = n_enrolled(5);


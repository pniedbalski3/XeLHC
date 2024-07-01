function review_all()

myfold = 'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\XeLHC\KUMC';

Resp = listdlg('ListString',{'Vent','DWI','GX'},'PromptString','What images do you want to review?');


allpart = dir(myfold);
allpart = struct2cell(allpart);
allpart = allpart(1,:);

subjects = find(contains(allpart,'AQA'));

for i = 1:length(subjects)
    
    tmp = fullfile(myfold,allpart{1,subjects(i)});
    try
        if ismember(1,Resp)
            QC.review_vent(tmp);
        end
        if ismember(2,Resp)
            QC.review_dwi(tmp);
        end
        if ismember(3,Resp)
            QC.review_gx(tmp);
        end
    catch
        disp(['Subject ' allpart{1,subjects(i)} ' cannot be displayed'])
    end
end
    
    


function save_figures(myfold)
%A function to save all the currently open figures - Adapts on code found on
%stack exchange
% You have the option of passing a path to the function, and the files will
% be passed to that directory. Otherwise, the figures are saved in the
% current directory with their name as the file name - Make sure to name
% figures distinctly, otherwise, they will be overwritten.

if nargin < 1
    myfold = pwd;
end

%Some code from online help forums to save all open figures
FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
for iFig = 1:length(FigList)
    FigHandle = FigList(iFig);
    FigName   = get(FigHandle, 'Name');
    try
        print(FigHandle,fullfile(myfold,strrep(FigName,' ','_')),'-djpeg')
    catch
        exportapp(FigHandle,fullfile(myfold,[strrep(FigName,' ','_') '.jpeg']))
    end
end


   
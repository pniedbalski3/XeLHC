function overlay_montage(Under_Im,Over_Im,mask,Cmap,Clim,Alpha)

Under_Im = abs(Under_Im);
Over_Im = abs(Over_Im);

[~,firstslice,lastslice] = ImTools.getimcenter(mask);

Im1 = imtile(Under_Im,'Frames',firstslice:lastslice,'GridSize',[2 NaN]);
Im2 = imtile(Over_Im,'Frames',firstslice:lastslice,'GridSize',[2 NaN]);

undermax = prctile(Im1(:),99);

ImTools.imoverlay(Im1,Im2,Clim,[0 undermax],Cmap,Alpha,gca);
colormap(gca,Cmap);

%set(gcf,'Position',[430 230 830 690],'color','white');
function fShow(func,varargin)
switch(func)
    case 'Image'
        ShowImage;
    case 'Tracks'
        ShowTracks;
    case 'OffsetMap'
        ShowOffsetMap(varargin{1});        
    case 'Marker'
        ShowMarker(varargin{1},varargin{2});        
end

function ShowImage
global Stack;
global Config;
hMainGui=getappdata(0,'hMainGui');
if hMainGui.IsRunningShowIm==1
    return;
else
    hMainGui.IsRunningShowIm=1;
    setappdata(0,'hMainGui',hMainGui);
end
if ~isempty(Stack)
    y=size(Stack{1},1);
    x=size(Stack{1},2);
    idx=hMainGui.Values.FrameIdx;
    if idx>0
        Image=double(Stack{idx});
    else
        switch(idx)
            case -1 %Maximum
                Image=double(getappdata(hMainGui.fig,'MaxImage'));
            case -2 %Average
                Image=double(getappdata(hMainGui.fig,'AverageImage'));
            case -3    
                Image=zeros(y,x,3);
                Image(:,:,1)=getappdata(hMainGui.fig,'MaxImage');
                Image(:,:,2)=Image(:,:,1);
                Image(:,:,3)=Image(:,:,1);
                Image(:,:,1)=double(Stack{1});
                Image(:,:,2)=double(Stack{length(Stack)});
                %Image=(Image-hMainGui.Values.ScaleMin)/(hMainGui.Values.ScaleMax-hMainGui.Values.ScaleMin);
        end
    end
    if strcmp(get(hMainGui.ToolBar.ToolNormImage,'State'),'on') 
        if strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'off')
            Image=(Image-hMainGui.Values.ScaleMin)/(hMainGui.Values.ScaleMax-hMainGui.Values.ScaleMin);
        else
            ImageR=(Image-hMainGui.Values.ScaleRedMin)/(hMainGui.Values.ScaleRedMax-hMainGui.Values.ScaleRedMin);
            ImageG=(Image-hMainGui.Values.ScaleGreenMin)/(hMainGui.Values.ScaleGreenMax-hMainGui.Values.ScaleGreenMin);
            if strcmp(get(hMainGui.Menu.mRedGreenOverlay,'Checked'),'on')==1
                Image=zeros(y,fix(x/2),3);
                Image(:,1:fix(x/2),2)=ImageG(:,fix(x/2)+1:x);
            else
                Image=zeros(y,x,3);
                Image(:,fix(x/2)+1:x,2)=ImageG(:,fix(x/2)+1:x);
            end
            Image(:,1:fix(x/2),1)=ImageR(:,1:fix(x/2));
        end
    elseif strcmp(get(hMainGui.ToolBar.ToolThreshImage,'State'),'on')
        params = struct('scale',Config.PixSize,'fwhm_estimate',Config.Threshold.FWHM,'binary_image_processing',Config.Threshold.Filter);
        if strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'off')
            if strcmp(Config.Threshold.Mode,'Variable')==1
                Image=Image2Binary(Image,params);
            elseif strcmp(Config.Threshold.Mode,'Relative')==1
                if idx<0
                    idx=1;
                end
                params.threshold = round(hMainGui.Values.MeanStack(idx)*hMainGui.Values.RelThresh/100+hMainGui.Values.MinStack);
                Image=Image2Binary(Image,params);
            else
                params.threshold = hMainGui.Values.Thresh;
                Image=Image2Binary(Image,params);
            end
        else
            ImageR=Image;
            ImageG=Image;
            if strcmp(Config.Threshold.Mode,'Variable')==1
                ImageR=Image2Binary(ImageR,params);
                ImageG=Image2Binary(ImageG,params);            
            elseif strcmp(Config.Threshold.Mode,'Relative')==1
                if idx<0
                    idx=1;
                end
                params.threshold = round(hMainGui.Values.MeanRed(idx)*hMainGui.Values.RedRelThresh/100+hMainGui.Values.MinRed);
                ImageR=Image2Binary(ImageR,params);
                params.threshold = round(hMainGui.Values.MeanGreen(idx)*hMainGui.Values.GreenRelThresh/100+hMainGui.Values.MinGreen);
                ImageG=Image2Binary(ImageG,params);
            else
                params.threshold = hMainGui.Values.RedThresh;
                ImageR=Image2Binary(ImageR,params);
                params.threshold = hMainGui.Values.GreenThresh;
                ImageG=Image2Binary(ImageG,params);
            end
            if strcmp(get(hMainGui.Menu.mRedGreenOverlay,'Checked'),'on')==1
                Image=zeros(y,fix(x/2),3);
                Image(:,1:fix(x/2),2)=ImageG(:,fix(x/2)+1:x);
            else
                Image=zeros(y,x,3);
                Image(:,fix(x/2)+1:x,2)=ImageG(:,fix(x/2)+1:x);
            end
            Image(:,1:fix(x/2),1)=ImageR(:,1:fix(x/2));
        end
    end
    Image(Image<0)=0;
    Image(Image>1)=1;
    if size(Image,3)==1
       Image=Image*2^16;
    end
    if isempty(hMainGui.Image)
        delete(hMainGui.MidPanel.aView);
        hMainGui.MidPanel.aView = axes('Parent',hMainGui.MidPanel.pView,'ActivePositionProperty','Position','Units','normalized','Visible','on','Position',[0 0 1 1],'Tag','aView','NextPlot','add','YDir','reverse');
        hMainGui.Image=image(Image,'Parent',hMainGui.MidPanel.aView,'CDataMapping','scaled');
        set(hMainGui.MidPanel.aView,'CLim',[0 65535],'YDir','reverse','NextPlot','add','TickDir','in'); 
        set(hMainGui.fig,'colormap',colormap('Gray'));
    else
        set(hMainGui.Image,'CData',Image);
        hMainGui=SetZoom(hMainGui);
    end
    if idx>0
        ShowMarker(hMainGui,idx)
    end
    if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
        ShowOffsetMap(hMainGui);
    end
    set(hMainGui.MidPanel.aView,{'xlim','ylim'},hMainGui.ZoomView.currentXY,'Visible','off');
    if ~isempty(findobj('Tag','plotLineScan'))
        setappdata(0,'hMainGui',hMainGui);        
        fRightPanel('UpdateLineScan',hMainGui);
        hMainGui=getappdata(0,'hMainGui');
    end
end
hMainGui.IsRunningShowIm=0;
setappdata(0,'hMainGui',hMainGui);

function ShowMarker(hMainGui,idx)
global Objects;
global Molecule;
global Filament;
global Stack;
if ~isempty(Stack)
    x=size(Stack{1},2);
    set(0,'CurrentFigure',hMainGui.fig);
    set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
    if strcmp(get(hMainGui.Menu.mRedGreenOverlay,'Checked'),'on')==1&&strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'on')==1
        DisLeftRight=fix(x/2);
        m='o';
    else
        DisLeftRight=x;
        m='.';
    end
    delete(findobj('Parent',hMainGui.MidPanel.aView,'Tag','pObjects'));
    if get(hMainGui.RightPanel.pData.cShowAllMol,'Value')||get(hMainGui.RightPanel.pData.cShowAllFil,'Value')
        if get(hMainGui.RightPanel.pData.cShowAllMol,'Value')&&length(Objects)>=idx 
            if isfield(Objects{idx},'length')
                l=double([Objects{idx}.length]);
                TempMol=Objects{idx}(l==0);
                if ~isempty(TempMol)
                    X=[];
                    Y=[];            
                    X(:,1)=double([TempMol.center_x])/hMainGui.Values.PixSize;
                    X(X>DisLeftRight)=X(X>DisLeftRight)-DisLeftRight;
                    X(:,2)=X(:,1);            
                    Y(:,1)=double([TempMol.center_y])/hMainGui.Values.PixSize;
                    Y(:,2)=Y(:,1);            
                    h=line(X',Y','Marker','+','Tag','pObjects','Color','g');
                    set(h,'UIContextMenu',hMainGui.Menu.ctObjectMol,{'UserData'},num2cell(1:length(TempMol))');
                end
            end
        end
        if get(hMainGui.RightPanel.pData.cShowAllFil,'Value')&&length(Objects)>=idx    
            if isfield(Objects{idx},'length')
                l=double([Objects{idx}.length]);
                TempFil=Objects{idx}(l>0);
                nTempFil=length(TempFil);
                if get(hMainGui.RightPanel.pData.cShowWholeFil,'Value')==1
                    for i=1:nTempFil
                        if double([TempFil(i).center_x])/hMainGui.Values.PixSize>DisLeftRight
                            line([TempFil(i).data.x]/hMainGui.Values.PixSize-DisLeftRight,[TempFil(i).data.y]/hMainGui.Values.PixSize,'Tag','pObjects','Color','r');
                        else
                            line([TempFil(i).data.x]/hMainGui.Values.PixSize,[TempFil(i).data.y]/hMainGui.Values.PixSize,'Tag','pObjects','Color','r');
                        end
                    end
                end
                if ~isempty(TempFil)
                    X=[];
                    Y=[];
                    X(:,1)=double([TempFil.center_x])/hMainGui.Values.PixSize;
                    X(X>DisLeftRight)=X(X>DisLeftRight)-DisLeftRight;
                    X(:,2)=X(:,1);            
                    Y(:,1)=double([TempFil.center_y])/hMainGui.Values.PixSize;
                    Y(:,2)=Y(:,1);            
                    h=line(X',Y','Marker','x','Tag','pObjects','Color','g');
                    set(h,'UIContextMenu',hMainGui.Menu.ctObjectFil,{'UserData'},num2cell(1:length(TempFil))');
                end
            end
        end
    end    
    if ~isempty(Molecule)
        PlotMarker(hMainGui,Molecule,idx,DisLeftRight,m);
    end
    if ~isempty(Filament)
        PlotMarker(hMainGui,Filament,idx,DisLeftRight,m);
    end
end
   
function PlotMarker(hMainGui,Object,idx,DisLeftRight,m)
k=find([Object.Visible]==1&[Object.Selected]>-1);
p=1;
X=[];
Y=[];
for i=k
    t=find(Object(i).Results(:,1)==idx,1,'first');
    if ~isempty(t)>0
        if Object(i).Results(1,3)/hMainGui.Values.PixSize>DisLeftRight
            X(p,1:2)=Object(i).Results(t,3)/hMainGui.Values.PixSize-DisLeftRight;
        else
            X(p,1:2)=Object(i).Results(t,3)/hMainGui.Values.PixSize;
        end
        Y(p,1:2)=Object(i).Results(t,4)/hMainGui.Values.PixSize;
        C{p}=Object(i).Color;
        N{p}=Object(i).Name;
        p=p+1;
    end
end
if ~isempty(X)
    h=line(X',Y','Marker',m,'Tag','pObjects');
    set(h,{'Color'},C',{'UserData'},N');
end

function ShowTracks
global Molecule;
global Filament;
global Stack;
hMainGui=getappdata(0,'hMainGui');
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
if isempty(Stack)
    axis auto;
    x=NaN;
else
    x=size(Stack{1},2);
end
if strcmp(get(hMainGui.Menu.mRedGreenOverlay,'Checked'),'on')==1&&strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'on')==1
    DisLeftRight=fix(x/2);
else
    DisLeftRight=x;
end
delete(findobj('Tag','pTracks'));
if ~isempty(Molecule)
    Molecule=PlotTracks(hMainGui,Molecule,DisLeftRight);
end
if ~isempty(Filament)
    Filament=PlotTracks(hMainGui,Filament,DisLeftRight);
end
if isempty(Stack)&&isempty(Molecule)&&isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','Off');
    set(hMainGui.MidPanel.pNoData,'Visible','On');
else
    if isempty(Stack)
        xy=get(hMainGui.MidPanel.aView,{'xlim','ylim'});
        lx=(xy{1}(2)-xy{1}(1));
        ly=(xy{2}(2)-xy{2}(1));
        if ly>lx
            xy{1}(2)=xy{1}(1)+lx/2+ly/2;
            xy{1}(1)=xy{1}(1)+lx/2-ly/2;
        else
            xy{2}(2)=xy{2}(1)+ly/2+lx/2;            
            xy{2}(1)=xy{2}(1)+ly/2-lx/2;
        end
        set(hMainGui.MidPanel.aView,{'xlim','ylim'},xy);
        hMainGui.ZoomView.globalXY=xy;
        hMainGui.ZoomView.currentXY=xy;
        hMainGui.ZoomView.level=0;
        setappdata(0,'hMainGui',hMainGui);
    end
end

function Object=PlotTracks(hMainGui,Object,DisLeftRight)
for n=length(Object):-1:1
    if Object(n).Results(1,3)/hMainGui.Values.PixSize>DisLeftRight
        X=Object(n).Results(:,3)/hMainGui.Values.PixSize-DisLeftRight;
    else
        X=Object(n).Results(:,3)/hMainGui.Values.PixSize;
    end
    Y=Object(n).Results(:,4)/hMainGui.Values.PixSize;
    if length(X)==1
        X(1,2)=X;
        Y(1,2)=Y;
    end
    Object(n).pTrack=line(X,Y,'Color',Object(n).Color,'Tag','pTracks','Visible','on','LineStyle','-');        
    Object(n).pTrackSelectB=line(X,Y,'Color','black','Tag','pTracks','Visible','on','LineStyle','-.');
    Object(n).pTrackSelectW=line(X,Y,'Color','white','Tag','pTracks','Visible','on','LineStyle',':');    
end
Visible=[Object.Visible];
Selected=[Object.Selected];
pTrack=[Object.pTrack];
pTrackSelectW=[Object.pTrackSelectW];
pTrackSelectB=[Object.pTrackSelectB];
set(pTrack(~Visible|Selected<0),'Visible','off');
set(pTrackSelectW(~Visible|Selected~=1),'Visible','off');
set(pTrackSelectB(~Visible|Selected~=1),'Visible','off');

function ShowOffsetMap(hMainGui)
global Stack;
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
OffsetMap=getappdata(hMainGui.fig,'OffsetMap');
if isempty(Stack)
    axis auto;
    x=NaN;
else
    x=size(Stack{1},2);
end
if strcmp(get(hMainGui.Menu.mRedGreenOverlay,'Checked'),'on')==1&&strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'on')==1
    DisLeftRight=fix(x/2);
else
    DisLeftRight=x;
end
delete(findobj('Tag','pOffset'));
if ~isempty(OffsetMap.Match)
    PlotOffset(OffsetMap.Match,DisLeftRight,[]);
end
if ~isempty(OffsetMap.RedXY)
    PlotOffset(OffsetMap.RedXY,DisLeftRight,1);
end
if ~isempty(OffsetMap.GreenXY)
    PlotOffset(OffsetMap.GreenXY,DisLeftRight,1i);
end
% if isempty(Stack)
%     xy=get(hMainGui.MidPanel.aView,{'xlim','ylim'});
%     lx=(xy{1}(2)-xy{1}(1));
%     ly=(xy{2}(2)-xy{2}(1));
%     if ly>lx
%         xy{1}(2)=xy{1}(1)+lx/2+ly/2;
%         xy{1}(1)=xy{1}(1)+lx/2-ly/2;
%     else
%         xy{2}(2)=xy{2}(1)+ly/2+lx/2;            
%         xy{2}(1)=xy{2}(1)+ly/2-lx/2;
%     end
%     set(hMainGui.MidPanel.aView,{'xlim','ylim'},xy);
%     hMainGui.ZoomView.globalXY=xy;
%     hMainGui.ZoomView.currentXY=xy;
%     hMainGui.ZoomView.level=0;
%     setappdata(0,'hMainGui',hMainGui);
% end

function PlotOffset(XY,DisLeftRight,Mode)
hMainGui=getappdata(0,'hMainGui');
if isempty(Mode)
    X=XY(:,[1 3])/hMainGui.Values.PixSize;
    Y=XY(:,[2 4])/hMainGui.Values.PixSize;
else
    X=XY(:,1)/hMainGui.Values.PixSize;
    Y=XY(:,2)/hMainGui.Values.PixSize;
    X(:,2)=X(:,1);
    Y(:,2)=Y(:,1);    
end
X(X>DisLeftRight)=X(X>DisLeftRight)-DisLeftRight;
if isempty(Mode)
    h=line(X',Y','Color','red','Tag','pOffset','Visible','on','LineStyle','-.','Marker','none');
    set(h,'UIContextMenu',hMainGui.Menu.ctOffsetMapMatch,{'UserData'},num2cell((1:size(XY,1)))');
    h=line(X',Y','Color','green','Tag','pOffset','Visible','on','LineStyle',':','Marker','none');    
    set(h,'UIContextMenu',hMainGui.Menu.ctOffsetMapMatch,{'UserData'},num2cell((1:size(XY,1)))');
else
    if isreal(Mode)
        h=line(X',Y','Color','red','Tag','pOffset','Visible','on','Marker','*');
        set(h,'UIContextMenu',hMainGui.Menu.ctOffsetMap,{'UserData'},num2cell((1:size(XY,1)))');
    else
        h=line(X',Y','Color','green','Tag','pOffset','Visible','on','Marker','*');
        set(h,'UIContextMenu',hMainGui.Menu.ctOffsetMap,{'UserData'},num2cell((1:size(XY,1))*i)');
    end
end

function hMainGui=SetZoom(hMainGui)
Zoom=hMainGui.ZoomView;
if ~isempty(Zoom.globalXY)
    Zoom.currentXY=get(hMainGui.MidPanel.aView,{'xlim','ylim'});
    x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
    x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
    Zoom.level=round(-log(x_current/x_total)*8);
    hMainGui.ZoomView=Zoom;
end
Zoom=hMainGui.ZoomKymo;
if ~isempty(Zoom.globalXY)
    Zoom.currentXY=get(hMainGui.RightPanel.pTools.aKymoGraph,{'xlim','ylim'});
    x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
    x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
    Zoom.level=round(-log(x_current/x_total)*8);
    hMainGui.ZoomKymo=Zoom;
end
%setappdata(0,'hMainGui',hMainGui);
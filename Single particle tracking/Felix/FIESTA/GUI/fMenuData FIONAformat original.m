function fMenuData(func,varargin)
switch func
    case 'OpenStack'
        OpenStack(varargin{1});
    case 'SaveStack'
        SaveStack(varargin{1}); 
    case 'CloseStack'
        CloseStack(varargin{1});
    case 'LoadTracks'
        LoadTracks(varargin{1});
    case 'ImportTracks'
        ImportTracks(varargin{1});        
    case 'SaveTracks'
        SaveTracks(varargin{1}); 
    case 'SaveText'
        SaveText(varargin{1});         
    case 'ClearTracks'
        ClearTracks(varargin{1}); 
    case 'LoadObjects'
        LoadObjects(varargin{1});  
    case 'SaveObjects'
        SaveObjects(varargin{1});          
    case 'ClearObjects'
        ClearObjects(varargin{1});          
    case 'Export'
        Export(varargin{1});          
end

function OpenStack(hMainGui)
global Stack;
global StackInfo;
global Config;
global Molecule;
global Filament;
global FiestaDir;
filetype=get(gcbo,'UserData');
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Stack...');
set(hMainGui.MidPanel.pView,'Visible','off');
if strcmp(filetype,'MetaMorph')
    [FileName,PathName] = uigetfile({'*.stk','Metamorph Stack-Files (*.stk)'},'Select the Stack',FiestaDir.Stack); %open dialog for *.stk files 
else
    [FileName,PathName] = uigetfile({'*.tif','Multilayer TIFF-Files (*.tif)'},'Select the Stack',FiestaDir.Stack); %open dialog for *.stk files 
    if FileName~=0
        Config.Time = str2double(inputdlg({'Enter plane time difference in ms:'},'Time Information',1,{'100'}));
    end
end
if PathName~=0
    PixSize=str2double(inputdlg({'Enter Pixel Size in nm:'},'Pixel Size',1,{'100'}));
    if isempty(PixSize)
        PathName=0;
    end
end
if PathName~=0
    set(hMainGui.fig,'Pointer','watch');    
    CloseStack(hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    Config.PixSize=PixSize;
    failed=0;
    FiestaDir.Stack=PathName;
    f=[PathName FileName];
    try
        [Stack,TiffInfo,StackInfo]=StackRead(f); 
    catch   
        msgstr = lasterr;
        errordlg(msgstr,'Error');  
        failed=1;
    end
    if strcmp(filetype,'TIFF')
        nFrames=length(Stack);
        for i=0:nFrames-1
            StackInfo.CreationTime(i+1)=(i*Config.Time); %#ok<AGROW>
        end
    end
    if failed==0&&~isempty(Stack)
        set(hMainGui.fig,'Name',[hMainGui.Name ':' FileName]);
        Config.StackName=FileName;
        Config.Directory=PathName;
        hMainGui.Directory.Stack=PathName;
        Config.StackType=filetype;
    end
    hMainGui.Values.PixSize=Config.PixSize;
    set(hMainGui.Menu.mRedGreenOverlay,'Checked','off');
    hMainGui=DeleteAllRegions(hMainGui);
    hMainGui.Values.Stack=1;
    fShared('DeleteScan',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    fMainGui('InitGui',hMainGui);
else
    if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
        set(hMainGui.MidPanel.tNoData,'Visible','off');
        set(hMainGui.MidPanel.pView,'Visible','on');
    end
end
set(hMainGui.fig,'Pointer','arrow');
set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present');    

function SaveStack(hMainGui)
global Stack;
global FiestaDir
[FileName,PathName] = uiputfile({'*.tif','Multilayer TIFF-Files (*.tif)'},'Create New TIFF',FiestaDir.Stack); %open dialog for *.stk files 
if FileName~=0
    set(hMainGui.fig,'Pointer','watch');    
    file = [PathName FileName];
    if isempty(findstr('.tif',file))
        file = [file '.tif'];
    end
    h = waitbar(0,'Please wait...');
    for i=1:length(Stack)
        if i==1
            imwrite(Stack{i},file,'tiff','Compression','none','WriteMode','overwrite');
        else
            imwrite(Stack{i},file,'tiff','Compression','none','WriteMode','append');
        end
        waitbar(i/length(Stack))
    end
    close(h);
    set(hMainGui.fig,'Pointer','arrow');
end
    
function CloseStack(hMainGui)
global Stack;
global StackInfo;
global Molecule;
global Filament;
if ~isempty(Stack)
    Stack=[];
    StackInfo=[];
    hMainGui.Values.FrameIdx=0;
    hMainGui.Values.Stack=0;
    hMainGui.Values.PixSize=1;
    setappdata(hMainGui.fig,'Stack',Stack);
    setappdata(hMainGui.fig,'StackInfo',StackInfo);
    set(hMainGui.MidPanel.sFrame,'Enable','off');
    set(hMainGui.MidPanel.eFrame,'Enable','off','String','');  
    set(hMainGui.fig,'Name',hMainGui.Name);
    hMainGui=DeleteAllRegions(hMainGui);
    fRightPanel('AllToolsOff',hMainGui);
    fLeftPanel('DisableAllPanels',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    fMenuContext('DeleteScan',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    hMainGui.Measure=[];
    hMainGui.Plots.Measure=[];
    try
        delete(hMainGui.Image);
    catch
    end
    hMainGui.Image=[];
    hMainGui.Value.PixSize=1;
    delete(findobj('Parent',hMainGui.MidPanel.aView,'Tag','pObjects'));
    if isempty(Molecule)&&isempty(Filament)
        set(hMainGui.MidPanel.pView,'Visible','Off');
        set(hMainGui.MidPanel.pNoData,'Visible','On');
    end
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui);   
    fShow('Tracks');
end

function hMainGui=DeleteAllRegions(hMainGui)
nRegion=length(hMainGui.Region);
for i=nRegion:-1:1
    hMainGui.Region(i)=[];
    try
        delete(hMainGui.Plots.Region(i));
        hMainGui.Plots.Region(i)=[];
    catch
    end
    set(hMainGui.LeftPanel.pRegions.cRegion(i),'Enable','off','Value',0);
end

function LoadTracks(hMainGui)
global Stack
global Molecule;
global Filament;
global Config;
global FiestaDir;
fRightPanel('CheckDrift',hMainGui);
Mode=get(gcbo,'UserData');
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Data...');
set(hMainGui.MidPanel.pView,'Visible','off');
if strcmp(Mode,'local')
    LoadDir = fShared('GetLoadDir');
else
    LoadDir = [FiestaDir.Server 'Data' filesep];
end
[FileName, PathName] = uigetfile({'*.mat','FIESTA Data(*.mat)'},'Load FIESTA Tracks',LoadDir,'MultiSelect','on');
if ~iscell(FileName)
    FileName={FileName};
end
if PathName~=0
    set(hMainGui.fig,'Pointer','watch');
    if strcmp(Mode,'local')
       fShared('SetLoadDir',PathName);
    end
    FileName = sort(FileName);
    workbar(0/length(FileName),['Loading file 1 of ' num2str(length(FileName)) '...'],'Progress',-1);
    for n = 1 : length(FileName)
        tempMicrotubule=[];
        [tempMolecule,tempFilament]=fLoad([PathName FileName{n}],'Molecule','Filament');
        if isempty(tempMolecule)&&isempty(tempFilament)
            [tempMolecule,tempFilament,tempMicrotubule]=fLoad([PathName FileName{n}],'sMolecule','sFilament','sMicrotubule');
        end
    
        if isstruct(tempMicrotubule)&&~isstruct(tempFilament)
            tempFilament=tempMicrotubule;
        end
        if ~isfield(tempMolecule,'data')||~isfield(tempFilament,'data')
            warndlg(['Data in ' FileName{n} ' not compatible with FIESTA - try to Import Data'],'FIESTA Warning');
        else
            if ~isempty(tempMolecule)
                tempMolecule=fDefStructure(tempMolecule,'Molecule');
                Molecule=[Molecule tempMolecule]; %#ok<AGROW>
            end
            if ~isempty(tempFilament)
                sFilament=fDefStructure(tempFilament,'Filament');
                Filament=[Filament sFilament]; %#ok<AGROW>
                if strcmp(Config.RefPoint,'center')==1
                    field='ResultsCenter';
                elseif strcmp(Config.RefPoint,'start')==1
                    field='ResultsStart';
                else
                    field='ResultsEnd';
                end
                for i=1:length(Filament)
                    Filament(i).Results=Filament(i).(field);
                end
            end
        end
        workbar(n/length(FileName),['Loading file ' num2str(n+1) ' of ' num2str(length(FileName)) '...'],'Progress',-1);
    end
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui);        
    fShow('Image');
    fShow('Tracks');
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    set(hMainGui.MidPanel.pView,'Visible','on');

end
if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    drawnow expose
end 
set(hMainGui.fig,'Pointer','arrow');    
set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present');  
    
function ImportTracks(hMainGui)
global Molecule;
global Filament;
global Objects;
global Stack; x
fRightPanel('CheckDrift',hMainGui);
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Data...');
set(hMainGui.MidPanel.pView,'Visible','off');
[FileName, PathName] = uigetfile({'*.mat','FOTS Data(*.mat)'},'Import FOTS Tracks',fShared('GetLoadDir'));    
if FileName~=0
    set(hMainGui.fig,'Pointer','watch');
    fShared('SetLoadDir',PathName);
    Objects=[];
    [sMolecule,sMicrotubule]=fLoad([PathName FileName],'sMolecule','sMicrotubule');
    nsMol=length(sMolecule);
    if nsMol>0
        sMolecule=fDefStructure(sMolecule,'Molecule');
        for i=1:nsMol
            for j=1:size(sMolecule(i).Results,1)
                sMolecule(i).data{j}.x=sMolecule(i).Results(j,3);
                sMolecule(i).data{j}.y=sMolecule(i).Results(j,4);
                sMolecule(i).data{j}.h=sMolecule(i).Results(j,7);
                sMolecule(i).data{j}.w=sMolecule(i).Results(j,3);
                sMolecule(i).data{j}.l=0;
                sMolecule(i).data{j}.b=sMolecule(i).Results(j,6);
            end
            sMolecule(i).Results(:,6)=sqrt(sMolecule(i).Results(:,8).^2+sMolecule(i).Results(:,9).^2)*2*sqrt(log(4));
            sMolecule(i).Results(:,8)=1;
            sMolecule(i).Results(:,9:size(sMolecule(i).Results,2))=[];
        end
        Molecule=[Molecule sMolecule];
    end
    sFilament=sMicrotubule;
    nsFil=length(sFilament);
    if nsFil>0
        sFilament=fDefStructure(sFilament,'Filament');
        for i=1:nsFil
            if size(sFilament(i).Results,2)==5
                for j=1:size(sFilament(i).Results,1)
                    MicX=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,2);
                    MicY=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,3);
                    f=1:1:length(MicX);
                    ff=1:0.01:length(MicX);
                    MicXX=spline(f,MicX,ff);
                    MicYY=spline(f,MicY,ff);
                    MicLenVec=sqrt( (MicXX(2:length(MicXX))-MicXX(1:length(MicXX)-1)).^2 +...
                                    (MicYY(2:length(MicYY))-MicYY(1:length(MicYY)-1)).^2);
                    MicLen=sum(MicLenVec);      
                    u=round(length(MicXX)/3);
                    while sum(MicLenVec(1:u))<MicLen/2
                        u=u+1;
                    end
                    sFilament(i).Results(j,3)=MicXX(u);
                    sFilament(i).Results(j,4)=MicYY(u);
                    sFilament(i).Results(j,6)=sum(MicLenVec);
                    sFilament(i).data{j}.x=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,2);
                    sFilament(i).data{j}.y=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,3);
                    sFilament(i).data{j}.l=(sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,1)-1);
                    sFilament(i).data{j}.w=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,7);
                    sFilament(i).data{j}.b=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,4);
                    sFilament(i).data{j}.h=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,5);
                end
            end
            if (sFilament(i).Results(1,5)~=0)&&size(sFilament(i).Results,2)==6
                h=sFilament(i).Results(:,5);
                sFilament(i).Results(:,5)=sObject(i).Results(:,6);
                sFilament(i).Results(:,6)=h;
            end
        end
        sFilament.ResultsCenter=sFilament.Results;
        sFilament.ResultsStart=sFilament.Results;
        sFilament.ResultsEnd=sFilament.Results;
        Filament=[Filament sFilament];        
    end
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui)
    fShow('Image',hMainGui);
    fShow('Tracks',hMainGui);
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    set(hMainGui.MidPanel.pView,'Visible','on');    
end
if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    drawnow expose
end 
set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present');  
set(hMainGui.fig,'Pointer','arrow');
    
function SaveTracks(hMainGui)
global Molecule; %#ok<NUSED>
global Filament; %#ok<NUSED>
[FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Tracks',fShared('GetSaveDir'));
if FileName ~= 0
    set(gcf,'Pointer','watch');    
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    save(file,'Molecule','Filament');
    set(hMainGui.fig,'Pointer','arrow');    
end

function SaveText(hMainGui)
global Molecule;
global Filament;
Mode = get(gcbo,'UserData');
if ~isempty(Molecule) || ~isempty(Filament)
    if strcmp(Mode,'multiple')
        PathName = uigetdir(fShared('GetSaveDir'));
    else
        [FileName, PathName] = uiputfile({'*.txt','Delimeted Text (*.txt)'}, 'Save FIESTA Tracks as...',fShared('GetSaveDir'));
        file = [PathName FileName];
        if isempty(findstr('.txt',file))
            file = [file '.txt'];
        end
    end
    if PathName~=0
        set(gcf,'Pointer','watch');        
        fShared('SetSaveDir',PathName);
        if strcmp(Mode,'single')
            file_id = fopen(file,'w');
        end
        for n=1:length(Molecule)
            if strcmp(Mode,'multiple')
                file = [PathName filesep Molecule(n).Name '.txt'];
                file_id = fopen(file,'w');
            end
%             fprintf(file_id,'%s - %s%s\n',Molecule(n).Name,Molecule(n).Directory,Molecule(n).File);
%             %determine what kind of Molecule found
              nHeight = length(Molecule(n).data{1}.h);            
%             str = sprintf('Frame\tTime[s]\tXPosition[nm]\tYPosition[nm]\tDistance[nm]\t');
%             if length(Molecule(n).data{1}.w)==1 || nHeight > 1
%                 str = [str sprintf('FWHM[nm]\t')];
%             else
%                 str = [str sprintf('FWHM_X[nm]\tFWHM_Y[nm]\tOrientation\t')];
%             end
%             str = [str sprintf('0\t0')];
%             if nHeight > 1 
%                 str = [str sprintf('\tRadius of first ring[nm]\tFWHM of first ring\tIntensity of first ring')];                
%                 if nHeight > 2
%                     str = [str sprintf('\tRadius of second ring[nm]\tFWHM of second ring\tIntensity of second ring')];                
%                 end
%             end
%             fprintf(file_id,[str sprintf('\n')]);
            str = sprintf('%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f',n,0,0,0,0,0,0,0);
            fprintf(file_id,[str sprintf('\n')]);
            Results=Molecule(n).Results;
            for j=1:size(Results,1)
                str = sprintf('%f\t%f\t%f\t%f\t%f\t',Results(j,1),Results(j,2),Results(j,3),Results(j,4),Results(j,5));
                if length(Molecule(n).data{1}.w)==1 || nHeight > 1
                    str = [str sprintf('%f\t',Results(j,6))];
                else
                    str = [str sprintf('%f\t%f\t%f\t',Molecule(n).data{j}.w(1),Molecule(n).data{j}.w(2),Molecule(n).data{j}.w(3))];
                end
                str = [str sprintf('%f\t%f',Results(j,7),Results(j,8))];
                if nHeight > 1 
                    str = [str sprintf('\t%f\t%f\t%f',Results(j,9),Results(j,10),Results(j,11))];
                    if nHeight > 2
                        str = [str sprintf('\t%f\t%f\t%f',Results(j,12),Results(j,13),Results(j,14))];
                    end
                end
                fprintf(file_id,[str sprintf('\n')]);
            end
            %fprintf(file_id,'\n');
            if strcmp(Mode,'multiple')
                fclose(file_id);
            end
        end
        for n=1:length(Filament)
            if strcmp(Mode,'multiple')
                file = [PathName filesep Filament(n).Name '.txt'];
                file_id = fopen(file,'w');
            end
            fprintf(file_id,'%s - %s%s\n',Filament(n).Name,Filament(n).Directory,Filament(n).File);
            fprintf(file_id,'Track Data\n');
            fprintf(file_id,'Frame\tTime[s]\tXPosition[nm]\tYPosition[nm]\tDistance[nm]\tLength[nm]\tAverage Intensity\n');
            sRes=size(Filament(n).Results,1);
            for j=1:sRes
                fprintf(file_id,'%f\t%f\t%f\t%f\t%f\t%f\t%f\n',...
                           Filament(n).Results(j,1),Filament(n).Results(j,2),Filament(n).Results(j,3),Filament(n).Results(j,4),Filament(n).Results(j,5),Filament(n).Results(j,6),Filament(n).Results(j,7));        
            end
            fprintf(file_id,'\n');  
            for j=1:sRes
                fprintf(file_id,'Tracking Details\n');
                fprintf(file_id,'Frame\tTime[s]\tXPosition[nm]\tYPosition[nm]\tDistance[nm]\tLength[nm]\tAverage Intensity\n');
                fprintf(file_id,'%f\t%f\t%f\t%f\t%f\t%f\t%f\n',...
                           Filament(n).Results(j,1),Filament(n).Results(j,2),Filament(n).Results(j,3),Filament(n).Results(j,4),Filament(n).Results(j,5),Filament(n).Results(j,6),Filament(n).Results(j,7));        
                fprintf(file_id,'Pixel\tXPosition[nm]\tYPosition[nm]\tIntensity\n');
                nPos=length(Filament(n).data{j});
                for l=1:nPos
                    fprintf(file_id,'%f\t%f\t%f\t%f\n',l,Filament(n).data{j}(l).x,Filament(n).data{j}(l).y,Filament(n).data{j}(l).h);
                end
                fprintf(file_id,'\n');            
            end
            if strcmp(Mode,'multiple')
                fclose(file_id);
            end
        end
        if strcmp(Mode,'single')
            fclose(file_id);
        end
    end
end
set(hMainGui.fig,'Pointer','arrow');

function LoadObjects(hMainGui)
global Stack
global Objects;
global Molecule;
global Filament;
global FiestaDir;
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Data...');
set(hMainGui.MidPanel.pView,'Visible','off');
Mode = get(gcbo,'UserData');
if strcmp(Mode,'local')
    LoadDir = fShared('GetLoadDir');
else
    LoadDir = [FiestaDir.Server 'Data' filesep];
end
[FileName, PathName] = uigetfile({'*.mat','FIESTA Data(*.mat)'},'Load FIESTA Objects',LoadDir,'MultiSelect','on');    
if ~iscell(FileName)
    FileName={FileName};
end
if PathName~=0
    set(hMainGui.fig,'Pointer','watch');
    if strcmp(Mode,'local')
       fShared('SetLoadDir',PathName);
    end
    FileName = sort(FileName);
    workbar(0/length(FileName),['Loading file 1 of ' num2str(length(FileName)) '...'],'Progress',-1);
    for n = 1 : length(FileName)
        tempObjects = fLoad([PathName FileName{n}],'Objects');
        if isempty(tempObjects)
            tempObjects = fLoad([PathName FileName{n}],'sObjects');
            if isempty(tempObjects)
                warndlg(['No Objects detected in ' FileName{n}],'FIESTA Warning');            
            end
        end
        for m=1:length(tempObjects)
            if m>length(Objects)
                Objects{m} = tempObjects{m};
            else
                if isempty(Objects{m}) 
                    Objects{m} = tempObjects{m};
                else
                    Objects{m} = [Objects{m} tempObjects{m}];
                end
            end
        end
        workbar(n/length(FileName),['Loading file ' num2str(n+1) ' of ' num2str(length(FileName)) '...'],'Progress',-1);
    end
    hMainGui.File=FileName{n};
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui);   
    if ~isempty(Stack)
        fShow('Image',hMainGui);
        set(hMainGui.MidPanel.pNoData,'Visible','off')
        set(hMainGui.MidPanel.pView,'Visible','on');
    end
end
if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    drawnow expose
end    
set(hMainGui.fig,'Pointer','arrow');
set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present');  
    
function SaveObjects(hMainGui)
global Objects; %#ok<NUSED>
[FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Objects',fShared('GetSaveDir'));
if FileName~=0
    set(gcf,'Pointer','watch');
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    save(file,'Objects');
    set(hMainGui.fig,'Pointer','arrow');    
end

function ClearObjects(hMainGui)
global Objects;
Objects=[];
hMainGui.File=[];
fShared('UpdateMenu',hMainGui);  
fShow('Image',hMainGui);
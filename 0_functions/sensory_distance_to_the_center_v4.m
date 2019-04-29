%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% This script is for Quynh to calculate the distance from the sensory 
%  position to the center of the cell  
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
clear;close all;clc;
folder=uigetdir('Please select the folder that contains all the sensoryposition_generateddata.mat file generated by ALI_basalbody_analysis_Main');
cd(folder);
%--------------------------------------------------------------------------
% Identify the corresponding files 
%--------------------------------------------------------------------------
files_sensory = dir([folder '\*_sensoryposition_generateddata.mat']);
if isempty(files_sensory)
    display('no sensoryposition files identified under the current folder')
end
%--------------------------------------------------------------------------
% Sensory cilia position
%--------------------------------------------------------------------------
sensory_centroid_distance=[];
normalized_x=[];
normalized_y=[];
radius_all=[];
catch_sequence=[];
x_distance_all=[];
y_distance_all=[];
distance_all=[];
translate_direction_all=[];
cell_direction_all=[];
center_all=[];
contour=cell(length(files_sensory),1);
bounding_x_min_all=[];
bounding_x_max_all=[];
bounding_y_min_all=[];
bounding_y_max_all=[];
for i=1:length(files_sensory)
    try
    data=importdata(files_sensory(i).name);
    x_distance=data.x_distance(1);
    x_distance_all=[x_distance_all;data.sensory_x(1)];
    y_distance=data.y_distance(1);
    y_distance_all=[y_distance_all;data.sensory_y(1)];
    distance=(x_distance^2+y_distance^2)^0.5;
    distance_all=[distance_all;distance];
    sensory_centroid_distance=[sensory_centroid_distance;distance];
    x_distance_norm=data.x_distance_norm(1);
    y_distance_norm=data.y_distance(1)/data.heighth;
    normalized_x=[normalized_x;x_distance_norm];
    normalized_y=[normalized_y;y_distance_norm];
    width=data.width;
    height=data.heighth;
    radius=(width+height)/4;
    radius_all=[radius_all;radius];
    translate_direction_all=[translate_direction_all;data.translate_direction];
    cell_direction_all=[cell_direction_all,data.cell_direction];
    center=[(data.b+1)/2,(data.a+1)/2];
    center_all=[center_all;center];
    image_binary=im2bw(data.image_translate_rotate(:,:,1),1/255);
    convex_hull=regionprops(image_binary, 'ConvexHull');
    index=1:1:length(convex_hull.ConvexHull);
    indexi=1:0.01:length(convex_hull.ConvexHull);
    x_insert=interp1(index,convex_hull.ConvexHull(:,1),indexi, 'PCHIP');
    y_insert=interp1(index,convex_hull.ConvexHull(:,2),indexi, 'PCHIP');
    contour{i,1}=[x_insert',y_insert'];
    bounding_x_min_all=[bounding_x_min_all,data.bounding_x_min];
    bounding_x_max_all=[bounding_x_max_all,data.bounding_x_max];
    bounding_y_min_all=[bounding_y_min_all,data.bounding_y_min];
    bounding_y_max_all=[bounding_y_max_all,data.bounding_y_max];
   catch
     catch_sequence=[catch_sequence;i];
   end   
end
  outbounds=find(normalized_x<-0.5|normalized_y<-0.5|normalized_x>0.5|normalized_y>0.5);
  normalized_x(outbounds)=[];
  normalized_y(outbounds)=[];
  x_distance_all(outbounds)=[];
  y_distance_all(outbounds)=[];
  distance_all(outbounds)=[];
  contour(outbounds,:)=[];
  files_sensory(outbounds,:)=[]; 
  mkdir('sensory distance to cell center')  
  cd('sensory distance to cell center')
for i=1:length(contour)
   figure(1000);clf;
   if ~ isempty(contour{i,1})
   plot(contour{i,1}(:,1),contour{i,1}(:,2),'k.')
   hold on
   plot(x_distance_all(i,1),y_distance_all(i,1),'*')
   axis equal
   saveas(figure(1000),[num2str(i) '_.png'],'png'); 
   end
end
%--------------------------------------------------------------------------
% manual delete the out of bounds
%--------------------------------------------------------------------------
index_badcell=input('please input the index of the wrong cells for instance,[1 2 3], bracket is needed');
x_distance_all(index_badcell,:)=[];
y_distance_all(index_badcell,:)=[];
contour(index_badcell,:)=[];
%--------------------------------------------------------------------------
% calculate all the distances
%--------------------------------------------------------------------------
d1_all=[];
d2_all=[];
d3_all=[];
for i=1:length(contour)
    
    if ~ isempty(contour{i,1})
        center=[mean(contour{i,1}(:,1)),mean(contour{i,1}(:,2))];
        % d1: the distance from the sensory cilia to the center of the cell
        % d2: the distance from the senory cilia to the boundary of the cell 
        %     along the center-sensorycilia line
        % d3: the distance from the sensory cilia to the boundary of the cell
        d1=((x_distance_all(i,1)-center(1))^2+(y_distance_all(i,1)-center(2))^2)^0.5;
        d1_all=[d1_all,d1];
        [IDX,D] = knnsearch(contour{i,1}(:,1:2),center);
        d3=D;
        d3_all=[d3_all,d3];
   %-----------------------------------------------------------------------
   % how to calculate d2 ????
   %-----------------------------------------------------------------------   
   end
    clear center
end



%--------------------------------------------------------------------------
% save the whole workspace
%--------------------------------------------------------------------------
% cd ../
save('sensory distance to the center.mat')

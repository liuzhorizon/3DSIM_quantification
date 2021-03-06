%--------------------------------------------------------------------------
% PCD_diagnosis
%--------------------------------------------------------------------------
% This MATLAB script is written for PCD_diagnosis data analysis. It will
% calculate a series of parameters including PCD protein intensity, tubulin
% intensity, PCD protein/tubulin colocalization for subsequent Principle
% Component Analysis &Machine Learning Use 
%--------------------------------------------------------------------------
% Input: a 2 color image ended with .ome.tiff   
%        the green signal represents PCD protein
%        the red signal represents tubulin
% Outputs: 
%         tiff file
%          FileName(1:end-9)_green_sum.tif
%          FileName(1:end-9)_red_sum.tif
%         figure
%          identified contour displayed on the image
%         data
%          the calculated paramters
%         workspace         
%          workspace contained all the raw data
%--------------------------------------------------------------------------
% Zhen Liu
% liuzhorizon@gmail.com
% Feb 13th, 2017
%--------------------------------------------------------------------------
% 1. Only the green channel(for instance DNAH11) and red channel(for instance 
%    a tubulin) is needed.
% 2. The integrated DNAH11 intensity in the entire cilia is also calculated.  
% 3. Adding the free draw tool instead to replace the threshold setting
%    tool.
% Revised Feb 22th, 2017
% Adding the manual contrast tool
%--------------------------------------------------------------------------
% Version 3.0
%--------------------------------------------------------------------------
% Creative Commons License 3.0 CC BY  
%--------------------------------------------------------------------------
 clear;close all;clc;
%--------------------------------------------------------------------------
% image format processing and saving
%--------------------------------------------------------------------------
 [FileName,PathName]=uigetfile({'*.ome.tiff';'*.tif';'*.tiff'},...
                                                  'Select the image file');
 cd(PathName);
% load the tiff file
 info = imfinfo(FileName);
 num_images = numel(info);
 for k = 1:num_images
     SpecificFrameImage=imread(FileName, k, 'Info', info);
     movie_raw(:,:,k)=SpecificFrameImage;
 end
% seperate channels
 red_raw=movie_raw(:,:,1:1:end/2);
 green_raw=movie_raw(:,:,end/2:1:end);
% sum of seperate channels

red_raw_sum=sum(red_raw,3);   
green_raw_sum=sum(green_raw,3);

data_red=uint32(red_raw_sum);
data_green=uint32(green_raw_sum);

t_red=Tiff([FileName(1:end-9) '_red_sum.tif'],'w');
t_green=Tiff([FileName(1:end-9) '_green_sum.tif'],'w');

% Setup tags
% Lots of information here:
% http://www.mathworks.com/help/matlab/ref/tiffclass.html
tagstruct.ImageLength=size(data_red,1);
tagstruct.ImageWidth=size(data_red,2);
tagstruct.Photometric=Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample=32;
tagstruct.SamplesPerPixel=1;
tagstruct.RowsPerStrip=16;
tagstruct.PlanarConfiguration=Tiff.PlanarConfiguration.Chunky;
tagstruct.Software='MATLAB';
t_red.setTag(tagstruct); t_green.setTag(tagstruct); 

t_red.write(data_red); t_red.close();
t_green.write(data_green); t_green.close();
[m,n]=size(green_raw_sum);



%--------------------------------------------------------------------------
% Optimizing threshold for each color channel
%--------------------------------------------------------------------------
% red
%--------------------------------------------------------------------------
figure1=figure(1); clf;
imagesc(red_raw_sum/max(max(single(red_raw_sum)))); 
axis equal;
imcontrast;
h_red=imfreehand;
red_binary=createMask(h_red);
[B_red,L_red]=bwboundaries(red_binary);
boundary_size_red=[];
for k=1:length(B_red)
    temp=B_red{k,1};
    boundary_size_red(k,1)=length(temp);
    clear temp
end
 [max_C_red,max_I_red]=max(boundary_size_red);
 boundary_largest_red=B_red{max_I_red};

 
s_red=regionprops(red_binary,'PixelIdxList');       
    
for k=1:length(s_red)
    temp=s_red(k,1).PixelIdxList;
    s_red_size(k,1)=length(temp);
    clear temp
end  
    [max_C2_red,max_I2_red]=max(s_red_size);
    index=s_red(max_I2_red,1).PixelIdxList;
    object_largest_red=zeros(m,n);
    object_largest_red(index)=1;
    object_largest_red=logical(object_largest_red);
 
 
% judgement=0;
% while judgement~=1
%     level_red=input('please input the threshold');
%     [level_red,bw_red,bw2_red,B_red,L_red,max_I_red,fig1_red,...
%         fig2_red,fig3_red,fig4_red,...
%         object_largest2_red]=PCD_diagnosis_contour(red_raw_sum,level_red);
%     judgement=input('Are you satisfied with the results? \n 1 for satisfied, 0 for unsatisfied');
% end
% 
%--------------------------------------------------------------------------
% green
%--------------------------------------------------------------------------
figure(1);clf;
imagesc(green_raw_sum/max(max(single(green_raw_sum)))); 
axis equal;
imcontrast
h_green=imfreehand;
green_binary=createMask(h_green);
[B_green,L_green]=bwboundaries(green_binary);
boundary_size_green=[];
for k=1:length(B_green)
    temp=B_green{k,1};
    boundary_size_green(k,1)=length(temp);
    clear temp
end
[max_C_green,max_I_green]=max(boundary_size_green);
boundary_largest_green=B_green{max_I_green};

s_green=regionprops(green_binary,'PixelIdxList');       
    
for k=1:length(s_green)
    temp=s_green(k,1).PixelIdxList;
    s_green_size(k,1)=length(temp);
    clear temp
end  
    [max_C2_green,max_I2_green]=max(s_green_size);
    index=s_green(max_I2_green,1).PixelIdxList;
    object_largest_green=zeros(m,n);
    object_largest_green(index)=1;
    object_largest_green=logical(object_largest_green);
 

    
    

% judgement=0;
% while judgement~=1
%     level_green=input('please input the threshold');
%     [level_green,bw_green,bw2_green,B_green,L_green,max_I_green,fig1_green,...
%         fig2_green,fig3_green,fig4_green,...
%         object_largest2_green]=PCD_diagnosis_contour(green_raw_sum,level_green);
%     judgement=input('Are you satisfied with the results? \n 1 for satisfied, 0 for unsatisfied');
% end
% 
%--------------------------------------------------------------------------
% display the identified contours
%--------------------------------------------------------------------------

figure(5),clf;
sum_integrate_normalize(:,:,1)=red_raw_sum/max(max(single(red_raw_sum)));
sum_integrate_normalize(:,:,2)=green_raw_sum/max(max(single(green_raw_sum)));
[a,b]=size(green_raw_sum);
sum_integrate_normalize(:,:,3)=zeros(a,b);
imagesc(sum_integrate_normalize);axis equal;
hold on
plot(boundary_largest_red(:,2),...
                boundary_largest_red(:,1),'r','LineWidth',2);
plot(boundary_largest_green(:,2),...
                boundary_largest_green(:,1),'g','LineWidth',2);
%--------------------------------------------------------------------------
% measurements
%--------------------------------------------------------------------------
% measure the size of the cell
%--------------------------------------------------------------------------
 cell_index=find(object_largest_green|object_largest_red);
[m,n]=size(object_largest_red);
 cell_contour=zeros(m,n);
 cell_contour(cell_index)=1;
 cell_contour=logical(cell_contour);
 scrsz = get(0,'ScreenSize');
 fig6=figure(6);
 imshow(cell_contour)
 cell_area=length(cell_index);
 truesize(fig6,[scrsz(3)/4,scrsz(4)/4])
%--------------------------------------------------------------------------
% measure the paramter of the cell
%--------------------------------------------------------------------------
 cell_contour=imfill(cell_contour,'holes');    
 temp=regionprops(cell_contour, 'Perimeter');    
 cell_perimeter=temp.Perimeter;
 %--------------------------------------------------------------------------
 % measure the intensity of the green signal in the whole cell
 %--------------------------------------------------------------------------
 green_index=find(object_largest_green);
 green_integrated_intensity=sum(green_raw_sum(green_index));
 green_area=length(green_index);
%--------------------------------------------------------------------------
% measure the intensity of the red signal
%--------------------------------------------------------------------------
 red_index=find(object_largest_red);
 red_integrated_intensity=sum(red_raw_sum(red_index));
 red_area=length(red_index);
 %--------------------------------------------------------------------------
 % measure the intensity of the green signal in the entire cilia region
 %--------------------------------------------------------------------------
 green_integrated_intensity_cilia=sum(green_raw_sum(red_index));
 %--------------------------------------------------------------------------
 % measure the colocalization/pixel overlap between the red and green signal
 %--------------------------------------------------------------------------
 red_green_overlap_index=find(object_largest_red&object_largest_green);
 red_green_overlap_area=length(red_green_overlap_index);
 overlap_red_integrated_intensity=sum(red_raw_sum(red_green_overlap_index));
 overlap_green_integrated_intensity=sum(green_raw_sum(red_green_overlap_index));
% overlap area % red signal area
 OverlapAreaDividedByRed=red_green_overlap_area/red_area;
% overlap red integrated intensity/red integrated intensity
 RedOverlapIntensityRatio=overlap_red_integrated_intensity/red_integrated_intensity;
% overlap green integrated intensity/green integrated intensity
 GreenOverlapIntensityRatio=overlap_green_integrated_intensity/green_integrated_intensity;
%--------------------------------------------------------------------------
% data saving
%--------------------------------------------------------------------------

data.cell_area=cell_area;
data.cell_perimeter=cell_perimeter;
data.DNAH11_integratedintensity=green_integrated_intensity;
data.tubulin_integratedintensity=red_integrated_intensity;
data.DNAH11_cilia_integratedintensity=green_integrated_intensity_cilia;
data.colocalization_RedOverlapArea=OverlapAreaDividedByRed;
data.colocalization_RedOverlapIntIntensityRatio=RedOverlapIntensityRatio;
data.colocalization_GreenOverlapIntIntensityRatio=GreenOverlapIntensityRatio;
%data.threshold=[level_red,level_green];
saveas(figure(5),[FileName(1:end-9) '_optimizedcontour.fig'],'fig');
save([FileName(1:end-9) '_PCD_diagnosis_requireddata.mat'],'data');










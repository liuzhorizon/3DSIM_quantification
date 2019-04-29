%--------------------------------------------------------------------------
% All_vector_length_boxplot
%--------------------------------------------------------------------------
% notice: after you finish 'allvectorlength_beforerefine', copy the
%         generated the data into one folder and name it properly 
%--------------------------------------------------------------------------
clear;close all;clc;
folder_name=uigetdir('Please select the folder that contains all the .mat file generated by allvectorlength_beforerefine');
cd(folder_name);
files = dir([folder_name '\*.mat']);
samples_name=[];
DATA=[];
Length=[];
for i=1:length(files)
    name=files(i).name;
    data=importdata(files(i).name);
    len=length(data);
    Length=[Length;len];
    label=i*ones(len,1);
    samples_name{i,1}=name(1:12);
    data=[data,label];
    DATA=[DATA;data];
end
 




All_value=NaN(max(Length),length(files)); 
All_label=NaN(max(Length),length(files));
for i=1:length(files)
    index=find(DATA(:,5)==i);
    All_value(1:length(index),i)=DATA(index,4);
    All_label(1:length(index),i)=DATA(index,2);  
end

 figure
 
 plotSpread(All_value,'categoryIdx',All_label,...
                 'categoryMarkers',{'+','o'},'categoryColors',{[0.85 0.7 1],[0.68 0.92 1]})
 ylabel('Aligned vector Distribution');
 hold on 
 %Index=find(All_label==0);
 %All_value_aligned=All_value;
 %All_value_aligned(Index)=NaN;
 boxplot(All_value,'widths',0.8);
 box off;
 set(gca,'XTick',1:6)
 set(gca,'XTickLabel',{'WT','DNAH5','DNAH11','HYDIN','Cystic Fibrosis','CCDC39'})
% vectorlength_aligned=vectorlength;
% index=find(judge==0);
% vectorlength_aligned(index)=NaN;
 
 
%  csvwrite('vectorlength.csv',DATA(DATA(:,2)==1,4));
%  csvwrite('label.csv',DATA(DATA(:,2)==1,5));
 
 
%  boxplot(DATA(DATA(:,2)==1,4),DATA(DATA(:,2)==1,5));
%  hold on
 
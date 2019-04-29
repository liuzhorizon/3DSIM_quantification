clear;close all;clc;
folder_name=uigetdir('Please select the folder that contains all the .mat file generated by ALI_basalbody_analysis_Main');
cd(folder_name);
files = dir([folder_name '\*_main_information.mat']);
if isempty(files)
    display('no files identified under the current folder')
end
all=[];
for i=1:length(files)
    data=importdata(files(i).name);
    p_value=data.p_value;
    all_directions=data.all_directions;
    if ~isempty(p_value);
        vector_len=circ_r(all_directions);
%         if p_value<0.05
%             k=1;
%         else
%             k=0;
%         end    
       
            if p_value>0.05
                 k=0;
            elseif p_value<=0.05 && p_value>0.01
                 k=1;
            elseif p_value<=0.01  && p_value>0.001
                 k=2;
            elseif p_value<=0.001 && p_value>0.0001
                 k=3;
            else
                 k=4;
            end
        all=[all;i,k,p_value,vector_len]; 
    end    
    
end
% the structure of all
% column 1: the index of the cell
% column 2: whether it is significantly aligned or not, 1 stands for aligned, 0 tands
% for not aligned
% column 3: p_value
% column 4: vector_len_afterrefine
alignedcell_number=length(find(all(:,2)==1));
allcell_number=length(all);
alignedpercentage=alignedcell_number/allcell_number;
display(alignedpercentage);
 


  



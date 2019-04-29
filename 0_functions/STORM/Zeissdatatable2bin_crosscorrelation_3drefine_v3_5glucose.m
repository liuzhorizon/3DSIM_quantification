% zeiss data table to bin + cross correlation 
% zeiss datatable to bin file
clear;close all;clc;

[FileName,PathName] = uigetfile('*.txt','select the zeiss data table');
cd(PathName);
DATA=importdata(FileName);
vars = fieldnames(DATA);
for i = 1:length(vars)
    assignin('base', vars{i}, DATA.(vars{i}));
end
% erase the NaN rows
data(data(:,5)==NaN|data(:,6)==NaN|data(:,7)==NaN)=[];
d=median(data(:,7)); % Noate that the d may be uncorrect
%d=1000;
data(:,7)=data(:,7)-mean(data(:,7));
figure;
hist(data(:,7),50);
zrange=find(data(:,7)>1000|data(:,7)<-1000);
data(zrange,:)=[];

pixelsize=160; %nm
coords(:,1:2)=data(:,5:6)/pixelsize;
coords(:,3)=data(:,2);
[coordscorr, finaldrift, A,b] = RCC(coords, 3000, 128, pixelsize, 30,0.2);


coords_xz(:,1)=data(:,5)/pixelsize;
coords_xz(:,2)=data(:,7)/pixelsize;
coords_xz(:,3)=data(:,2);
[coordscorr_xz, finaldrift_xz, A_xz,b_xz] = RCC(coords_xz, 3000, 128, pixelsize, 30,0.2);

coords_yz(:,1)=data(:,6)/pixelsize;
coords_yz(:,2)=data(:,7)/pixelsize;
coords_yz(:,3)=data(:,2);
[coordscorr_yz, finaldrift_yz, A_yz,b_yz] = RCC(coords_yz, 3000, 128, pixelsize, 30,0.2);


display('auto correlation finished')


figure;
scatter(finaldrift(1:500:end,1)*pixelsize,finaldrift(1:500:end,2)*pixelsize,20,(1:500:length(finaldrift))','o','filled')
%hold on
%plot(finaldrift(1:500:end,1),finaldrift(1:500:end,2),'k-')
xlabel('drift in x(nm)')
ylabel('drift in y(nm)')
title('drift corretion xy by cross correlation')

colorbar
figure
scatter(finaldrift_xz(1:500:end,1)*pixelsize,finaldrift_xz(1:500:end,2)*pixelsize,20,(1:500:length(finaldrift_xz))','o','filled')
%hold on
%plot(finaldrift(1:500:end,1),finaldrift(1:500:end,2),'k-')
xlabel('drift in x(nm)')
ylabel('drift in z(nm)')
title('drift corretion xz by cross correlation')
colorbar

figure
scatter(finaldrift_yz(1:500:end,1)*pixelsize,finaldrift_yz(1:500:end,2)*pixelsize,20,(1:500:length(finaldrift_yz))','o','filled')
%hold on
%plot(finaldrift(1:500:end,1),finaldrift(1:500:end,2),'k-')
xlabel('drift in y(nm)')
ylabel('drift in z(nm)')
title('drift corretion yz by cross correlation')
colorbar

% assign the molecule list
z=0.5*(coordscorr_xz(:,2)+coordscorr_yz(:,2))*pixelsize;   % calibration the error brought by index mismatch
z_sphericalabberationcorrected=zeros(length(z),1);
% Note that the focal shift I use the 0.79 for 10% glucose
% The spherical aberration I still use the parameter for 5% glucose

for i=1:length(z)

if z(i,1)<0
     if d<1600
        z_sphericalabberationcorrected(i,1)=z(i,1)*0.72*0.9;
     elseif d>=1600&&d<2300
        z_sphericalabberationcorrected(i,1)=z(i,1)*0.72*0.95;
     else 
        z_sphericalabberationcorrected(i,1)=z(i,1)*0.72*1;
     end 
else
        z_sphericalabberationcorrected(i,1)=z(i,1)*0.72*(1+0.7*d/1000); 
end
end





moleculelist.x=single(coordscorr(:,1));   % pixel
moleculelist.xc=single(coordscorr(:,1));
moleculelist.y=single(coordscorr(:,2));
moleculelist.yc=single(coordscorr(:,2));
moleculelist.z=single(z_sphericalabberationcorrected);
moleculelist.zc=single(z_sphericalabberationcorrected);
moleculelist.h=single(1000*ones(length(data),1));
%moleculelist.a=single(10000*ones(length(data),1));
moleculelist.a=single(data(:,10));
moleculelist.w=single(300*ones(length(data),1));
moleculelist.phi=single(300*ones(length(data),1));
moleculelist.ax=single(300*ones(length(data),1));
moleculelist.bg=single(data(:,11));
moleculelist.i=single(1000*ones(length(data),1));
moleculelist.c=int32(ones(length(data),1));
moleculelist.density=int32(ones(length(data),1));
moleculelist.frame=int32(data(:,2));
moleculelist.length=int32(data(:,3));
moleculelist.link=int32(300*ones(length(data),1));
% write molecule list
WriteMoleculeList(moleculelist,[FileName(1:end-4) '_zrange_crosscorr.bin'])
display('finished')
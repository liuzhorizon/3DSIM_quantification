%--------------------------------------------------------------------------
% Imagerender_3DSTORM.
%-------------------------------------------------------------------------
% The script is used to render a 3D-STORM image
%-------------------------------------------------------------------------
% Input
%--------------------------------------------------------------------------
%      bin file generated by Insight3 or DAO-STORM
%--------------------------------------------------------------------------
% Output
%--------------------------------------------------------------------------
%  1. 2D color coded high resolution image
%  2. tiff stack with each frame representing a z step, opened with ImageJ
%  3. tiff stack same as 2 while each frame is a RGB image, opened withh
%     Image J hyperstack
%--------------------------------------------------------------------------
% Zhen Liu
% liuzhorizon@gmail.com
% Sickkids Toronto
% Jan 11,2018
%--------------------------------------------------------------------------
% Default inputs:
%--------------------------------------------------------------------------
  clear;close all;clc;
  pixelsize=160; % orignial pixel size
  binsize=10; % rendered pixel size in xy, unit nm
  zrange=[-500,500]; % lower and highest z position
  zsteps=10;  % unit nm 
  Zsteps=(zrange(2)-zrange(1))/zsteps+1;
%--------------------------------------------------------------------------  
% Select the bin file intended for rendering
%--------------------------------------------------------------------------
  [file, path]=uigetfile('*.bin','Select the bin file you want to render');
  cd(path);
  moleculelist=ReadMasterMoleculeList(file);
%--------------------------------------------------------------------------
% Bin to HxWxN
%--------------------------------------------------------------------------
  zoom=pixelsize/binsize;
  display('bin to HxWxN ing');
  [In, imaxes] = list2img_large(moleculelist,'scalebar',0,'zoom',zoom,'Zsteps',Zsteps,'Zrange',zrange);
  display('bin to HxWxN finished');
  % The function is written by Alistair Boettiger, Harvard University; 
  % I change the fspecial gaussian from 250 to 25 to accelarate the process
 %-------------------------------------------------------------------------
 % HxWxN to HxWx3
 %-------------------------------------------------------------------------
  display('HxWxN to HxWx3 ing');
  [Io,Io4d]=Ncolor_zhen(In{1,1}); 
  display('HxWxN to HxWx3 finished');
  figure;
  imagesc(autocontrast(Io));
  axis equal
 %------------------------------------------------------------------------
 % Save all the files
 %------------------------------------------------------------------------
   options.append = true;
   options.color = true;
   options.big=true;
   options2.append = true;
   options2.color = false;
   options2.big=true;
   for i=1:Zsteps
       saveastiff(Io4d(:,:,:,i), [file(1:end-4) '_10nmbin_rgb.tif'], options);
       saveastiff(In{1,1}(:,:,i),[file(1:end-4) '_10nmbin_.tif'],options2);
   end   
   imwrite(Io, [file(1:end-4) '_zstep' num2str(zsteps) '_binsize' num2str(binsize) '_zrange' num2str(zrange(1)) '-' num2str(zrange(2)) '_zproj_rgb.tif'], 'WriteMode', 'overwrite', 'Compression','none');
   display('all finished!')
   display('please check with ImageJ')
   clear;

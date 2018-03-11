% tiff_f32_to_uint8
%
% 26 Aug 2009: Gerry wrote it
%
% This script will read in 32-bit float tiff images and output unsigned
% 8-bit tiff images. Assumes only 1 channel.
%
% First time setup: put this script and tiffread27.m in a directory of your
% choosing and add that directory to Matlab's path (File --> Set Path -->
% Add Folder .. --> Select Folder --> then click the 'Save' button and
% close.
%
% Notes:
% 1) input images need to have the same number of characters in each image
% name
% 2) input images need to be in a directory ALONE with no other files
% 3) currently can only output max 999 images and/or z-slices; just edit the
% sprintf statements if you want to increase this maximum
%
% Dependencies:
% 1) tiffread27
%

% input dialog: prompt to get directory for images
prompt = {'Full path to img directory','Imaris (0) or Vias (1)?'};
default = {'','1'};
title = 'Convert 32-bit float tiff to unsigned 8-bit tiff';
Lines = 1;
answer = inputdlg(prompt,title,Lines,default);

% go to the image directory
[rootDir,ImOrVias] = deal(answer{:});
ImOrVias = str2double(ImOrVias);

cd(rootDir);

% get list of image names
imgList = ls;
imgList = imgList(3:end,:); % ignore those dots at the beginning

% extract channels, number of images; assume this is constant for all images
% FirstImg = tiffread27(imgList(1,:));
% NumChannels = size(FirstImg(1,1).data,2);
NumChannels = 1;
NumImages = size(imgList,1);

for k=1:NumImages
    CurrentImgInfo = tiffread27(imgList(k,:)); % use tiffread to get stack info
    
    % extract image dimensions here (b/c not all images have same dimensions
    Height = size(CurrentImgInfo(1,1).data,1);
    Width = size(CurrentImgInfo(1,1).data,2);
    Depth = size(CurrentImgInfo,2);
    eval(['Img' num2str(k) '= zeros(Height,Width,Depth,NumChannels);']);
    
    for i=1:NumChannels % extract individual channels, data{1,1} is channel 1
        for j=1:Depth % extract z-slices, blah(1,1) is top-most slice
%             eval(['Img' num2str(k) '(:,:,j,i) = CurrentImg(1,j).data{1,i};']);
            eval(['Img' num2str(k) '(:,:,j,i) = imread(imgList(k,:),j);']);
        end
    end
    fprintf(1,'.');
    
    % now save the image
    eval(['mkdir(''Img' num2str(k) ''');'])
    eval(['cd(''Img' num2str(k) ''');'])
    for i=1:NumChannels
        for j=1:Depth
            if ImOrVias % output to a format Vias can read into a stack
                Zee = sprintf('%04d',j);
                Cee = sprintf('%02d',i);
                Num = [Cee Zee];
                eval(['imwrite(uint8(Img' num2str(k) '(:,:,j,i)),[imgList(k,:) Num ''.tif''],''Compression'',''none'');']);
            else % or output to a format Imaris likes for a stack
                Zee = sprintf('%03d',j);
                Cee = sprintf('%03d',i);
                eval(['imwrite(uint8(Img' num2str(k) '(:,:,j,i)),[imgList(k,:) ''_z'' Zee ''_c'' Cee ''.tif''],''Compression'',''none'');']);
            end
        end
    end
    cd ..    
    eval(['clear Img' num2str(k) ';']);
end

fprintf(1,'\nDone!\n');    
    
% NumImages = size(imgList,1);

% for j=1:NumImages
%     CurrentImg = zeros(Height,Width,Depth);
%     for i=1:Depth
%         CurrentImg = imread('',i);
%     end
% end
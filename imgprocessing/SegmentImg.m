% currently can only output max 999 images and/or z-slices; just edit the
% sprintf statements if you want to increase this maximum

% rootDir contains images numbered in sequence with same number of
% characters in each image name (i.e. image01 ... image10 -->not image1 ...
% image10)
rootDir = 'C:\Documents and Settings\Kurt\Desktop\gerry\test';
cd(rootDir);

% get list of image names
imgList = ls;
imgList = imgList(3:end,:); % ignore those dots at the beginning

% extract channels, number of images; assume this is constant for all images
FirstImg = tiffread27(imgList(1,:));
NumChannels = size(FirstImg(1,1).data,2);
NumImages = size(imgList,1);

for k=1:NumImages
    CurrentImg = tiffread27(imgList(k,:));
    
    % extract image dimensions here (b/c not all images have same dimensions
    Height = size(CurrentImg(1,1).data{1,1},1);
    Width = size(CurrentImg(1,1).data{1,1},2);
    Depth = size(CurrentImg,2);
    eval(['Img' num2str(k) '= zeros(Height,Width,Depth,NumChannels);']);
    
    for i=1:NumChannels % extract individual channels, data{1,1} is channel 1
        for j=1:Depth % extract z-slices, blah(1,1) is top-most slice
            eval(['Img' num2str(k) '(:,:,j,i) = CurrentImg(1,j).data{1,i};']);
        end
    end
    fprintf(1,'.');
% end

% Get the mask for image segmentation
% Default: DAPI channel, slice 2
% Mask array has Depth = NumChannels = 1
%%
% for k=1:NumImages
    answer = 0; % also see GetImgMask; helps you abort to fix errors and try again
    counter = 0;
    while(~answer)
        eval(['[Mask' num2str(k) ',answer,counter] = GetImgMask(Img' num2str(k) '(:,:,2,1),counter);']);
    end
% end

% Segment the image using the mask
% for k=1:NumImages
    eval(['SegmentedImg' num2str(k) '= zeros(size(Img' num2str(k) '));']);
    for i=1:NumChannels
        for j=1:Depth
            eval(['Temp = Img' num2str(k) '(:,:,j,i);']);
            eval(['Temp(~Mask' num2str(k) '(:,:,1,1)) = mean(Temp(:));']);
            eval(['SegmentedImg' num2str(k) '(:,:,j,i) = Temp;']);
        end
    end
% end

% now save the image in an organized manner such that Imaris can read it

% for k=1:NumImages
    eval(['mkdir(''Img' num2str(k) ''');'])
    eval(['cd(''Img' num2str(k) ''');'])
    for i=1:NumChannels
        for j=1:Depth
            Zee = sprintf('%03d',j);
            Cee = sprintf('%03d',i);

            eval(['imwrite(uint8(SegmentedImg' num2str(k) '(:,:,j,i)),[imgList(k,:) ''_z'' Zee ''_c'' Cee ''.tif''],''Compression'',''none'');']);

        end
    end
    eval(['imwrite(uint8(Mask' num2str(k) '),[imgList(k,:) ''_mask.tif''],''Compression'',''none'');']);    
    eval(['save(''Img' num2str(k) ''',''Img' num2str(k) ''');']); % save the img in a mat file in case you want to do later analyses
    cd ..    
    eval(['clear SegmentedImg' num2str(k) ' Img' num2str(k) ' Mask' num2str(k) ';']);
end

fprintf(1,'\nDone!\n');
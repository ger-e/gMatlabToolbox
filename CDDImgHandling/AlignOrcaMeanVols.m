function AlignOrcaMeanVols(rootdir,folderwildcard)
% function AlignOrcaMeanVols(rootdir,folderwildcard)
% 8/17/2017: Gerry wrote it
% This script will use simple xy translation to align mean images of a
% volume. It was written specifically for images acquired on the Orca flash
% with wide field microscopy, whereby tif images for the mean intensity of
% each slice was already exported. Point this script to a root directory
% containing named folders, one per image. The folder's name is always the
% 'stem' of any images inside the folder. We expect metadata in a specific
% *.mat file, and to be from ThorImage and HCImage. We expect the mean tif
% images to also have a specific name. In other words, this is a specific
% script, not a general-use script.
% 
% This script runs relatively quickly
%
% Dependencies: AlignmentTool toolbox from Rainer Friedrich's lab

folderlist = dir(fullfile(rootdir,[folderwildcard '*']));
XYBin = 4; % this should equal that used for ICA
Method='redxcorr2normimages';

% take the first image from the first folder as your reference
for a=1:length(folderlist)
    ImgDir = fullfile(rootdir,folderlist(a).name);
    ImgNameStem = folderlist(a).name;
    
    if a==1 % read in metadata
        % parse ThorImage metadata and extract useful information
        load(fullfile(ImgDir,[ImgNameStem '_allmetadata.mat']));
        ActualNumSlices = str2double(MetaData_Thor.ThorImageExperiment.ZStage.Attributes.steps);
        NumFlybackFrames = str2double(MetaData_Thor.ThorImageExperiment.Streaming.Attributes.flybackFrames);
        SlicesPerVol = ActualNumSlices + NumFlybackFrames;
        
        % parse HCImage metadata
        Height = double(MetaData_Orca(44)); Width = double(MetaData_Orca(42)); TotalFrames = double(MetaData_Orca(39));
%         NumVolumes = TotalFrames/SlicesPerVol;
        
        refImages = zeros(Height/XYBin,Width/XYBin,SlicesPerVol);
        for aa=1:SlicesPerVol
            temp = double(imread(fullfile(ImgDir,[ImgNameStem '_meanstack_z' num2str(aa) '.tif'])));
            refImages(:,:,aa) = BinImg2D(temp,XYBin,XYBin);
        end
        
        % specify alignment maxoffset parameter
        MaxOffset = [size(refImages,1) size(refImages,2) size(refImages,1) size(refImages,2)];
        
        % initialize max displacements storage (of the alignment)
        MaxLeft = zeros(SlicesPerVol,1); MaxRight = zeros(SlicesPerVol,1); 
        MaxUp = zeros(SlicesPerVol,1); MaxDown = zeros(SlicesPerVol,1);
    end
    
    % now align each slice to reference slice (from first image)
    dY = zeros(SlicesPerVol,1); dX = zeros(SlicesPerVol,1);
    iOverlapX = zeros(SlicesPerVol,2); iOverlapY = zeros(SlicesPerVol,2);
    jOverlapX = zeros(SlicesPerVol,2); jOverlapY = zeros(SlicesPerVol,2);
    FixedImgs = zeros(size(refImages));
    fh=figure; set(fh,'Name',ImgNameStem);
    for b=1:SlicesPerVol
        unalignedFrame = double(imread(fullfile(ImgDir,[ImgNameStem '_meanstack_z' num2str(b) '.tif'])));
        unalignedFrame = BinImg2D(unalignedFrame,XYBin,XYBin);
        refImage = refImages(:,:,b);
        
        % now compute alignment
        [dY(b),dX(b),~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
        [iOverlapX(b,:),iOverlapY(b,:),~,jOverlapX(b,:),jOverlapY(b,:)]=fcn_get_overlap(1,1,0,size(refImage,2),size(refImage,1),0,dX(b)+1,dY(b)+1,0,size(refImage,2),size(refImage,1),0);
        
        % now apply alignment for visual inspection
        FixedImgs(iOverlapY(b,1):iOverlapY(b,2),iOverlapX(b,1):iOverlapX(b,2),b) = ... % shift image
            unalignedFrame(jOverlapY(b,1):jOverlapY(b,2),jOverlapX(b,1):jOverlapX(b,2));
        
        % show the alignment result: refImage in red, aligned image in green
        subplot_tight(1,SlicesPerVol,b);
        FixedImg = FixedImgs(:,:,b);
        RGBImg = zeros(256,256,3,'uint8');
        RGBImg(:,:,1) = uint8(refImage./max(refImage(:)).*255);
        RGBImg(:,:,2) = uint8(FixedImg./max(FixedImg(:)).*255);
        imshow(RGBImg);
        
        % get max displacements for later cropping
        MaxLeft(b) = max([MaxLeft(b) dX(b)]);
        MaxRight(b) = min([MaxRight(b) dX(b)]);
        MaxUp(b) = max([MaxUp(b) dY(b)]);
        MaxDown(b) = min([MaxDown(b) dY(b)]);
        
        % now export the aligned image (optional)
%         imwrite(uint16(FixedImg),fullfile(ImgDir,[ImgNameStem '_meanstack_z' num2str(b) '_GJSregistered.tif']),'tiff');
    end
    
    % now export the registration parameters
    save(fullfile(ImgDir,[ImgNameStem '_meanstack_GJSRegParams.mat']),'dY','dX','iOverlapX','iOverlapY','jOverlapX','jOverlapY','FixedImgs','refImages');
end

% append the max displacements to each data file
for a=1:length(folderlist)
    ImgDir = fullfile(rootdir,folderlist(a).name);
    ImgNameStem = folderlist(a).name;
    MaxRight = abs(MaxRight); MaxDown = abs(MaxDown);
    save(fullfile(ImgDir,[ImgNameStem '_meanstack_GJSRegParams.mat']),'-append','MaxLeft','MaxRight','MaxUp','MaxDown');
end
end
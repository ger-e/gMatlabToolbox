function alignimgs2(FixedImgName,Directory,refFrameIdx,method,MaxOffset)
% function alignimgs2(FixedImgName,Directory,refFrameIdx,method,MaxOffset)
% 12/17/2014: Gerry wrote it, then made a modified version to allow
% operation on arbitrarily large datafiles. This means that the aligned
% image will not be returned; rather exported to a tif stack
%
% This script will take in an x by y by t image and align each frame (along
% t) to some reference frame, using only rigid-body transformations.
%
% 1) FixedImg: matrix containing your image, likely processed by
% adjstartdelay_interlacing2.m to fix interlacing issues due to scan mirror
% 2) refFrameIdx: index to the frame in FixedImg that you wish to align to
% (currently I have not built in the ability to align across images from
% different acquisitions)
% 3) method: =1, fast, compute correlation; =2, slow, demon registration
% 4) MaxOffset: (applies to method 1 only, pass [] otherwise) default = 10;
% number of pixels neighborhood to allow searching for alignment. The
% higher the slower the algorithm
cd(Directory);
NumSlices = length(imfinfo(FixedImgName));

% read the ref slice
refImage = imread(FixedImgName,'Index',refFrameIdx);
refImage = single(refImage); % convert from uint16

for a=1:NumSlices
    % read a slice
    FixedImg = imread(FixedImgName,'Index',a);
    FixedImg = single(FixedImg); % convert from uint16

if method==2
    %--------------------------------------------------------------------------
    % demon_registration script: slooooooooooow
    % you may get some speedup using parfor
    Options.Registration = 'Rigid'; % force rigid transformations only
    Options.Similarity = 'p'; % force same modality

    % now do the alignment
    FixedImgAligned2 = register_images(FixedImg,refImage,Options);
    success = 0;
    while ~success
        try
            imwrite(uint16(FixedImgAligned2),[FixedImgName(1:end-4) '_aligned.tif'],'Compression','none','WriteMode','append');
            success = 1;
        catch
            fprintf(1,'\nWrite error, retrying...');
            pause(0.1);
        end
    end    
else
    %--------------------------------------------------------------------------
    % Rainer Friedrich lab script: fast
    Method='redxcorr2normimages'; %alignment method
    if isempty(MaxOffset) % set default max offset if not specified
        MaxOffset=10; % max movement allowed, in pixels
    end

    Height=size(FixedImg,1);
    Width=size(FixedImg,2);
    FixedImgAligned = zeros(size(FixedImg)); % need to initialize this for later use
    
    % now do the alignment
    unalignedFrame = FixedImg;
    [dY,dX,~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
    disp(['Inter-trial alignment: ' 'Frame ' num2str(a) filesep num2str(size(FixedImg,3)) '. XOffset: ' num2str(dX) ', YOffset: ' ...
    num2str(dY) ', Cmax: ' num2str(cmax)]);

    [iOverlapX,iOverlapY,~,jOverlapX,jOverlapY]=...
    fcn_get_overlap(...
    1,1,0,Width,Height,0,dX+1,dY+1,0,Width,Height,0);

    % shift image
    FixedImgAligned(iOverlapY(1):iOverlapY(2),iOverlapX(1):iOverlapX(2)) = FixedImg(jOverlapY(1):jOverlapY(2),jOverlapX(1):jOverlapX(2));
    
    success = 0;
    while ~success
        try
            imwrite(uint16(FixedImgAligned),[FixedImgName(1:end-4) '_aligned.tif'],'Compression','none','WriteMode','append');
            success = 1;
        catch
            fprintf(1,'\nWrite error, retrying...');
            pause(0.1);
        end
    end
end
end
end
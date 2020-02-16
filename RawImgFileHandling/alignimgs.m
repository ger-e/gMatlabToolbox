function FixedImgAligned = alignimgs(FixedImg,refFrameIdx,method,MaxOffset)
% function FixedImgAligned = alignimgs(FixedImg,refFrameIdx,method,MaxOffset)
% 12/17/2014: Gerry wrote it
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

if method==2
    %--------------------------------------------------------------------------
    % demon_registration script: slooooooooooow
    % you may get some speedup using parfor
    refImage = FixedImg(:,:,refFrameIdx); % specify frame to align to
    Options.Registration = 'Rigid'; % force rigid transformations only
    Options.Similarity = 'p'; % force same modality

    FixedImgAligned2 = zeros(size(FixedImg));

    % now do the alignment
    for a=1:size(FixedImg,3)
        FixedImgAligned2(:,:,a) = register_images(FixedImg(:,:,a),refImage,Options);
    end

else
    %--------------------------------------------------------------------------
    % Rainer Friedrich lab script: fast
    Method='redxcorr2normimages'; %alignment method
    refImage = FixedImg(:,:,refFrameIdx); % specify frame to align to
    if isempty(MaxOffset) % set default max offset if not specified
        MaxOffset=10; % max movement allowed, in pixels
    end

    Height=size(FixedImg,1);
    Width=size(FixedImg,2);
    FixedImgAligned = zeros(size(FixedImg));

    % now do the alignment
    for a=1:size(FixedImg,3)
        unalignedFrame = FixedImg(:,:,a);
        [dY,dX,~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
        disp(['Inter-trial alignment: ' 'Frame ' num2str(a) filesep num2str(size(FixedImg,3)) '. XOffset: ' num2str(dX) ', YOffset: ' ...
        num2str(dY) ', Cmax: ' num2str(cmax)]);

        [iOverlapX,iOverlapY,~,jOverlapX,jOverlapY]=...
        fcn_get_overlap(...
        1,1,0,Width,Height,0,dX+1,dY+1,0,Width,Height,0);

        % shift image
        FixedImgAligned(iOverlapY(1):iOverlapY(2),iOverlapX(1):iOverlapX(2),a) = FixedImg(jOverlapY(1):jOverlapY(2),jOverlapX(1):jOverlapX(2),a);
    end
end
end
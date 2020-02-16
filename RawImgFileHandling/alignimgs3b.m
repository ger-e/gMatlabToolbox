function [dX, dY] = alignimgs3b(FixedImgName,Directory,tempdir,refFrameIdx,MaxOffset,Verbose)
% function [dX, dY] = alignimgs3b(FixedImgName,Directory,tempdir,refFrameIdx,MaxOffset,Verbose)
% 12/17/2014: Gerry wrote it, then made a modified version to allow
% operation on arbitrarily large datafiles. This means that the aligned
% image will not be returned; rather exported to a tif stack
% 12/18/2014: modified again to improve file handling speed. Removed demon
% registration method option. Script now utilizes parfor and MIJI
% (FIJI/Matlab implementation) for massive speed up of computations and
% file handling, respectively. Note as currently written, we can only
% handle 99999 frames per stack (filenaming)
% 12/23/2014: Gerry modified (3b version) to allow reading >4GB tif files
% as outputted by ImageJ (these are actually raw files)
%
% This script will take in an x by y by t image and align each frame (along
% t) to some reference frame, using only rigid-body transformations.
%
% 1) FixedImg: matrix containing your image, likely processed by
% adjstartdelay_interlacing2.m to fix interlacing issues due to scan mirror
% 2) Directory: full path to your input stack
% 3) tempdir: required name of temporary directory for saving tif series
% intermediates
% 4) refFrameIdx: index to the frame in FixedImg that you wish to align to
% (currently I have not built in the ability to align across images from
% different acquisitions)
% 5) MaxOffset: (applies to method 1 only, pass [] otherwise) default = 10;
% number of pixels neighborhood to allow searching for alignment. The
% higher the slower the algorithm
% 6) Verbose: pass 0 if you don't want to see progress

mkdir(fullfile(Directory,tempdir)); % make temp directory

% get number of slices from ImageJ header
temp = imfinfo(fullfile(Directory,FixedImgName));
temp2 = strfind(temp.ImageDescription,'s=');
NumSlices = str2double(temp.ImageDescription(temp2(1)+2:temp2(2)-6));

if isempty(MaxOffset) % set default max offset if not specified
    MaxOffset=10; % max movement allowed, in pixels
end
Method='redxcorr2normimages'; %alignment method

% read the ref slice
% refImage = imread(fullfile(Directory,FixedImgName),'Index',refFrameIdx);
refImage = ReadRawIJSlice(fullfile(Directory,FixedImgName),refFrameIdx);
refImage = single(refImage); % convert from uint16

% get basic img parameters
Height=size(refImage,1);
Width=size(refImage,2);

% initialize storage
dY = zeros(NumSlices,1);
dX = zeros(NumSlices,1);
iOverlapX = zeros(NumSlices,2);
iOverlapY = zeros(NumSlices,2);
jOverlapX = zeros(NumSlices,2);
jOverlapY = zeros(NumSlices,2);

% first get offsets
parfor a=1:NumSlices
    % read a slice
%     FixedImg = imread(fullfile(Directory,FixedImgName),'Index',a);
    FixedImg = ReadRawIJSlice(fullfile(Directory,FixedImgName),a);
    FixedImg = single(FixedImg); % convert from uint16

    %--------------------------------------------------------------------------
    % Rainer Friedrich lab script: fast
    unalignedFrame = FixedImg;
    [dY(a),dX(a),~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
    if Verbose
        disp(['Inter-trial alignment: ' 'Frame ' num2str(a) filesep num2str(size(FixedImg,3)) '. XOffset: ' num2str(dX(a)) ', YOffset: ' ...
        num2str(dY(a)) ', Cmax: ' num2str(cmax)]);
    end

    [iOverlapX(a,:),iOverlapY(a,:),~,jOverlapX(a,:),jOverlapY(a,:)]=...
    fcn_get_overlap(...
    1,1,0,Width,Height,0,dX(a)+1,dY(a)+1,0,Width,Height,0);
end

% figure out the max displacements to crop 0's out later
MaxLeft = max(dX(:));
MaxRight = abs(min(dX(:)));
MaxUp = max(dY(:));
MaxDown = abs(min(dY(:)));

% then apply the offsets
parfor b=1:NumSlices
    % read a slice
%     FixedImg = imread(fullfile(Directory,FixedImgName),'Index',b);
    FixedImg = ReadRawIJSlice(fullfile(Directory,FixedImgName),b);
    FixedImg = single(FixedImg); % convert from uint16

    % need to initialize this for later use
    FixedImgAligned = zeros(size(FixedImg)); 
    
    % shift image
    FixedImgAligned(iOverlapY(b,1):iOverlapY(b,2),iOverlapX(b,1):iOverlapX(b,2)) = FixedImg(jOverlapY(b,1):jOverlapY(b,2),jOverlapX(b,1):jOverlapX(b,2));
    
    % crop off zeros
    FixedImgAligned = FixedImgAligned(MaxUp+1:end-MaxDown,MaxLeft+1:end-MaxRight);
    
    success = 0;
    while ~success
        try
            imwrite(uint16(FixedImgAligned),fullfile(Directory,tempdir,[FixedImgName(1:end-4) '_aligned' '_t' num2str(b,'%05d') '.tif']),'Compression','none');
            success = 1;
        catch
            fprintf(1,'\nWrite error, retrying...');
            pause(0.1);
        end
    end
end

% then call MIJI to export to tiff stack, and clean up
FullTempDir = DuplicateChar(fullfile(Directory,tempdir),'\');
IJOutputDir = DuplicateChar(Directory,'\');

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

% now read virtual stack and then export tif stack
MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' FixedImgName(1:end-4) '_aligned_t00001.tif sort use']);
MIJ.run('Save',['path=[' IJOutputDir '\\' FixedImgName(1:end-4) '_aligned.tif]']);

% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');
end
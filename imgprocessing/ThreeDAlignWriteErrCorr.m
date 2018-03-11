% ThreeDAlignWriteErrCoor.m
% 10/1/2010: Gerry wrote it
% 10/6/2010: Updated for batch processing
% 7/31/2011: Kurt added timeout TIFF write pause from previous Gerry script
% 10/14/2011: Gerry added fix for accurately reading image names from
% subdir, note that you will have to specify your input filetype now!
%
% This script will align pairs of 3D, *single channel* image stacks using
% demon_registration_version_8f. It will output to a single tiff stack.
% This script can batch align images to a given target image of your
% choosing. By default, this script will assume that the images are of the
% same modality and will use only rigid transformations for alignment.
% Non-rigid/affine transformations are available by the demon_registration
% script, but initial testing of these proved them to be slow and not very
% effective.
%
% Note: the xyz dimensions can be different in your two images, but
% empirical testing showed that it's best to keep xy dimensions constant;
% varying Z dimension is OK; in theory, varying Z voxel sizes should be
% OK--the voxel size of the image you are aligning to will be the one you
% use for re-scaling the aligned image
% Options.Similatrity = "m" for different modality and "p" for the same
%
% **Source dir always needs to be named like 000_XXXX to put it at the top of
% the directory list when invoking dir()!!!**

% Things to edit-----------------------------------------------------------
ImgRootDir = 'J:\2011-10-13 registration for cell death\Aligned images\Redo';
DemonRegistrationLocation = '\\SONGMINGTHREE\Users\Kurt\Desktop\MatLab Programs\demon_registration_version_8f';
InputImgType = 'tif';

% image dimensions
XDim = 548;
YDim = 859;

%--------------------------------------------------------------------------

% get image directories
cd(ImgRootDir);
ImgDirs = dir(ImgRootDir);
ImgDirs = ImgDirs(3:end,1);

for d=2:length(ImgDirs)
    subdir1 = ImgDirs(d).name;
    SourceDir = ImgDirs(1).name; % This will always be the source!
    cd(subdir1); img1names = dir(['*.' InputImgType]); cd ..
    cd(SourceDir); img2names = dir(['*.' InputImgType]); cd ..

    img1 = zeros(YDim,XDim,length(img1names));
    img2 = zeros(YDim,XDim,length(img2names));

    for a=1:length(img1names)
        img1(:,:,a) = imread([subdir1 '\' img1names(a).name],'tiff');
    end

    for b=1:length(img2names)
        img2(:,:,b) = imread([SourceDir '\' img2names(b).name],'tiff');
    end    

    cd(DemonRegistrationLocation); % go to the script

    % do a rigid transformation registration
    Options.Registration = 'Rigid';
    Options.Similarity = 'p';
    Registered1on2 = register_volumes(img1,img2,Options);

    % now fix range and export
    fix = ones(size(Registered1on2)).*-min(Registered1on2(:));
    Fixed = Registered1on2 + fix;
    Registered1on2 = uint8(Fixed);

    cd(ImgRootDir); % save the files to the image root directory
    for c=1:size(Registered1on2,3)
        % note that we're explicitly assuming that the image has only ONE
        % channel
         success = 0;
        while ~success
            try
                imwrite(Registered1on2(:,:,c),['Registered_' subdir1 '_on_' SourceDir '_uint8.tiff'],'tif','Compression','none','Resolution',[96 96],'WriteMode','append');
                success = 1;
            catch
                fprintf(1,'\nWrite Error, waiting 1sec to try again');
                fprintf(1,'\nIt was: Img %i Z%i', a, b);
                pause(1);
            end
        end
    end
end
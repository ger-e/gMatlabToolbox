% ThreeDAlign.m
% 10/1/2010: Gerry wrote it
% 10/6/2010: Updated for batch processing
% 10/12/2010: Updated to read in tiff stacks, if needed
% 12/18/2010: Reads in only LSM, outputs tiff series (because tiff
% stack output is too buggy; also modified how images are being read in
% (i.e. more sophisticated use of 'dir')
% 01/07/2011: Set up for dumb batch processing
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
%
% Dependencies: demon_registration_version_8f, image processing toolbox,
% tiffread29, LSMto4DMatrix
%
% Notes
% 1) Make sure your LSM files have no compression!
% 2) The very first image in your image directory (i.e. ABC order) will be
% the one that all other images are aligned to

% Things to edit-----------------------------------------------------------
% ImgRootDir = 'C:\Users\Gerry\Desktop\daria'; % directory where only your images to be aligned reside
% DemonRegistrationLocation = 'C:\Users\Kurt\Desktop\demon_registration_version_8f';

% are your inputs a tiff series or a tiff stack?
% InputType = 1; % 0 for tiff series, 1 for tiff stack

% image dimensions
% XDim = 1024;
% YDim = 1024;

%--------------------------------------------------------------------------

ImgRootDir = {'D:\Daria\20110107_alignments\rat126\stack1' ...
    'D:\Daria\20110107_alignments\rat126\stack2' ...
    'D:\Daria\20110107_alignments\rat126\stack3' ...
    'D:\Daria\20110107_alignments\rat127\stack1' ...
    'D:\Daria\20110107_alignments\rat127\stack2' ...
    'D:\Daria\20110107_alignments\rat127\stack3' ...
    'D:\Daria\20110107_alignments\rat128\stack1' ...
    'D:\Daria\20110107_alignments\rat128\stack2'};

for f=1:length(ImgRootDir)
    % get image directories
    cd(ImgRootDir{f});
    ImgDirs = dir([ImgRootDir{f} '\*.lsm']);
    % ImgDirs = ImgDirs(3:end,1);

    for d=2:length(ImgDirs)
    %     subdir1 = ImgDirs(d).name;
    %     SourceDir = ImgDirs(1).name; % This will always be the source!
    %     img1names = dir(subdir1);
    %     img2names = dir(SourceDir);

    %     img1names = img1names(3:end,1); % may need end-1 if dir shows Thumbs.db
    %     img2names = img2names(3:end,1);

        % load images either as a stack or as series
    %     if InputType % load as stack
            img1 = LSMto4DMatrix(ImgDirs(d).name);
            img2 = LSMto4DMatrix(ImgDirs(1).name);
    %     else % load as series
    %         img1 = zeros(YDim,XDim,length(img1names));
    %         img2 = zeros(YDim,XDim,length(img2names));

    %         for a=1:length(img1names)
    %             img1(:,:,a) = imread([subdir1 '\' img1names(a).name],'tiff');
    %         end

    %         for b=1:length(img2names)
    %             img2(:,:,b) = imread([SourceDir '\' img2names(b).name],'tiff');
    %         end    
    %     end

    %     cd(DemonRegistrationLocation); % go to the script

        for e=1:2 % try both single and multi modality
            % do a rigid transformation registration
            Options.Registration = 'Rigid';
            if e==1
                Options.Similarity = 'p';
            else
                Options.Similarity = 'm';
            end
            Registered1on2 = register_volumes(img1,img2,Options);

            % now fix range and export
            fix = ones(size(Registered1on2)).*-min(Registered1on2(:));
            Fixed = Registered1on2 + fix;
            Registered1on2 = uint8(Fixed);

%             cd(ImgRootDir{f}); % save the files to the image root directory
            for c=1:size(Registered1on2,3)
                % note that we're explicitly assuming that the image has only ONE
                % channel
                imwrite(Registered1on2(:,:,c),[Options.Similarity '_Registered_' ImgDirs(d).name '_on_' ImgDirs(1).name '_z' num2str(c) '_uint8.tiff'],'tif','Compression','none','Resolution',[96 96]); % ,'WriteMode','append');
            end
        end
    end
end
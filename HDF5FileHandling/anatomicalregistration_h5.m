function anatomicalregistration_h5(ImgName,Directory,AnatParam,flag)
% function anatomicalregistration_h5(ImgName,Directory,AnatParam,flag)
% 1/4/2016: Gerry wrote it
% 1/19/2016: Gerry modified to use '--auto-multi-levels 5' instead of
% '--exploration 50 --accuracy 1' as the additional parameters for
% registration. The auto mode seemed to yield better results than those of
% manual specification. It's still not perfect, but at least it's within
% 0.5-1 cell bodies (as opposed to 1-2 cell bodies previously)
% 2/5/2016: Gerry switched back to less accurate, but more robust x50 a1
% parameter for registration because of high failure rate with
% auto-multi-levels
% 8/26/2016: Gerry modified CMTK command to include '--match-histograms'
% flag for both affine and warp transformations. This allows ~feature
% normalization / rescaling and yields much improved robustness with
% registration. See CMTK documentation for details as to what this does.
% Also included a flag to control whether you want to export the AnatRef
% avg brain or not (0 for no, 1 for yes) in case you're re-running this
% step where the AnatRef avg brain has already been made (or edited, e.g.)
% This script will take your chunks of data (as broken up by
% getvoxelsignals_h5) and register them into a specified reference brain
% space. The avg vol of the chunk and the voxel centroids of the chunk are
% the only things being registered here. 
%
% Note: *significant* dependencies of this script: Windows, Cygwin, FIJI,
% MIJI, CMTK (compiled for Windows)
%
% Note: data are stored in a *.mat file at the end, due to the difficulty
% (or my laziness in figuring out...) how to store structures, logicals,
% and strings in HDF5
%
% Note: matlab loads a logical() dataset lazily. FullMaskDB will only take
% up its full form in memory after you query every value in it. This takes
% about 20-30GB of memory. This step occurs at the very end when you are
% registering centroids

fullpath = fullfile(Directory,ImgName); % just so we can save a bit of time in the loop

% Directory can't have a trailing backslash (b/c backslash is escape char for bash...)
if length(Directory) == 3 % e.g. C:\
    Directory = Directory(1:2);
end
tempdir = 'temp';
[~,ImgNameStem] = fileparts(ImgName);

% unpack AnatParam structure
XYZScale = AnatParam.XYZScale;
CMTKPath = AnatParam.CMTKPath;
RefBrainPath = AnatParam.RefBrainPath;
RefBrainName = AnatParam.RefBrainName;
BridgeBrainPath = AnatParam.BridgeBrainPath;
BridgeBrainName = AnatParam.BridgeBrainName;
BridgeBrainAffineList = AnatParam.BridgeBrainAffineList;
AngleXYZ = AnatParam.AngleXYZ;
RefBrainScale = AnatParam.RefBrainScale;
FullPathToRefBrainIDs = AnatParam.FullPathToRefBrainIDs;

% load in required metadata
AllVoxSigCentroid = h5read(fullpath,'/AllVoxSigCentroid');
AnatRefs = h5read(fullpath,'/AnatRefs');

% Prep images to be read in by CMTK----------------------------------------
% export in reverse order (such that the final slice is most superficial)
% and rotate 180deg to match proper orientation for CMTK
if flag
    mkdir(fullfile(Directory,tempdir)); % make temp directory
    for i=1:size(AnatRefs,4)
        for h=1:size(AnatRefs,3)
            success = 0;
            while ~success
                try
                    imwrite(imrotate(AnatRefs(:,:,h,i),180),fullfile(Directory, ...
                        tempdir,[ImgNameStem '-chunk-' num2str(i,'%02d') ...
                        '_slice_' num2str(size(AnatRefs,3)-(h-1),'%02d') '.tif']),'tiff');
                    success = 1; 
                catch
                    pause(0.1);
                end
            end
        end
    end

    % then call MIJI to export to nrrd stacks, specify voxel dimensions, and clean up
    FullTempDir = DuplicateChar(fullfile(Directory,tempdir),'\');
    mkdir(fullfile(Directory,'images')); % make directory for CMTK registration
    IJOutputDir = DuplicateChar(fullfile(Directory,'images'),'\');

    try % make sure MIJI is turned on
        MIJ.version;
    catch
        fprintf(1,'\nMIJI not turned on...turning on...\n');
        Miji(false);
    end

    for i=1:size(AnatRefs,4)
        % now read virtual stack
        MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' ImgNameStem '-chunk-' num2str(i,'%02d') '_slice_01.tif file=-chunk-' num2str(i,'%02d') ' sort use']);

        % set voxel dimensions
        MIJ.run('Properties...', ['channels=1 slices=' num2str(size(AnatRefs,3)) ' frames=1 unit=um pixel_width=' num2str(XYZScale(1)) ' pixel_height=' num2str(XYZScale(2)) ' voxel_depth=' num2str(XYZScale(3))]);

        % finally save to nrrd file for CMTK registration
        MIJ.run('Nrrd ... ',['nrrd=' IJOutputDir '\\' ImgNameStem '-chunk-' num2str(i,'%02d') '-avg.nrrd']);
    end

    % clean up tif series
    [success, message, msgID] = rmdir(fullfile(Directory,tempdir),'s');
    MIJ.closeAllWindows;
end
% Perform the registration via CMTK----------------------------------------
BridgeBrainNameStem = BridgeBrainName(1:find(BridgeBrainName=='_',1)-1); % CMTK will only take the string before the first underscore
RefBrainNameStem = RefBrainName(1:find(RefBrainName=='_',1)-1); % CMTK will only take the string before the first underscore
xx = load(FullPathToRefBrainIDs); % load the Z-brain atlas
FullMaskDB = full(xx.MaskDatabase); % convert to full matrix from sparse
FullMaskDB = reshape(FullMaskDB,[xx.height xx.width xx.Zs length(xx.MaskDatabaseNames)]); % reshape to volume
clear xx; % clear this to save memory
for i=1:size(AnatRefs,4)
    AvgVolName = [ImgNameStem '-chunk-' num2str(i,'%02d') '-avg.nrrd'];
    
    
    % Write shell script and execute in CMTK (cygwin) to perform registration to bridging registration
    ShScriptName = [AvgVolName(1:end-9) '_to_' BridgeBrainNameStem '.sh'];
    fID = fopen(fullfile(Directory,ShScriptName),'w'); % 'w' will discard existing contents of file
    fprintf(fID,'#!/bin/bash');
    fprintf(fID,'\n');
    rootdirEscaped = DuplicateChar(Directory,'\');
    fprintf(fID,['cd "' rootdirEscaped '"']); % change to root directory
    fprintf(fID,'\n');
    fprintf(fID,['"' CMTKPath 'munger" ' ... % run the registration
        '-b "' CMTKPath '" -a -r 01 -A ' ...
        '''--exploration 50 --accuracy 1 --match-histograms'' -T 48 -s "' BridgeBrainPath BridgeBrainName '" "images"']);
    fprintf(fID,'\n');
    fprintf(fID,['"' CMTKPath 'reformatx" -v ' ... % reformat the image
        '--pad-out 0 -o "' AvgVolName(1:end-9) '_to_' BridgeBrainNameStem '.nrrd" --floating "images/' AvgVolName '" "' ...
        '' BridgeBrainPath BridgeBrainName '" "Registration/affine/' BridgeBrainNameStem '_' AvgVolName(1:end-5) '_9dof.list"']);
    fclose(fID);

    % run the shell script
    str1 = fullfile(Directory,ShScriptName);
    str2 = WinToLinuxPath(str1,4,1); % convert to linux path with escape chars for parenthesis
    str2 = ['/cygdrive/' Directory(1) '/' str2];
    system(['C:\cygwin64\bin\bash --login -c "' str2 '"'])
    clear str1 str2;
    
    
    % Write/run txt doc and shell script to transform centroids into registered space
    CurrSigCentroid = AllVoxSigCentroid(:,:,:,i);
    CurrSigCentroid = permute(CurrSigCentroid,[1 3 2]);
    CurrSigCentroid = reshape(CurrSigCentroid,[size(CurrSigCentroid,1)*size(CurrSigCentroid,2) size(CurrSigCentroid,3)]);
    MyPoints = RotatePoints3D(CurrSigCentroid,XYZScale,AngleXYZ);

    % export to txt file for streamxform
    fID2 = fopen(fullfile(Directory,[AvgVolName(1:end-9) '_AllSigCentroids.txt']),'w');
    for a=1:size(MyPoints,1)
        fprintf(fID2,[num2str(MyPoints(a,1)) ' ' num2str(MyPoints(a,2)) ' ' num2str(MyPoints(a,3))]);
        fprintf(fID2,'\r\n'); % new line, windows style
    end
    fclose(fID2);

    % write the shell script
    ShScriptName = [AvgVolName(1:end-9) '_to_' RefBrainNameStem '.sh'];
    fID = fopen(fullfile(Directory,ShScriptName),'w'); % 'w' will discard existing contents of file
    fprintf(fID,'#!/bin/bash');
    fprintf(fID,'\n');
    rootdirEscaped = DuplicateChar(Directory,'\');
    fprintf(fID,['cd "' rootdirEscaped '"']); % change to root directory
    fprintf(fID,'\n');
    fprintf(fID,['"' CMTKPath 'streamxform" -- --inverse ' ... % (1) streamxform to register raw points to bridging volume
        '"Registration/affine/' BridgeBrainNameStem '_' AvgVolName(1:end-5) '_9dof.list"' ...
        ' < "' AvgVolName(1:end-9) '_AllSigCentroids.txt" > "' ...
        AvgVolName(1:end-9) '_AllSigCentroids_to' BridgeBrainNameStem '.txt"']);
    fprintf(fID,'\n');
    fprintf(fID,['"' CMTKPath 'streamxform" -- --inverse ' ... % (2) streamxform to register result of (1) to final anatomical reference volume
        '"' BridgeBrainPath BridgeBrainAffineList '"' ... % hopefully we can do a path here...
    ' < "' AvgVolName(1:end-9) '_AllSigCentroids_to' BridgeBrainNameStem '.txt" > "' ...
        AvgVolName(1:end-9) '_AllSigCentroids_to' RefBrainNameStem '.txt"']);
    fprintf(fID,'\n');
    fprintf(fID,['"' CMTKPath 'reformatx" -v ' ... % reformat the image to align to ref volume
        '--pad-out 0 -o "' AvgVolName(1:end-9) '_to_' RefBrainNameStem '.nrrd" --floating "' AvgVolName(1:end-9) '_to_' BridgeBrainNameStem '.nrrd" "' ...
        '' RefBrainPath RefBrainName '" "' BridgeBrainPath BridgeBrainAffineList '"']);
    fclose(fID);

    % run the shell script
    str1 = fullfile(Directory,ShScriptName);
    str2 = WinToLinuxPath(str1,4,1); % convert to linux path with escape chars for parenthesis
    str2 = ['/cygdrive/' Directory(1) '/' str2];
    system(['C:\cygwin64\bin\bash --login -c "' str2 '"'])
    clear str1 str2;
    
    % export imaris inventor file
    fID3 = fopen(fullfile(Directory,[AvgVolName(1:end-9) '_AllSigCentroids_to' RefBrainNameStem '.txt']),'r');
    xformedpoints = textscan(fID3,'%f64 %f64 %f64');
    xformedpoints = cell2mat(xformedpoints);
    exportImarisInv2_1(xformedpoints,fullfile(Directory,[AvgVolName(1:end-9) '_AllSigCentroids_to' RefBrainNameStem]),5,[1 1 1]);

    
    % Get the anatomical IDs from the voxel centroids
    [RegisteredPoints, PtsInRefVol, NonZeroAnatID, PtsInRefVolwAnatID] = CMTK_GetZBrainIDs2(fullfile(Directory,[AvgVolName(1:end-9) '_AllSigCentroids_to' RefBrainNameStem '.txt']),FullMaskDB,RefBrainScale);
    save(fullfile(Directory,[AvgVolName(1:end-9) '_AnatRegInfo']),'AnatParam','RegisteredPoints','PtsInRefVol','PtsInRefVolwAnatID'); % b/c it's not straightforward to save a struct, logical array or strings to HDF5
end
end
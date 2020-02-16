function CCD_TurboReg(rootdir,folderwildcard,Interpolate,Iterative)
% function CCD_TurboReg(rootdir,folderwildcard,Interpolate,Iterative)
% 4/25/2015: Gerry wrote it
% 4/26/2015: Gerry added ability to turn off pixel interpolation
% 8/6/2017: Gerry wrote it based upon CCD_BinAlign--which itself may have
% some algorithmic problems, FYI
%
% This script will take in a directory of image folder names (as specified
% by a folder wild card identifier). It will then go into each directory
% and align each mean slice tif image to the first folder's mean slice tif
% image. Only translations and rotations are allowed; this script calls
% Miji and TurboReg to perform the alignment. Aligned tif images and the
% matrix of transformations will be exported to each image folder.
%
% Options
% rootdir: the root directory containing your folders of images
% folderwildcard: a unique identifier for the set of folders to perform
% aligment on
% Interpolate: pass 1 if you want subpixel interpolation
% Iterative: pass 1 if you want each successive image to be aligned to the
% previous image (as opposed to all being aligned to the first image)
%
% Generally speaking, this script is written to work within a very specific
% image processing pipeline (that of raw images obtained with HCImage, with
% a camera triggered by a Thorlabs microscope)
%
% Expectations
% *mean images are labeled as *meanstack_z#, where * is the image name stem
% and # is the z slice number; there should be no other tif images in the
% folder that satisfy this wildcard search criteria
% *All image metadata are stored in a *_allmetadata.mat file (* is the
% ImgName) as struct 'MetaData_Thor' and matrix 'MetaData_Orca'
%
% Dependencies: Miji v.1.3.9

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

folderlist = dir(fullfile(rootdir,[folderwildcard '*']));

% get some metadata from first folder; here we assume all folders have
% the same z acquisition parameters...else you wouldn't be trying to register
% their slices!
ImgDir = fullfile(rootdir,folderlist(1).name);
MetadataFileName = dir(fullfile(ImgDir,'*_allmetadata.mat'));
MetadataFileName = MetadataFileName(1).name;
load(fullfile(ImgDir,MetadataFileName));
ActualNumSlices = str2double(MetaData_Thor.ThorImageExperiment.ZStage.Attributes.steps);
NumFlybackFrames = str2double(MetaData_Thor.ThorImageExperiment.Streaming.Attributes.flybackFrames);
SlicesPerVol = ActualNumSlices + NumFlybackFrames;

for b=1:SlicesPerVol    
    for a=1:length(folderlist)
        ImgDir = fullfile(rootdir,folderlist(a).name);
        ImgName = dir(fullfile(ImgDir,['*meanstack_z' num2str(b) '.tif']));
        ImgName = ImgName(1).name;
        [~,ImgNameStem,~] = fileparts(ImgName);
        if a==1 % first folder is source
            SourceImgName = ImgName;
            SourceImgDir = ImgDir;
        end
        ImgInfo = imfinfo(fullfile(ImgDir,ImgName));    
        ImgDims = [ImgInfo.Height ImgInfo.Width];

        % Align via TurboReg
        % get transformation values from TurboReg
        % note that TurboReg defaults to landmarks along the middle line of
        % your image, and 1/4 or 3/4 the way down
        MIJ.run('TurboReg ',['-align' ...
            ' -file ' fullfile(ImgDir,ImgName) ...
            ' 0 0 ' num2str(ImgDims(2)-1) ' ' num2str(ImgDims(1)-1) ...
            ' -file ' fullfile(SourceImgDir,SourceImgName) ... % use your first slice as your reference
            ' 0 0 ' num2str(ImgDims(2)-1) ' ' num2str(ImgDims(1)-1) ...
            ' -rigidBody ' ...
            num2str(round(ImgDims(2)/2)) ' ' num2str(round(ImgDims(1)/2)) ' ' num2str(round(ImgDims(2)/2)) ' ' num2str(round(ImgDims(1)/2)) ' ' ...
            num2str(round(ImgDims(2)/4)) ' ' num2str(round(ImgDims(1)/2)) ' ' num2str(round(ImgDims(2)/4)) ' ' num2str(round(ImgDims(1)/2)) ' ' ...
            num2str(round(ImgDims(2)*3/4)) ' ' num2str(round(ImgDims(1)/2)) ' ' num2str(round(ImgDims(2)*3/4)) ' ' num2str(round(ImgDims(1)/2)) ' ' ...
            '-hideOutput']);
        
        % uncomment this if you want to run translation only--you'll still
        % need to modify some additional code below to remove computations
        % related to rotation
%         MIJ.run('TurboReg ',['-align' ...
%             ' -file ' fullfile(ImgDir,ImgName) ...
%             ' 0 0 ' num2str(ImgDims(2)-1) ' ' num2str(ImgDims(1)-1) ...
%             ' -file ' fullfile(SourceImgDir,SourceImgName) ... % use your first slice as your reference
%             ' 0 0 ' num2str(ImgDims(2)-1) ' ' num2str(ImgDims(1)-1) ...
%             ' -translation ' ...
%             num2str(round(ImgDims(2)/2)) ' ' num2str(round(ImgDims(1)/2)) ' ' num2str(round(ImgDims(2)/2)) ' ' num2str(round(ImgDims(1)/2)) ' ' ...
%             '-hideOutput']);
        
        table = MIJ.getResultsTable; % matrix for storing transformation values

        % apply the tranformation
        sourceX0 = table(1,1); sourceY0 = table(1,2);
        targetX0 = table(1,3); targetY0 = table(1,4);
        sourceX1 = table(2,1); sourceY1 = table(2,2);
        targetX1 = table(2,3); targetY1 = table(2,4);
        sourceX2 = table(3,1); sourceY2 = table(3,2);
        targetX2 = table(3,3); targetY2 = table(3,4);
%         dx1 = targetX0 - sourceX0; % this translation seems to be in the wrong direction?
%         dy1 = targetY0 - sourceY0; % this translation seems to be in the wrong direction?
        dx1 = sourceX0 - targetX0;
        dy1 = sourceY0 - targetY0;
%         translation = sqrt(dx1^2+ dy1^2); % Amount of translation, in pixels.
        dx = sourceX2 - sourceX1;
        dy = sourceY2 - sourceY1;
        sourceAngle = atan2(dy, dx);
        dx = targetX2 - targetX1;
        dy = targetY2 - targetY1;
        targetAngle = atan2(dy, dx);
        rotation = targetAngle - sourceAngle; % Amount of rotation, in radians.

        shifteddata=imread(fullfile(ImgDir,ImgName));

        % translate with interpolation
        % see: http://www.mathworks.com/matlabcentral/newsreader/view_thread/261037#720879
        xshift=dx1;
        yshift=dy1; % since shift is finer than sampling, sub-pixel shifting is required
        xdata=[1 size(shifteddata,2)];
        ydata=[1 size(shifteddata,1)];
        T=maketform('affine',[1 0 0; 0 1 0; xshift yshift 1]);
 
       % rotate with interpolation
        degrotation = rotation*180/pi;
        if Interpolate
            shifteddata = imrotate(shifteddata,degrotation,'bicubic','crop');
        else
            shifteddata = imrotate(shifteddata,degrotation,'nearest','crop');
        end
        
        if Interpolate
            shifteddata=imtransform(shifteddata,T,'bicubic','XData',xdata,'YData',ydata);
        else
            shifteddata=imtransform(shifteddata,T,'nearest','XData',xdata,'YData',ydata);
        end

        finaldata = shifteddata;
        
        % export transformed image and save registration parameters
        imwrite(uint16(finaldata),fullfile(ImgDir,[ImgNameStem '_registered.tif']),'tiff');
        
        TransformationTable = table;
        save(fullfile(ImgDir,[ImgNameStem '_RegParams.mat']),'SourceImgName','SourceImgDir','TransformationTable','Interpolate');        
    end
    if Iterative
        SourceImgName = [ImgNameStem '_registered.tif'];
        SourceImgDir = ImgDir;
    end
end
end
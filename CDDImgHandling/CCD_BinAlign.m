function CCD_BinAlign(rootdir,ImgName,tempdir,DatasetName,XYBinSize,Interpolate)
% function CCD_BinAlign(rootdir,ImgName,tempdir,DatasetName,XYBinSize,Interpolate)
% 4/25/2015: Gerry wrote it
% 4/26/2015: Gerry added ability to turn off pixel interpolation
%
% This script will take in a single HDF5 file (where the data all reside in
% Datasetname (i.e. '/data') with dimensions Y, X, Z, and T (in that
% order), bin each frame by XYBinSize (must be an integer and the XY
% dimensions of the image must be divisible by this integer!), and then
% align all frames of a given slice (Z=1 to end) to the very first frame
% (T=1) of that given slice. Output will be one HDF5 file per slice. Pass
% interpolate = 0 if you don't want subpixel bicubic interpolation
% 
% Note: we translate and then rotate, because this seems to be the order of
% transformations used by TurboReg
%
% Dependencies: Miji v.1.3.9

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

% open matlab pool if it's not already
if ~matlabpool('size')
    matlabpool open;
end

% go to rootdir and make tempdir
cd(rootdir); 

% get image info
ImgInfo = h5info(ImgName,DatasetName);
YXZTDims = ImgInfo.Dataspace.Size;
DotExtension = find(ImgName == '.',1,'last');

for d=1:YXZTDims(3) % align each slice one-by-one
    mkdir(tempdir);
    
    % prep output file
    OutputName = [ImgName(1:DotExtension-1) '_slice' num2str(d,'%02d') '_XYBin' num2str(XYBinSize) '_Interp' num2str(Interpolate) '_aligned.h5'];
    h5create(fullfile(rootdir,OutputName),DatasetName,[YXZTDims(1)/XYBinSize YXZTDims(2)/XYBinSize YXZTDims(4)],'Datatype','single');    
    
    % First Bin and export tiff series
    parfor b=1:YXZTDims(4) % go through all time points for one slice
        CurrSlice = h5read(fullfile(rootdir,ImgName),DatasetName,[1 1 d b],[YXZTDims(1) YXZTDims(2) 1 1]);
        
        if XYBinSize ~=1
            % bin along xdim
            temp = reshape(CurrSlice,[size(CurrSlice,1) XYBinSize size(CurrSlice,2)/XYBinSize]);
            temp = sum(temp,2);
            temp = squeeze(temp);
            temp = temp';

            % bin along ydim
            temp2 = reshape(temp,[size(temp,1) XYBinSize size(temp,2)/XYBinSize]);
            temp2 = sum(temp2,2);
            temp2 = squeeze(temp2);
            temp2 = temp2';

            % now actually calculate the bin average
            temp2 = temp2./(XYBinSize^2);        
        else % don't do anything if no binning is required
            temp2 = CurrSlice;
        end
        
        % export these images as 32-bit FP tiff files
        % i.e. single() datatype is 32-bit floating point
        t = Tiff(fullfile(rootdir,tempdir,[ImgName(1:DotExtension-1) '_t' num2str(b,'%08d') '.tif']),'w');
        t.setTag('Photometric',Tiff.Photometric.LinearRaw);
        t.setTag('Compression',Tiff.Compression.None);
        t.setTag('BitsPerSample',32);
        t.setTag('SamplesPerPixel',1);
        t.setTag('SampleFormat',Tiff.SampleFormat.IEEEFP);
        t.setTag('ImageLength',size(temp2,1));
        t.setTag('ImageWidth',size(temp2,2));
        t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
        t.write(single(temp2));
        t.close();
    end
    
    % Then Align via TurboReg and export HDF5 file, one per slice
    cd(tempdir);
    Imgs = dir('*.tif');
    for a=1:length(Imgs)
        % get transformation values from TurboReg
        % note that TurboReg defaults to landmarks along the middle line of
        % your image, and 1/4 or 3/4 the way down
        MIJ.run('TurboReg ',['-align' ...
            ' -file ' fullfile(rootdir,tempdir,Imgs(a).name) ...
            ' 0 0 ' num2str(YXZTDims(2)-1) ' ' num2str(YXZTDims(1)-1) ...
            ' -file ' fullfile(rootdir,tempdir,Imgs(1).name) ... % use your first slice as your reference
            ' 0 0 ' num2str(YXZTDims(2)-1) ' ' num2str(YXZTDims(1)-1) ...
            ' -rigidBody ' ...
            num2str(round(YXZTDims(2)/2)) ' ' num2str(round(YXZTDims(1)/2)) ' ' num2str(round(YXZTDims(2)/2)) ' ' num2str(round(YXZTDims(1)/2)) ' ' ...
            num2str(round(YXZTDims(2)/4)) ' ' num2str(round(YXZTDims(1)/2)) ' ' num2str(round(YXZTDims(2)/4)) ' ' num2str(round(YXZTDims(1)/2)) ' ' ...
            num2str(round(YXZTDims(2)*3/4)) ' ' num2str(round(YXZTDims(1)/2)) ' ' num2str(round(YXZTDims(2)*3/4)) ' ' num2str(round(YXZTDims(1)/2)) ' ' ...
            '-hideOutput']);
        table = MIJ.getResultsTable; % matrix for storing transformation values

        % apply the tranformation
        sourceX0 = table(1,1); sourceY0 = table(1,2);
        targetX0 = table(1,3); targetY0 = table(1,4);
        sourceX1 = table(2,1); sourceY1 = table(2,2);
        targetX1 = table(2,3); targetY1 = table(2,4);
        sourceX2 = table(3,1); sourceY2 = table(3,2);
        targetX2 = table(3,3); targetY2 = table(3,4);
        dx1 = targetX0 - sourceX0;
        dy1 = targetY0 - sourceY0;
        translation = sqrt(dx1^2+ dy1^2); % Amount of translation, in pixels.
        dx = sourceX2 - sourceX1;
        dy = sourceY2 - sourceY1;
        sourceAngle = atan2(dy, dx);
        dx = targetX2 - targetX1;
        dy = targetY2 - targetY1;
        targetAngle = atan2(dy, dx);
        rotation = targetAngle - sourceAngle; % Amount of rotation, in radians.

        data=imread(fullfile(rootdir,tempdir,Imgs(a).name));

        % translate with interpolation
        % see: http://www.mathworks.com/matlabcentral/newsreader/view_thread/261037#720879
        xshift=dx1; yshift=dy1; % since shift is finer than sampling, sub-pixel shifting is required
        xdata=[1 size(data,2)];
        ydata=[1 size(data,1)];
        T=maketform('affine',[1 0 0; 0 1 0; xshift yshift 1]);
        
        if Interpolate
            shifteddata=imtransform(data,T,'bicubic','XData',xdata,'YData',ydata);
        else
            shifteddata=imtransform(data,T,'nearest','XData',xdata,'YData',ydata);
        end

        % rotate with interpolation
        degrotation = rotation*180/pi;
        finaldata = imrotate(shifteddata,degrotation,'bicubic','crop');
        h5write(fullfile(rootdir,OutputName),DatasetName,single(finaldata),[1 1 a],[YXZTDims(1)/XYBinSize YXZTDims(2)/XYBinSize 1]);
    end
    
    cd(rootdir);
    % clean up the temporary directory
    [success message msgID] = rmdir(fullfile(rootdir,tempdir),'s');
end
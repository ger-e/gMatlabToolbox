function Bin_MultiPlanePiezo3_function(filename,Directory,tempdir,FrameCeiling,BinSize)
% function Bin_MultiPlanePiezo3_function(filename,Directory,tempdir,FrameCeiling,BinSize)
% ~12/1/2014: Gerry wrote it
% 12/11/2014: modified to force SampleXFrames to be less than frame ceiling,
% and also divisible by both the BinSize and Piezo_fpc, such that you don't
% have to worry about remainder frames
% 12/17/2014: finished modifications to transform this into a function,
% whereby you specify filename, your frame ceiling (how many frames you can
% fit into memory at a time), and the size of the desired bins
% 12/18/2014: Gerry modified to force MIJI usage for massive
% filehandling speedup. Note as currently written, we can only handle 
% 99999 frames (filenaming) per stack
% 12/23/2014: Gerry modified to force 0 padding for file names because
% slices were being read in the wrong order by other downstream analysis
% scripts; e.g. slice 10, 11, 12, 1, 2, 3 ...
% 12/24/2014: Gerry fixed a bug with num2str on output, as well as a bug
% whereby you'd still do an additional read pass if you had no remainder
% frames
%
% Simple function to read in piezo zig-zag raw image and bin according to
% BinSize. Here we only read SampleXFrames at each loop iteration because
% of memory constraints.
%
% NOTE: this will only work for single channel image with piezo in zig-zag
% mode
%
% Todo: be able to take as input a multi-channel image

% basic parameters for you to set
% filename = 'ImageName.raw';
% SampleXFrames = 1000; % number of frames to sample each time (set as high
% as your memory allows) -->see below; you cannot define, but you can
% define your frame ceiling here
% FrameCeiling = 1000; % max number of frames your computer can handle reading in at once (memory limited). We will read in roughly this amount

% BinSize = 10; % in number of frames

mkdir(fullfile(Directory,tempdir)); % make temp directory

% get basic img parameters
[dummy, ini] = readrawfile_gerry(fullfile(Directory,filename),[],1);

% specify size of bite to take when reading in frames. Force to be a
% multiple of BinSize and Piezo_fpc
SampleXFrames = BinSize*ini.Piezo_fpc;
if SampleXFrames > FrameCeiling
    fprintf(1,'\nWarning! Minimum frame sample size exceeds your FrameCeiling: %g', SampleXFrames);
else
    SampleXFrames = FrameCeiling - mod(FrameCeiling,SampleXFrames); % take as large a bite as you can, without exceeding ceiling
end

% figure out number of distinct read passes to make (because of RAM limitations)
RemainingFrames = mod(ini.totalframes,SampleXFrames);
NumPasses = (ini.totalframes - RemainingFrames)/SampleXFrames;

Offset = 0;
for a=1:NumPasses+1 % one extra pass for the 'remainder' frames
    if a<=NumPasses % load in boluses of frames
        data = readrawfile_gerry(fullfile(Directory,filename),(a-1)*SampleXFrames-Offset,SampleXFrames);
    else % load in the 'remainder' frames
        if Offset~=0 % only read if there are remainder frames
            data = readrawfile_gerry(fullfile(Directory,filename),ini.totalframes-Offset-RemainingFrames,Offset+RemainingFrames);
            Offset = 0;
        end
    end
    for b=1:ini.Piezo_fpc
        if Offset~=0 || a<=NumPasses % only perform if on extra pass and there are remainder frames
        SliceData = data(:,:,b:ini.Piezo_fpc:end);
        
        % bin the data (take mean intensity for pixels within a bin)
        % set bin = 1 to just output the original data
        % writing tiffs in append mode
        
        % figure out how many frames to push to the next iteration
        RemainingFramesB = mod(size(SliceData,3),BinSize);
        ZtoUse = size(SliceData,3) - RemainingFramesB;
        Offset = Offset + RemainingFramesB;
        SliceData = SliceData(:,:,1:ZtoUse);
        
        temp3 = BinImg(SliceData,BinSize);
        for d=1:size(temp3,3)
            success = 0;
            while ~success
                try
                    imwrite(uint16(temp3(:,:,d)),fullfile(Directory,tempdir,[filename(1:end-4) '_slice' num2str(b,'%02d') '_binsOf' num2str(BinSize) '_t' num2str(d+(a-1)*size(temp3,3),'%05d') '.tif']),'tiff','Compression','none');
                    success = 1;
                catch
                    fprintf(1,'\nWrite Error, waiting...\n');
                    pause(0.1);
                end
            end
        end
        clear SliceData;
        end
    end
    fprintf(1,'\n%i frames not binned\n',Offset);
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
for c=1:ini.Piezo_fpc
    MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' filename(1:end-4) '_slice' num2str(c,'%02d') '_binsOf' num2str(BinSize) '_t00001.tif file=slice' num2str(c,'%02d') '_bin sort use']);
    MIJ.run('Save',['path=[' IJOutputDir '\\' filename(1:end-4) '_slice' num2str(c,'%02d') '_binsOf' num2str(BinSize) '.tif]']);
end
% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');

end
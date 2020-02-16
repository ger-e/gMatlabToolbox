function Bin_MultiPlanePiezo2_function(filename,FrameCeiling,BinSize)
% function Bin_MultiPlanePiezo2_function(filename,FrameCeiling,BinSize)
% ~12/1/2014: Gerry wrote it
% 12/11/2014: modified to force SampleXFrames to be less than frame ceiling,
% and also divisible by both the BinSize and Piezo_fpc, such that you don't
% have to worry about remainder frames
% 12/17/2014: finished modifications to transform this into a function,
% whereby you specify filename, your frame ceiling (how many frames you can
% fit into memory at a time), and the size of the desired bins
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
% filename = 'ImgName.raw';
% SampleXFrames = 1000; % number of frames to sample each time (set as high
% as your memory allows) -->see below; you cannot define, but you can
% define your frame ceiling here
% FrameCeiling = 1000; % max number of frames your computer can handle reading in at once (memory limited). We will read in roughly this amount

% BinSize = 10; % in number of frames

% get basic img parameters
[dummy, ini] = readrawfile_gerry(filename,[],1);

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
        data = readrawfile_gerry(filename,(a-1)*SampleXFrames-Offset,SampleXFrames);
    else % load in the 'remainder' frames
        data = readrawfile_gerry(filename,ini.totalframes-Offset-RemainingFrames,Offset+RemainingFrames);
        Offset = 0;
    end
    for b=1:ini.Piezo_fpc
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
                    imwrite(uint16(temp3(:,:,d)),[filename(1:end-4) '_slice' num2str(b) '_binsOf' num2str(BinSize) '.tif'],'tiff','Compression','none','WriteMode','append');
                    success = 1;
                catch
                    fprintf(1,'\nWrite Error, waiting...\n');
                    pause(0.1);
                end
            end
        end
        clear SliceData;
    end
    fprintf(1,'\n%i frames not binned\n',Offset);
end
% Img = Img(:,:,3:6:end);
% showimgdata(Img,0.1);
% 
% % does this bin into 50 bins of 4?
% blah = reshape(Img,[512*512 4 200/4]);
% blah2 = mean(blah,2);
% blah3 = reshape(blah2,[512 512 50]);
end
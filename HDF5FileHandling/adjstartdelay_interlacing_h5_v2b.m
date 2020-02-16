function adjstartdelay_interlacing_h5_v2b(ImgName,Directory,WindowSize)
% function adjstartdelay_interlacing_h5_v2(ImgName,Directory,WindowSize)
% 1/24/2015: Gerry wrote it
% This function is based off of adjstartdelay_interlacing4. Refer to that
% script for full changelog and documentation for pre-2016 modifications
% 1/1/2016: Gerry modified significantly to only export the offset values
% for interlacing, and to export these values directly to the hdf5 file
% that contains the ENTIRE dataset. Likewise, this script will take as
% input the HDF5 file that contains the ENTIRE dataset. Parallel processing
% is still done within each slice (as opposed to across slices), to allow
% for best scalability
% 1/9/2016: Gerry modified such that the background signal (10th percentile
% of each frame) is calculated directly here, thus eliminating a second
% traversal through the entire dataset
% Additional optimizations include
% 1) more efficient sliding window reading of additional frames (plus
% bugfix whereby the wrong index was being taken), allowing for neglibile
% increase in processing time with larger window sizes
% 2) more efficient mean image calculation
% 3) more efficient parallel processing (parfor on the slices, not on the
% frames)
%
% WindowSize in pixels
% 
% Note: all variables added to hdf5 file will be written with chunking and
% infinite dimensions, to allow greatest future flexibity because variables
% cannot be deleted in hdf5 files
% Note: there are limits to the values that can be had for certain values,
% due to the datatype (e.g. uint8, uint16, int8, etc)

fullpath = fullfile(Directory,ImgName); % just so we can save a bit of time in the loop

% here we assume all img data are in '/data'
ImgInfo = h5info(fullpath,'/data'); % get info for only this variable
Width = ImgInfo.Dataspace.Size(2);
Height = ImgInfo.Dataspace.Size(1);
SlicesToUse = double(h5read(fullpath,'/SlicesToUse')); %1:20
TotalAcquiredSlices = double(h5read(fullpath,'/TotalAcquiredSlices')); %23
SliceIndices = double(h5read(fullpath,'/SliceIndices'));
NumFramesPerSlice = size(SliceIndices,2);
TotalFrames = double(h5read(fullpath,'/TotalFrames'));

% initialize variables here and in the hdf5 file
AllOffsets = zeros(size(SliceIndices));
AllPostFirstFlag = zeros(size(SliceIndices));
allptile = zeros(1,TotalFrames);
if ~h5dataexists('AllOffsets',h5info(fullpath))
    h5create(fullpath,'/AllOffsets',[Inf Inf],'ChunkSize',[1 10],'Datatype','int8'); % note precision here: can only have at most a -128 to 127 displacement!
end
if ~h5dataexists('AllPostFirstFlag',h5info(fullpath))
    h5create(fullpath,'/AllPostFirstFlag',[Inf Inf],'ChunkSize',[1 10],'Datatype','int8');
end
if ~h5dataexists('Background10thPtile',h5info(fullpath))
    h5create(fullpath,'/Background10thPtile',[Inf Inf],'ChunkSize',[1 100],'Datatype','uint16');
end

% determine offsets
parfor f=1:length(SlicesToUse)
    allptile2 = zeros(1,TotalFrames);
    for a=1:NumFramesPerSlice
        % allow for moving window-based interlacing
        if a-1 > (NumFramesPerSlice-WindowSize)
            % stick with your prev temp image the rest of the way
        else
            if a == 1
                tempimg = h5read(fullpath,'/data',[1 1 SliceIndices(f,a)],[Height Width WindowSize],[1 1 TotalAcquiredSlices]); % tempimg is uint16
                ReplaceSlice = 1;
                OldSum = sum(tempimg,3,'double'); % 16-bits not enough to hold the sum!
                CurrSum = OldSum; % double
            else
                % fastest method: just read in the extra slice you need to
                % move the window, but not worrying about order per se
                SliceReplaced = tempimg(:,:,ReplaceSlice); % uint16
                tempimg(:,:,ReplaceSlice) = h5read(fullpath,'/data',[1 1 SliceIndices(f,a-1+WindowSize)],[Height Width 1]); %uint16
                CurrSum = (OldSum-double(SliceReplaced)+double(tempimg(:,:,ReplaceSlice))); % double                
                ReplaceSlice = ReplaceSlice + 1; % increment this only after you're done with it!
                if ReplaceSlice > WindowSize
                    ReplaceSlice = 1;
                end
            end
        end
        Img = single(CurrSum)./WindowSize; % single--keep as single; the following calc will be faster
        allptile2(SliceIndices(f,a)) = prctile(Img(:),10); % sliding window-based percentile
        OldSum = CurrSum; %double

        % auto-correct per frame
        % pluck out each set of lines
        lace1 = Img(:,7:2:end);
        lace2 = Img(:,8:2:end);

        % re-interlace by column, so invert
        lace1 = permute(lace1,[2 1]);
        lace2 = permute(lace2,[2 1]);

        % pad array to shift; change lace1 to 'pre' and lace2 to 'post', depending
        % on the direction you need to shift to get a coherent image
        CurrLace1 = lace1;
        CurrLace2 = lace2;
        CurrentCorr = corrcoef(CurrLace1(:,2:end-2),CurrLace2(:,2:end-2)); % note that we truncate the img so that we don't get spurious poor correlation from the padded 0's

        % initial guess shift
        templace1 = padarray(CurrLace1,[0 1],'post');
        templace2 = padarray(CurrLace2,[0 1],'pre');
        NewCorr = corrcoef(templace1(:,2:end-2),templace2(:,2:end-2));

        if NewCorr(2) > CurrentCorr(2)
            % you've chosen the right direction
            CurrentCorr = NewCorr;
            Optimal = 0;
            Offset = 2;
            while ~Optimal
                templace1 = padarray(CurrLace1,[0 Offset],'post');
                templace2 = padarray(CurrLace2,[0 Offset],'pre');
                NewCorr = corrcoef(templace1(:,(Offset+1):end-(Offset+1)),templace2(:,(Offset+1):end-(Offset+1)));
                if NewCorr(2) > CurrentCorr(2)
                    CurrentCorr = NewCorr; % store the new best
                    Optimal = 0; % try a new offset
                    Offset = Offset + 1;
                else
                    AllOffsets(f,a) = Offset - 1; % go back to prev offset
                    Optimal = 1; % you found the right offset
                    AllPostFirstFlag(f,a) = 1; % flag for which direction to pad
                end
            end
        else
            % try the other direction
            % initial guess shift
            templace1 = padarray(CurrLace1,[0 1],'pre');
            templace2 = padarray(CurrLace2,[0 1],'post');
            NewCorr = corrcoef(templace1(:,2:end-2),templace2(:,2:end-2));
            if NewCorr(2) > CurrentCorr(2)
                % you've chosen the right direction
                CurrentCorr = NewCorr;
                Optimal = 0;
                Offset = 2;
                while ~Optimal
                    templace1 = padarray(CurrLace1,[0 Offset],'pre');
                    templace2 = padarray(CurrLace2,[0 Offset],'post');
                    NewCorr = corrcoef(templace1(:,(Offset+1):end-(Offset+1)),templace2(:,(Offset+1):end-(Offset+1)));
                    if NewCorr(2) > CurrentCorr(2)
                        CurrentCorr = NewCorr; % store the new best
                        Optimal = 0; % try a new offset
                        Offset = Offset + 1;
                    else
                        AllOffsets(f,a) = Offset - 1; % go back to prev offset
                        Optimal = 1; % you found the right offset
                        AllPostFirstFlag(f,a) = -1; % flag for which direction to pad
                    end
                end
            else
                % you're already at the optimal offset
                AllOffsets(f,a) = 0;
                AllPostFirstFlag(f,a) = 0;
            end
        end
    end
    allptile = allptile + allptile2;
end

% now export the offsets and flags to the hdf5 file
h5write(fullpath,'/AllOffsets',AllOffsets,[1 1],size(AllOffsets));
h5write(fullpath,'/AllPostFirstFlag',AllPostFirstFlag,[1 1],size(AllPostFirstFlag));    

% store the background signal estimate
h5write(fullpath,'/Background10thPtile',allptile,[1 1],size(allptile));

% store the size of the window used
if ~h5dataexists('InterlaceWinSize',h5info(fullpath))
    h5create(fullpath,'/InterlaceWinSize',1,'Datatype','uint32');
end
h5write(fullpath,'/InterlaceWinSize',WindowSize);
end
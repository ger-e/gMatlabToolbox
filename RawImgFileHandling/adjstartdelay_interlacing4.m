function Offsets = adjstartdelay_interlacing4(ImgName,Directory,tempdir,WindowSize,Swap)
% function Offsets = adjstartdelay_interlacing4(ImgName,Directory,tempdir,WindowSize,Swap)
% 12/16/2014: Gerry wrote it
% 12/17/2014: Gerry modified to instead take in a tif img stack, read slice
% by slice, calc offsets, then output to new image, slice by slice. This
% allows processing of arbitrarily large images. The fixed image will no
% longer be returned
% 12/18/2014: Gerry modified to force parfor and MIJI usage for massive
% processing and filehandling speedup, respectively. Note as currently
% written, we can only handle 99999 frames (filenaming) per stack (~30min)
% 12/22/2014: Gerry modified to discard first 6 lines, as these contain the
% y-mirror (galvo) flyback 'junk' data
% 12/23/2014: Gerry modified (3b version) to allow reading >4GB tif files
% as outputted by ImageJ (these are actually raw files)
% 1/8/2015: Gerry fixed bug whereby only one set of the two interlaced
% lines was being read in, thus leading to failure to adjust interlacing
% 1/16/2015: Gerry modified to allow for sliding window of arbitrary size
% on which to calculate the appropriate correlation. This is most useful
% when each frame has very low signal/noise. Also modified to use either
% imread or ReadRawIJSlice, depending on whether the image size exceeds 32
% bit space. Finally, modified to actually discard first 6 lines
% (previously only discarded those lines when calculating the proper
% offset)
% 1/17/2015: Gerry modified intefacing with ReadRawIJSlice--imfinfo calls
% were taking too much time, so we now make a single call outside of
% ReadRawIJSlice, and then pass the appropriate information along to the
% function; also modified to ReadRawIJSliceS --> read the entire bolus at
% once to help save additional time (hmm this doesn't actually save time).
% Final improvment: just read the additional slice required for the moving
% window, as opposed to loading all the slices all over again when you
% slide the window over a step (applies only to if files are less than 2^32
% bytes); this however required alteration of the processing algorithm to
% still enable parfor loop usage
% 1/3/2016: Gerry fixed bug: the sliding window-based incremental data
% loading was performed incorrectly. Need to index a-1+WindowSize
%
% This function will take in your x by y by t raster scanned image and fix
% line interlacing / start delay issues. An optimal line scan offset will 
% be found by computing the corrcoef of each frame (comparing the frames 
% from each direction of scanning). Each full frame gets its offset value
% calculated independently. Thus, if the code is running slow, consider
% switching to parfor loops.
%
% Line interlacing can be fixed by just swapping the order of the 
% interlaced lines. Pass 0 to stay the same, 1 to swap.
%
% NOTE: an extra 1 pixel padding will occur if successive offset values
% differ by a value of only 1 pixel. This script will also automatically
% truncate the image to remove the jagged edges caused by shifting the
% scanned lines.

mkdir(fullfile(Directory,tempdir)); % make temp directory
ImgInfo = imfinfo(fullfile(Directory,ImgName));
filesize = ImgInfo(1).FileSize; % to use appropriate method if exceeds 32-bit space

if filesize < 2^32
    NumSlices = length(ImgInfo);
else
    temp2 = strfind(ImgInfo.ImageDescription,'s=');
    NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));
end

% initialize variables
% Offsets = zeros(NumSlices,1);
% PostFirst = zeros(NumSlices,1);
% just need info from first index of ImgInfo struct
ImgInfo = ImgInfo(1);

% specify parfor loop iteration conditions
NumWorkers = matlabpool('size');
FramesPerWorker = ceil(NumSlices/NumWorkers);
StartIndices = 1:FramesPerWorker:NumSlices;

% prevstr=[];
% determine offsets
parfor aa=1:length(StartIndices)
    StartA = StartIndices(aa);
    EndA = min([StartIndices(aa)+FramesPerWorker-1 NumSlices]);
    OffsetsTemp = zeros(1,EndA-StartA+1);
    PostFirstTemp = zeros(1,EndA-StartA+1);
    for a=StartA:EndA
%     tic
    if filesize < 2^32
        tempimg = zeros(ImgInfo.Height,ImgInfo.Width,WindowSize);
    end
    
    % allow for moving window-based interlacing
    if a-1 > (NumSlices-WindowSize)
        if filesize > 2^32
            % stick with your prev temp image the rest of the way
%             tempimg = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,NumSlices-WindowSize+1,WindowSize);
        else
            for b=1:WindowSize
                tempimg(:,:,b) = imread(fullfile(Directory,ImgName),'Index',NumSlices-WindowSize+b);
            end
        end
    else
        if filesize > 2^32
            if a == StartIndices(aa)
                tempimg = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,a,WindowSize);
            else
                % faster method: just read in the extra slice you need to
                % move the window
                tempimg2 = zeros(size(tempimg));
                tempimg2(:,:,1:end-1) = tempimg(:,:,2:end);
                tempimg2(:,:,end) = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,a-1+WindowSize,1);
                tempimg = tempimg2;
            end
        else
            for b=1:WindowSize
                tempimg(:,:,b) = imread(fullfile(Directory,ImgName),'Index',a+b-1);
            end
        end
    end
    Img = single(mean(tempimg,3)); % convert from uint16
    
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
                OffsetsTemp(a-StartA+1) = Offset - 1; % go back to prev offset
                Optimal = 1; % you found the right offset
                PostFirstTemp(a-StartA+1) = 1; % flag for which direction to pad
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
                    OffsetsTemp(a-StartA+1) = Offset - 1; % go back to prev offset
                    Optimal = 1; % you found the right offset
                    PostFirstTemp(a-StartA+1) = 0; % flag for which direction to pad
                end
            end
        else
            % you're already at the optimal offset
            OffsetsTemp(a-StartA+1) = 0;
            PostFirstTemp(a-StartA+1) = NaN;
        end
    end
    
%     if ~rem(a,10) % display progress
%         str=['processing frame ' num2str(a) '/' num2str(NumSlices)];
%         refreshdisp(str,prevstr,a);
%         prevstr=str;
%     end
% toc
    end
    % need to store data this way because of parfor restrictions
    OffsetsStruct(aa).data = OffsetsTemp;
    PostFirstStruct(aa).data = PostFirstTemp;
end

% reconstitute Offsets and PostFirst matrices
Offsets = []; PostFirst = [];
for d=1:length(StartIndices)
    Offsets = [Offsets OffsetsStruct(d).data];
    PostFirst = [PostFirst PostFirstStruct(d).data];
end

% edit and export fixed images
parfor b=1:NumSlices
    if filesize < 2^32
        Img = imread(fullfile(Directory,ImgName),'Index',b);
    else
        Img = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,b,1);
    end
    Img = single(Img); % convert from uint16
    lace1 = Img(:,7:2:end);
    lace2 = Img(:,8:2:end);
    lace1 = permute(lace1,[2 1]);
    lace2 = permute(lace2,[2 1]);
    CurrLace1 = lace1;
    CurrLace2 = lace2;

    % now apply the appropriate offset
    if isnan(PostFirst(b))
        % do nothing
    else
        if PostFirst(b)
            CurrLace1 = padarray(CurrLace1,[0 Offsets(b)],'post');
            CurrLace2 = padarray(CurrLace2,[0 Offsets(b)],'pre');
        else
            CurrLace1 = padarray(CurrLace1,[0 Offsets(b)],'pre');
            CurrLace2 = padarray(CurrLace2,[0 Offsets(b)],'post');
        end
    end
    % pad equally on both sides to allow final matrix dimensions to be the same
    if Offsets(b) < max(Offsets(:))
        if mod(max(Offsets(:))-Offsets(b),2) % if difference is odd number, we have issues with alignment...
            % ...take floor and add 1 pixel jitter for now (we'll address this later in registration/alignment step)
            CurrLace1 = padarray(CurrLace1,[0 floor((max(Offsets(:))-Offsets(b))/2)],'both');
            CurrLace2 = padarray(CurrLace2,[0 floor((max(Offsets(:))-Offsets(b))/2)],'both');
            CurrLace1 = padarray(CurrLace1,[0 1],'pre');
            CurrLace2 = padarray(CurrLace2,[0 1],'pre');            
        else
            CurrLace1 = padarray(CurrLace1,[0 (max(Offsets(:))-Offsets(b))/2],'both');
            CurrLace2 = padarray(CurrLace2,[0 (max(Offsets(:))-Offsets(b))/2],'both');
        end
    end
    
    % re-interlace; change the order of lace1 and lace2 if it looks like they
    % aren't interlaced correctly
    if Swap
        FixedSlice = reshape([CurrLace2(:) CurrLace1(:)]',[size(Img,1)-6 size(CurrLace1,2)]);
    else
        FixedSlice = reshape([CurrLace1(:) CurrLace2(:)]',[size(Img,1)-6 size(CurrLace1,2)]);
    end
    % optional: remove 0 padded pixels
    FixedSlice = FixedSlice(:,(max(Offsets(:))+1):end-(max(Offsets(:))+1));
    
    % restore original orientation
    FixedSlice = permute(FixedSlice,[2 1]);
    
    % export
    success = 0;
    while ~success
        try
            imwrite(uint16(FixedSlice),fullfile(Directory,tempdir,[ImgName(1:end-4) '_fixed' '_t' num2str(b,'%05d') '.tif']),'tiff','Compression','none');
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
MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' ImgName(1:end-4) '_fixed_t00001.tif sort use']);
MIJ.run('Save',['path=[' IJOutputDir '\\' ImgName(1:end-4) '_WinSize' num2str(WindowSize) '_fixed.tif]']);

% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');
end
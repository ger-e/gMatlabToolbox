function Offsets = adjstartdelay_interlacing_h5(ImgName,Directory,WindowSize,Swap)
% function Offsets = adjstartdelay_interlacing_h5(ImgName,Directory,WindowSize,Swap)
% 1/24/2015: Gerry wrote it
% 1/3/2016: Gerry fixed bug: the sliding window-based incremental data
% loading was performed incorrectly. Need to index a-1+WindowSize
%
% This function is based off of adjstartdelay_interlacing4. Refer to that
% script for full changelog and documentation.
%
% This script has the same functionality, except utilizes uncompressed HDF5
% files for I/O, which allows faster, more efficient I/O, as well as no
% constratins on data size. Miji is no longer required.

% here we assume all data are in '/data'
ImgInfo = h5info(fullfile(Directory,ImgName),'/data'); % get info for only this variable
Width = ImgInfo.Dataspace.MaxSize(2);
Height = ImgInfo.Dataspace.MaxSize(1);
NumSlices = ImgInfo.Dataspace.MaxSize(3);

% specify parfor loop iteration conditions
NumWorkers = matlabpool('size');
FramesPerWorker = ceil(NumSlices/NumWorkers);
StartIndices = 1:FramesPerWorker:NumSlices;

% determine offsets
parfor aa=1:length(StartIndices)
    StartA = StartIndices(aa);
    EndA = min([StartIndices(aa)+FramesPerWorker-1 NumSlices]);
    OffsetsTemp = zeros(1,EndA-StartA+1);
    PostFirstTemp = zeros(1,EndA-StartA+1);
    for a=StartA:EndA
%     tic
    
    % allow for moving window-based interlacing
    if a-1 > (NumSlices-WindowSize)
        % stick with your prev temp image the rest of the way
    else
        if a == StartIndices(aa)
            tempimg = h5read(fullfile(Directory,ImgName),'/data',[1 1 a],[Height Width WindowSize]);
        else
            % faster method: just read in the extra slice you need to
            % move the window
            tempimg2 = zeros(size(tempimg));
            tempimg2(:,:,1:end-1) = tempimg(:,:,2:end);
            tempimg2(:,:,end) = h5read(fullfile(Directory,ImgName),'/data',[1 1 a-1+WindowSize],[Height Width 1]);
            tempimg = tempimg2;
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

% create new file to store the fixed image
% (storing in same file is possible, but makes debugging inconvenient, esp since you can't delete variables in h5 files)
FinalHeight = Height-max(Offsets(:))-1;
FinalWidth = Width-6;
h5create([fullfile(Directory,ImgName(1:end-3)) '_WinSize' num2str(WindowSize) '_fixed.h5'],'/data',[FinalHeight FinalWidth NumSlices],'Datatype','single');

% edit and export fixed images
parfor b=1:NumSlices
    Img = h5read(fullfile(Directory,ImgName),'/data',[1 1 b],[Height Width 1]);
    Img = single(Img); % data should already be in single, but this is just in case
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
    h5write([fullfile(Directory,ImgName(1:end-3)) '_WinSize' num2str(WindowSize) '_fixed.h5'],'/data',FixedSlice,[1 1 b],[FinalHeight FinalWidth 1]);
end

end
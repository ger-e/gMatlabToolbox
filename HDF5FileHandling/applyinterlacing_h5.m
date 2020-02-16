function SliceOut = applyinterlacing_h5(MaxOffset,Height,Width,fullpath,StartIndx,Offset,PostFirst)
% function SliceOut = applyinterlacing_h5(MaxOffset,Height,Width,fullpath,StartIndx,Offset,PostFirst)
% 1/1/2016: Gerry wrote it.
% This script will take as input the metadata required to apply a
% reinterlacing transformation to a single slice. Note that this function
% locally calls h5read, so as to minimize overhead from passing the entire
% slice matrix to this function. It returns the transformed single slice

% SlicesIn is Height by Width by NumSlices
StartIndx = double(StartIndx);
% Height = 1;
% Width = 1;
% InputImgFullPath = fullfile(Directory,ImgName);
Offset = double(Offset);
PostFirst = double(PostFirst);
MaxOffset = double(MaxOffset);
% Swap = 1;

% edit and export fixed images
Img = h5read(fullpath,'/data',[1 1 StartIndx],[Height Width 1]);
% Img = single(Img); % -->no, keep data in uint16
lace1 = Img(:,7:2:end);
lace2 = Img(:,8:2:end);
lace1 = permute(lace1,[2 1]);
lace2 = permute(lace2,[2 1]);
CurrLace1 = lace1;
CurrLace2 = lace2;

% now apply the appropriate offset
if PostFirst == 0
    % do nothing
else
    if PostFirst > 0
        CurrLace1 = padarray(CurrLace1,[0 Offset],'post');
        CurrLace2 = padarray(CurrLace2,[0 Offset],'pre');
    elseif PostFirst < 0
        CurrLace1 = padarray(CurrLace1,[0 Offset],'pre');
        CurrLace2 = padarray(CurrLace2,[0 Offset],'post');
    end
end

% pad equally on both sides to allow final matrix dimensions to be the same
if Offset < MaxOffset
    if mod(MaxOffset-Offset,2) % if difference is odd number, we have issues with alignment...
        % ...take floor and add 1 pixel jitter for now (we'll address this later in registration/alignment step)
        CurrLace1 = padarray(CurrLace1,[0 floor((MaxOffset-Offset)/2)],'both');
        CurrLace2 = padarray(CurrLace2,[0 floor((MaxOffset-Offset)/2)],'both');
        CurrLace1 = padarray(CurrLace1,[0 1],'pre');
        CurrLace2 = padarray(CurrLace2,[0 1],'pre');            
    else
        CurrLace1 = padarray(CurrLace1,[0 (MaxOffset-Offset)/2],'both');
        CurrLace2 = padarray(CurrLace2,[0 (MaxOffset-Offset)/2],'both');
    end
end

% re-interlace; change the order of lace1 and lace2 if it looks like they
% aren't interlaced correctly
% if Swap
%     FixedSlice = reshape([CurrLace2(:) CurrLace1(:)]',[size(Img,1)-6 size(CurrLace1,2)]);
% else
    FixedSlice = reshape([CurrLace1(:) CurrLace2(:)]',[size(Img,1)-6 size(CurrLace1,2)]);
% end

% optional: remove 0 padded pixels
FixedSlice = FixedSlice(:,(MaxOffset+1):end-(MaxOffset+1));

% restore original orientation
SliceOut = permute(FixedSlice,[2 1]);
end
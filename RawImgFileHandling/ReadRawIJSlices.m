function Slice = ReadRawIJSlices(FullImgPath,ImgInfo,Index,NumSlices)
% function Slice = ReadRawIJSlices(FullImgPath,ImgInfo,Index,NumSlices)
% ImgInfo: struct returned by imfinfo
% Index: (starting) index of the desired slice(s)
% NumSlices: number of slices starting from Index, that you want to read in
%
% 12/23/2014: Gerry wrote it (ReadRawIJSlice)
% 1/9/2014: Gerry fixed bug: apparently I mixed up order of width and
% height...well honestly, I just guessed it the first time and guessed
% wrong
% 1/17/2014: Gerry modified to remove imfinfo call because it's VERY SLOW.
% Better practice is too get the information once BEFORE calling this
% function, and then just pass to this function. Gerry also modified to
% allow reading in boluses of slices at a time, because it's too slow to
% read in small chunks at a time
% This function will read in a raw ImageJ-created tif stack (>4GB files)

% ImgInfo = imfinfo(FullImgPath);
fid = fopen(FullImgPath,'r','b');
fseek(fid,ImgInfo(1).StripOffsets,'bof'); % seek past header

% go to desired slice
if Index > 1
    fseek(fid,ImgInfo(1).StripOffsets+(Index-1).*2.*prod([ImgInfo.Width ImgInfo.Height]),'bof');
end

% read the slice and reshape
Slice = fread(fid,prod([NumSlices ImgInfo.Height ImgInfo.Width]),[num2str(prod([NumSlices ImgInfo.Width ImgInfo.Height]))  '*uint16']);
Slice = reshape(Slice,[ImgInfo.Width ImgInfo.Height NumSlices]);
Slice = permute(Slice,[2 1 3]);
fclose(fid);
end
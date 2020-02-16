function Line = ReadRawIJLines(FullImgPath,ImgInfo,Index,NumLines)
% function Line = ReadRawIJLines(FullImgPath,ImgInfo,Index,NumLines)
% ImgInfo: struct returned by imfinfo
% Index: (starting) row of the desired line(s)
% NumLines: number of lines starting from Index, that you want to read in
%
% 1/20/2015: Gerry wrote it based upon ReadRawIJSlices
% This function will read in a raw ImageJ-created tif stack (>4GB files) on
% a per line(s) basis across all time points (slices).

% get number of slices from ImageJ header
temp2 = strfind(ImgInfo.ImageDescription,'s=');
NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));

fid = fopen(FullImgPath,'r','b');
fseek(fid,ImgInfo(1).StripOffsets,'bof'); % seek past header

% go to desired line
if Index > 1
%     fseek(fid,ImgInfo(1).StripOffsets+(Index-1).*2.*prod([ImgInfo.Width NumLines]),'bof');
    fseek(fid,ImgInfo(1).StripOffsets+2.*prod([(Index-1) ImgInfo.Width]),'bof');
end

% read the lines and reshape
Line = fread(fid,prod([NumSlices ImgInfo.Width NumLines]),[num2str(prod([ImgInfo.Width NumLines]))  '*uint16'],prod([2 ImgInfo.Width ImgInfo.Height-NumLines]));
Line = reshape(Line,[ImgInfo.Width NumLines NumSlices]);
Line = permute(Line,[2 1 3]);
fclose(fid);
end
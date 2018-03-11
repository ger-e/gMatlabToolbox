function [Img,InputImg] = LSMto4DMatrix(InputImgName, varargin)
% function Img = LSMto4DMatrix(InputImgName)
% 05/17/2010: Added: functionality to conserve memory by doing the
% transformation either as a whole, or on a per slice basis (varargin = the
% current depth to export)
% 05/13/2010: Fixed: apparently tiffread will put single channel images'
% data in a matrix, as opposed to a structure
% 04/07/2010: Gerry wrote it based upon previous code written in
% SegmentImg.m
%
% Dependencies: need tiffread28 or newer (see:
% http://www.cytosim.org/other/)
%
% This function will use tiffread to load in an UNCOMPRESSED LSM file,
% ignore metadata of the image, and simply output a 4D matrix with the
% image data where the dimensions are height, width, depth, channel. The
% function can output the full image with metadata in case the metadata is
% required.
% 
% Note: this function assumes your image is larger than 1x1 pix

if ~isempty(varargin)
    CurrentSlice = varargin{1};
else
    CurrentSlice = [];
end

% load the image
InputImg = tiffread28(InputImgName);

% for multichannel images
if size(InputImg(1,1).data,1) == 1
    % get image dimensions
    NumChannels = size(InputImg(1,1).data,2);
    Height = size(InputImg(1,1).data{1,1},1);
    Width = size(InputImg(1,1).data{1,1},2);
    Depth = size(InputImg,2);

    % initialize 4D matrix to load the image data into
    if isempty(CurrentSlice) % whole image
        Img = zeros(Height,Width,Depth,NumChannels);
    else % just one slice
        Img = zeros(Height,Width,1,NumChannels);
    end
    
    % now fill the 4D matrix with the image data
    for i=1:NumChannels % extract individual channels, data{1,1} is channel 1
        if isempty(CurrentSlice) % whole image
            for j=1:Depth % extract z-slices, blah(1,1) is top-most slice
                Img(:,:,j,i) = InputImg(1,j).data{1,i};
            end
        else % just one slice
            Img(:,:,1,i) = InputImg(1,CurrentSlice).data{1,i};
        end
    end
    
% for single channel images
else
    % get image dimensions
    NumChannels = 1;
    Height = size(InputImg(1,1).data,1);
    Width = size(InputImg(1,1).data,2);
    Depth = size(InputImg,2);

    % initialize 4D matrix to load the image data into
    if isempty(CurrentSlice) % whole image
        Img = zeros(Height,Width,Depth,NumChannels);
    else % just one slice
        Img = zeros(Height,Width,1,NumChannels);
    end
    
    % now fill the 4D matrix with the image data
    for i=1:NumChannels % extract individual channels, data{1,1} is channel 1
        if isempty(CurrentSlice) % whole img
            for j=1:Depth % extract z-slices, blah(1,1) is top-most slice
                Img(:,:,j,1) = InputImg(1,j).data;
            end
        else % just one slice
            Img(:,:,1,i) = InputImg(1,CurrentSlice).data;
        end
    end
end
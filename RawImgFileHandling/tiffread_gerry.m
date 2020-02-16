function [Img,bits] = tiffread_gerry(filename)
% function tiffread_gerry(filename)
% 11/26/2014: Gerry wrote it
% 5/25/2017: Gerry edited to query and preallocate at proper bit depth
% A simple function to read in your tiff stack (as outputted by matlab's
% imwrite) of x y z dimensions, and in original bit depth. Here we pass
% image info from imfinfo to imread to help imread run faster

info = imfinfo(filename);
numslices = length(info);
ydim = info(1).Width;
xdim = info(1).Height;
bits = info(1).BitDepth;
Img = zeros(xdim,ydim,numslices,['uint' num2str(bits)]);
for a=1:numslices
    Img(:,:,a) = imread(filename,'Index',a,'Info',info);
end

end
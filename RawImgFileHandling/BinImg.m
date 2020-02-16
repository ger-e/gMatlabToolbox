function temp3 = BinImg(SliceData,BinSize)
% function temp3 = BinImg(SliceData,BinSize)
% 11/26/2014: Gerry wrote it
% A simple function to bin your data. E.g. if you have 512x512x100, for
% xyt, you can bin into size(SliceData,3)/BinSize bins of size BinSize.
% Binning is performed by taking the mean of all values within a bin

    temp = reshape(SliceData,[size(SliceData,1)*size(SliceData,2) BinSize size(SliceData,3)/BinSize]);
    temp2 = mean(temp,2);
    temp3 = reshape(temp2,[size(SliceData,1) size(SliceData,2) size(SliceData,3)/BinSize]);
end
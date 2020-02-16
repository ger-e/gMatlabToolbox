function bytes = frameind2bytes(index,FrameSize,BitLevel)
% function bytes = frame2bytes(index,FrameSize,BitLevel)
% 8/8/2017: Gerry wrote ite
% This function will convert an index to a byte offset, based upon the size
% of your frame and bitlevel, so that you can 'index' into a raw binary
% file
% Frame size in [n m]

% 8 bits per byte
% e.g. (2-1)*1024*1024*
bytes = (index-1)*FrameSize(1)*FrameSize(2)*BitLevel/8;

end
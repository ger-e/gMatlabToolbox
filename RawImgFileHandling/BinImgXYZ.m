function FinalBinned = BinImgXYZ(MatIn,ybin,xbin,zbin)
% function FinalBinned = BinImgXYZ(MatIn,ybin,xbin,zbin)
% 8/15/2017: Gerry wrote it
% A simple function to bin in x y and z, assuming MatIn's dimensions are
% divisible by the amount you want to bin them by!
[y, x, z] = size(MatIn);
BinOverX = reshape(MatIn,[y xbin x/xbin z]);
BinOverX = squeeze(sum(BinOverX,2));
BinOverX = permute(BinOverX,[2 1 3]); % swap order to bin
BinOverY = reshape(BinOverX,[size(BinOverX,1) ybin size(BinOverX,2)/ybin z]);
BinOverY = squeeze(sum(BinOverY,2));
BinOverY = permute(BinOverY,[2 1 3]); % restore original order

BinOverZ = reshape(BinOverY,[size(BinOverY,1)*size(BinOverY,2) zbin size(BinOverY,3)/zbin]);
BinOverZ = squeeze(sum(BinOverZ,2));

% get the final mean of the bins by dividing by how much you binned
FinalBinned = reshape(BinOverZ,[size(BinOverY,1) size(BinOverY,2) size(BinOverY,3)/zbin])./(ybin*xbin*zbin);
end
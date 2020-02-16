function SliceOut = applyalignment_h5(fullpath,StartIndx,Height,Width,iOverlapY,iOverlapX,jOverlapY,jOverlapX,MaxUp,MaxDown,MaxLeft,MaxRight)
% function SliceOut = applyalignment_h5(fullpath,StartIndx,Height,Width,iOverlapY,iOverlapX,jOverlapY,jOverlapX,MaxUp,MaxDown,MaxLeft,MaxRight)
% 1/3/2016: Gerry wrote it
% This script will take as input the metadata required to apply an
% alignment transformation to a single slice. Note that this function
% locally calls h5read, so as to minimize overhead from passing the entire
% slice matrix to this function. It returns the transformed single slice.

% edit and export the aligned image
SliceOut = h5read(fullpath,'/data',[1 1 StartIndx],[Height Width 1]); % read img
SliceOut(iOverlapY(1):iOverlapY(2),iOverlapX(1):iOverlapX(2)) = ... % shift image
    SliceOut(jOverlapY(1):jOverlapY(2),jOverlapX(1):jOverlapX(2)); 
SliceOut = SliceOut(MaxUp+1:end-MaxDown,MaxLeft+1:end-MaxRight); % crop off zeros

end
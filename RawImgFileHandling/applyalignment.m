function SliceOut = applyalignment(SliceIn,iOverlapY,iOverlapX,jOverlapY,jOverlapX,MaxUp,MaxDown,MaxLeft,MaxRight,Crop)
% function SliceOut = applyalignment(SliceIn,iOverlapY,iOverlapX,jOverlapY,jOverlapX,MaxUp,MaxDown,MaxLeft,MaxRight,Crop)
% 1/3/2016: Gerry wrote it
% 5/18/2017: Gerry modified to work with any type of image--in this case,
% you just send the slice directly to this function and it returns the
% transformed and properly cropped result
%
% This script will take as input the metadata required to apply an
% alignment transformation to a single slice. Note that this function
% locally calls h5read, so as to minimize overhead from passing the entire
% slice matrix to this function. It returns the transformed single slice.

% edit and export the aligned image
if Crop % export cropped version
    SliceIn(iOverlapY(1):iOverlapY(2),iOverlapX(1):iOverlapX(2)) = ... % shift image
        SliceIn(jOverlapY(1):jOverlapY(2),jOverlapX(1):jOverlapX(2)); 
    SliceOut = SliceIn(MaxUp+1:end-MaxDown,MaxLeft+1:end-MaxRight); % crop off zeros
else % export in original dimensions
    SliceOut = zeros(size(SliceIn),'like',SliceIn);
    SliceOut(iOverlapY(1):iOverlapY(2),iOverlapX(1):iOverlapX(2)) = ... % shift image
        SliceIn(jOverlapY(1):jOverlapY(2),jOverlapX(1):jOverlapX(2));
end
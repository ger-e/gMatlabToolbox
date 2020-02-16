function filtOut = cropICs(filtIn,ImgDir,ImgNameStem)
% function filtOut = cropICs(filtIn,ImgDir,ImgNameStem)
% 8/18/2018: Gerry wrote it
% This function will load in the registration parameters (as exported
% specifically by AlignOrcaMeanVols.m) and apply the alignment to ICA
% spatial filters, followed by cropping to the smallest bounding box across
% all ICs (all of which are contained in the registration parameters *.mat
% file)
%
% Note that we expect the registration parameters *.mat file to be named in
% a very particular way!

% load registration metadata and then align and crop ICs
load(fullfile(ImgDir,[ImgNameStem '_meanstack_GJSRegParams.mat']));

% MaxUP,Down,Left,Right: max displacement in each plane, so size is [3,1]
MaxUp = max(MaxUp); MaxDown = max(MaxDown); MaxLeft = max(MaxLeft); MaxRight = max(MaxRight); % crop all planes to the same size window

% filtIn = reshape(filtIn,[256 256 nICs SlicesPerVol]); % 256 256 60 3
% filtIn should be 256 256 60 3
filtOut = zeros(length(MaxUp+1:size(filtIn,1)-MaxDown),length(MaxLeft+1:size(filtIn,2)-MaxRight),size(filtIn,3),size(filtIn,4)); % <256 <256 60 3

for c=1:size(filtIn,4)
    filtIn(iOverlapY(c,1):iOverlapY(c,2),iOverlapX(c,1):iOverlapX(c,2),:,c) = ... % shift image
        filtIn(jOverlapY(c,1):jOverlapY(c,2),jOverlapX(c,1):jOverlapX(c,2),:,c); 
    filtOut(:,:,:,c) = filtIn(MaxUp+1:end-MaxDown,MaxLeft+1:end-MaxRight,:,c); % crop off zeros
end

end
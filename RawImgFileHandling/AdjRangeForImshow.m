function Output = AdjRangeForImshow(Img,range)
% function Output = AdjRangeForImshow(Img,range)
% Img is a 2D matrix, single plane
% range is a length = 2 vector with your desired range, e.g. [0 100]
% AdjRangeForImshow.m
% This script will take in a previously determined optimal range for your
% image (that makes it look pretty) and then project all your image values
% into uint8 space for exporting and visualization in RGB. You will need to
% have loaded your image first. This script is necessary because imshow can't
% allow you to adjust the range on an RGB image. Outputted is an RGB image
% where you can select your channel of interest

% range = [400 1000]; % optimal range you found by trial and error

% clip, per the range, much as imshow does
Img = single(Img); % single() is sufficient for 16-bit images
Img(Img<range(1)) = 0;
Img(Img>range(2)) = range(2);
Temp = (Img-range(1))./range(2).*255;
Output = repmat(Temp,[1 1 3]);
Output = uint8(Output);

end
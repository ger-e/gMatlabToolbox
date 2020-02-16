function [correctedImage,xyShift] = warpImages(reference, image, warpingSettings)
% function [correctedImage,xyShift] = warpImages(reference, image, warpingSettings)
% Misha B. Ahrens and Philipp J. Keller, HHMI/Janelia Farm, 2012-2013
% Email: ahrensm@janelia.hhmi.org, kellerp@janelia.hhmi.org
% 11/10/2015: Gerry modified to allow for warping to be done with
% rectangles as opposed to just squares. Note that X and Y here are
% reversed.

pointDensityX = warpingSettings(1);
pointDensityY = warpingSettings(2);
squareSizeX  = warpingSettings(3);
squareSizeY  = warpingSettings(4);
maximumShiftX = warpingSettings(5);
maximumShiftY = warpingSettings(6);

jVector = (squareSizeX + 1):pointDensityX:(size(image, 1) - squareSizeX);
kVector = (squareSizeY + 1):pointDensityY:(size(image, 2) - squareSizeY);
dxArray = zeros(1, length(jVector) * length(kVector));
dyArray = zeros(1, length(jVector) * length(kVector));

q = 0;
for j = jVector
    for k = kVector
        q = q + 1;
        imageSquare = image((j - squareSizeX):(j + squareSizeX), (k - squareSizeY):(k + squareSizeY));
        imageSquareReference = reference((j - squareSizeX):(j + squareSizeX), (k - squareSizeY):(k + squareSizeY));
        I1 = imageSquareReference;
        I2 = imageSquare;
        C = ifftshift(ifft2(fft2(I1) .* conj(fft2(I2))));
        [dx, dy] = find(C == max(C(:)));
        dx = dx - squareSizeX - 2;
        dy = dy - squareSizeY - 2;
        
        if length(dx) ~= 1
            dx = 0;
            dy = 0;
        end;
        dxArray(q) = dx;
        dyArray(q) = dy;
    end;
end;

dxArray = dxArray .* (abs(dxArray) < maximumShiftX); % this part may need reversing
dyArray = dyArray .* (abs(dyArray) < maximumShiftY);

xShiftInterpolated = zeros(size(image,1),size(image,2));
yShiftInterpolated = zeros(size(image,1),size(image,2));

q = 0;
for j = jVector
    for k = kVector
        q = q + 1;
        xRange = max(1, j - squareSizeX):min(size(reference, 1), j + squareSizeX);
        yRange = max(1, k - squareSizeY):min(size(reference, 2), k + squareSizeY);
        
        xMaxShiftInterpolatedSquare = xShiftInterpolated(xRange, yRange);
        xNewShiftInterpolatedSquare = dxArray(q)*ones(size(xMaxShiftInterpolatedSquare));
        yMaxShiftInterpolatedSquare = yShiftInterpolated(xRange, yRange);
        yNewShiftInterpolatedSquare = dyArray(q)*ones(size(yMaxShiftInterpolatedSquare));
        
        xFinalShiftInterpolatedSquare = (abs(xMaxShiftInterpolatedSquare) >= abs(xNewShiftInterpolatedSquare)) .* xMaxShiftInterpolatedSquare + ...
            (abs(xMaxShiftInterpolatedSquare) < abs(xNewShiftInterpolatedSquare)) .* xNewShiftInterpolatedSquare;
        yFinalShiftInterpolatedSquare = (abs(yMaxShiftInterpolatedSquare) >= abs(yNewShiftInterpolatedSquare)) .* yMaxShiftInterpolatedSquare + ...
            (abs(yMaxShiftInterpolatedSquare) < abs(yNewShiftInterpolatedSquare)) .* yNewShiftInterpolatedSquare;
        
        xShiftInterpolated(xRange, yRange) = xFinalShiftInterpolatedSquare;
        yShiftInterpolated(xRange, yRange) = yFinalShiftInterpolatedSquare;
    end;
end;

noShiftVector = (1:numel(image))';
xShiftVector = xShiftInterpolated(:);
yShiftVector = yShiftInterpolated(:) * size(image, 1);
xyShift = noShiftVector - xShiftVector - yShiftVector;
imageVector = image(:);
xyShift = xyShift .* (xyShift >= 1) .* (xyShift <= length(noShiftVector)) + noShiftVector .* (xyShift < 1) + noShiftVector .* (xyShift > length(noShiftVector));
correctedImageVector = imageVector(xyShift);
correctedImage = reshape(correctedImageVector, size(image, 1), size(image, 2));
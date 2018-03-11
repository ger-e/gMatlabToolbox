% PlotElongationTensors.m
% 12/11/2010: Gerry wrote it
%
% This script will read in an elongation tensor file outputted by
% packing_analyzer_v2.0 (Benoit Aigouy, Max Planck Institute). The file is
% formatted in the following way.
% Column (1): Cell number/label
% Column (2): X coordinate of cell center
% Column (3): Y coordinate of cell center
% Column (4): X component of 2*(tensor angle)
% Column (5): Y component of 2*(tensor angle)
% Note the XY coordinates should always be positive and are arranged such
% that (1,1) is in the upper left corner of the input image and (end,end)
% is in the lower right corner of the image (i.e. coordinates are actually
% matrix indices)
%
% This script will then plot the elongation tensors, and overlay them on
% the original and segmented images from packing_analyzer_v2.0

% general file i/o
InputTensors = 'K:\TestSetFull1LH_Dapi-BetaCatenin-Dcx_ICE710_Sect08_16bit_oblique_cropped\elongation_tensor.xls'; % full path to elongation tensor file
InputSegmentedImg = 'K:\TestSetFull1LH_Dapi-BetaCatenin-Dcx_ICE710_Sect08_16bit_oblique_cropped\handCorrection.png'; % full path to segemented image of cells
TensorMatrix = xlsread(InputTensors); % read the file in
SegmentedImg = imread(InputSegmentedImg); % read the file in

% convert the 2*(tensor angle) values to 1*(tensor angle)
TwiceAngles = TensorMatrix(:,4:5);

% ...and do it in a really inefficient way, but I don't know how else to do
% it...
% angles in degrees just for quick error checking with the packing analyzer
% program
AnglesInDegrees = zeros(size(TwiceAngles,1),1);
for a=1:size(TwiceAngles,1)
    Radians = TwiceAngles(a,2)/TwiceAngles(a,1);
    if TwiceAngles(a,1) >= 0 && TwiceAngles(a,2) >= 0
        % you're in quadrant 1
        AnglesInDegrees(a) = (atan(Radians)*180/pi)/2;
    elseif TwiceAngles(a,1) <= 0 && TwiceAngles(a,2) >= 0
        % you're in quadrant 2
        AnglesInDegrees(a) = ((atan(Radians)*180/pi)+180)/2;
    elseif TwiceAngles(a,1) <= 0 && TwiceAngles(a,2) <= 0
        % you're in quadrant 3
        AnglesInDegrees(a) = ((atan(Radians)*180/pi)+180)/2;
    elseif TwiceAngles(a,1) >= 0 && TwiceAngles(a,2) <= 0
        % you're in quadrant 4
        AnglesInDegrees(a) = ((atan(Radians)*180/pi)+360)/2;
    else
        fprintf(1,'\nSomething messed up...\n');
    end
end

% now just convert back to radians
AnglesInRadians = AnglesInDegrees.*pi/180;

% and then get your x and y components for tensor plotting
% note that these components differ from the original components in that
% they represent half the original angle (which was 2*tensor angle)
XComp = cos(AnglesInRadians);
YComp = sin(AnglesInRadians);

% also get these components from the angles + pi (because we're going to
% plot the tensor as a vector field with double-headed arrows)
XCompRev = cos(AnglesInRadians+pi);
YCompRev = sin(AnglesInRadians+pi);

% now plot the tensor field
starts = TensorMatrix(:,2:3); % get the center of the cell
ends = [XComp YComp] + starts; % get direction
endsRev = [XCompRev YCompRev] + starts; % get direction (pi complement)

% calculate the unit vectors
unitVector = zeros(size(ends));
unitVectorRev = zeros(size(endsRev));
for b=1:size(ends,1)
    unitVector(b,1) = (ends(b,1)-starts(b,1))./d2points(starts(b,1),starts(b,2),ends(b,1),ends(b,2));
    unitVector(b,2) = (ends(b,2)-starts(b,2))./d2points(starts(b,1),starts(b,2),ends(b,1),ends(b,2));
    unitVectorRev(b,1) = (endsRev(b,1)-starts(b,1))./d2points(starts(b,1),starts(b,2),endsRev(b,1),endsRev(b,2));
    unitVectorRev(b,2) = (endsRev(b,2)-starts(b,2))./d2points(starts(b,1),starts(b,2),endsRev(b,1),endsRev(b,2));
end

% then plot the vector field and the cell center points
figure(2); hold on;

% note that we're plotting '-starts' so that we can align with the
% segmented image; unitVectors don't need to be transformed because they
% are all relative to the start point, so don't take the negative of them
% or you'll alter the direction!
quiver(starts(:,1),-starts(:,2),unitVector(:,1),unitVector(:,2),0.25);
quiver(starts(:,1),-starts(:,2),unitVectorRev(:,1),unitVectorRev(:,2),0.25);
plot(starts(:,1),-starts(:,2),'ro');

% now overlay the segmented image
SegmentedImg = SegmentedImg(:,:,1)'; % take the inverse to make it have the right orientation
CellBoundaries = find(SegmentedImg(:,:,1) == 255);
[XCoords YCoords] = ind2sub(size(SegmentedImg(:,:,1)),CellBoundaries);
plot(XCoords, -YCoords,'k.');
axis square;
axis equal;
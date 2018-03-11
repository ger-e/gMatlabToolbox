% ProteinDistributionNematic.m
% 12/12/2010: Gerry wrote it
%
% This script will read in the segmented image outputted by
% packing_analyzer_v2.0 (Benoit Aigouy, Max Planck Institute). It will then
% read in some other helpful files (like the original image and the
% elongation tensor file) to calculate the nematic of the cell's protein
% distribution (intensity values in your original image). 
%
% The script will restrict the calculation to only the cell border (as 
% outlined by beta-catenin, e.g.) based upon measurement information **that
% you must provide**.
% 
% The script will finally plot the segmented cells, their centers (as read
% out by the elongation tensor file, which, incidentally, is NOT exactly
% the centroid as calculated by Matlab regionprops, but is pretty much the
% same if you round to the nearest integer), and the magnitude and
% orientation of the nematic.  This magnitude and orientation gives you a
% readout of asymmetric protein distribution in the cell.

% Stuff you need to provide------------------------------------------------
% get the size of the cell border from raw measurements
WidthOfBorder = 2; % in microns (the entire border, not just that which belongs to one cell)
WidthOfBorder = WidthOfBorder/4; % fudge factor

% general file i/o
% InputRawImg = 'K:\4-ImageProcessing\PackingAnalyzer\3-Data\cx43_SGZ_cropped\dapi-gfap,mcm2-cx43-nes_Sect01,1to100.lsm'; % full path to raw image so you can read its metadata
% InputTensors = 'K:\4-ImageProcessing\PackingAnalyzer\3-Data\cx43_SGZ_cropped\elongation_tensor.xls'; % full path to elongation tensor file
% InputImg = 'K:\4-ImageProcessing\PackingAnalyzer\3-Data\cx43_SGZ_cropped\original_made_white.png'; % full path to original image (RGB white)
% InputSegmentedImg = 'K:\4-ImageProcessing\PackingAnalyzer\3-Data\cx43_SGZ_cropped\handCorrection.png'; % full path to segemented image of cel
InputRawImg = 'K:\1-DGTangentialCut\CellPolarity\TestSets\20101216_1218_C57_DGTangCutFull_NewMicro50um_TestSetFull18RH_Dapi-Nes-Vangal2-Mcm2-ZO1_ICE710_Sect03.lsm'; % full path to raw image so you can read its metadata
InputTensors = 'C:\Users\Gerry\Desktop\TestNoise\elongation_tensor.xls'; % full path to elongation tensor file
InputImg = 'C:\Users\Gerry\Desktop\TestNoise\original_made_white.png'; % full path to original image (RGB white)
InputSegmentedImg = 'C:\Users\Gerry\Desktop\TestNoise\handCorrection.png'; % full path to segemented image of cel
TensorMatrix = xlsread(InputTensors); % read the file inls
Img = imread(InputImg); Img = Img(:,:,1); % read the file in
SegmentedImg = imread(InputSegmentedImg); % read the file in
MetaData = lsminfo(InputRawImg);
MicronsPerPix = MetaData.VoxelSizeX*10^6; % get microns per pix from img metadata
DiskSize = floor(WidthOfBorder*1/MicronsPerPix); 
Disk = strel('disk',DiskSize); % create disk for imdilate/imerode

% Start script-------------------------------------------------------------
% get the center of the cells
CellCenters = TensorMatrix(:,2:3);

% convert the segmented image into logical and invert
SegmentedImg = SegmentedImg(:,:,1); % just need one channel
SegmentedImg = logical(SegmentedImg); % logical
SegmentedImg = (SegmentedImg == 0); % invert

% pull out the individual cells
Cells = bwlabel(SegmentedImg,4); % need 4-bit connectivity not 8

% now get the protein distribution nematic on a per cell basis
% note that we're actually gonna take all of the protein in the segmented
% cell, not just on the border (because I don't know how to do just the
% border...it shouldn't make that much a difference seeing that you'd
% expect all the signal on the border anyway)
Q1 = zeros(max(Cells(:)),1); % initialize matrix
Q2 = Q1; % initialize matrix
NematicOrder = Q1; % initialize matrix
Phi = Q1; % initialize matrix

for a=1:max(Cells(:))
    % get only the intensities on the perimeter
    TempCells = (Cells == a); % just focus on the current cell
    TempCells2 = imdilate(TempCells,Disk); % dilate
    TempCells3 = imerode(TempCells,Disk); % erode
    TempCells = TempCells2-TempCells3; % get perimeter
    TempCells(TempCells > 0) = a; % get back your label

    % now do your calculations
    CCol = round(CellCenters(a,1)); % get a center; note that the indices for col/row are reversed
    CRow = round(CellCenters(a,2));
    ACol = CCol+1; ARow = CRow; % get a point to the right of center
    [BRow BCol] = ind2sub(size(TempCells),find(TempCells(:) == a));
    Q1s = zeros(length(find(TempCells(:) == a)),1); % initialize matrix
    Q2s = Q1s; % initialize matrix
    for b=1:length(find(TempCells(:)==a))
        LengthA = d2points(CCol,CRow,BCol(b),BRow(b));
        LengthB = d2points(CCol,CRow,ACol,ARow); % should = 1 by defn
        LengthC = d2points(BCol(b),BRow(b),ACol,ARow);
        AngleC = acos((LengthC^2-LengthA^2-LengthB^2)/(-2*LengthA*LengthB)); % law of cosines
        if BRow(b) < CRow % correct for cos domain only in quadrants I,II
            AngleC = 2*pi-AngleC;
        end
%         Q1s(b) = double(Img(BRow(b),BCol(b)))*cos(2*AngleC);
%         Q2s(b) = double(Img(BRow(b),BCol(b)))*sin(2*AngleC);
        Q1s(b) = double(Img(BRow(b),BCol(b)))*cos(AngleC);
        Q2s(b) = double(Img(BRow(b),BCol(b)))*sin(AngleC);
    end
    Q1s(isnan(Q1s)) = 0; Q2s(isnan(Q2s)) = 0; % get rid of NaN's!
    Q1(a) = sum(Q1s);
    Q2(a) = sum(Q2s);
    NematicOrder(a) = (Q1(a)^2 + Q2(a)^2)^0.5;
%     Phi(a) = acos(Q1(a)/NematicOrder(a))/2;
    Phi(a) = acos(Q1(a)/NematicOrder(a));
end

% now plot
% get components of the angle
XComp = cos(Phi);
YComp = sin(Phi);

% also get these components from the angles + pi (because we're going to
% plot this as a vector field with double-headed arrows)
XCompRev = cos(Phi+pi);
YCompRev = sin(Phi+pi);

% now factor in the nematic order (ugh..do I really need a for loop?)
for c=1:length(XComp)
    % divide by two because we're plotting two vectors but still want the
    % right magnitude of their sum
    XComp(c) = XComp(c)*NematicOrder(c)/2;
    YComp(c) = YComp(c)*NematicOrder(c)/2;
    XCompRev(c) = XCompRev(c)*NematicOrder(c)/2;
    YCompRev(c) = YCompRev(c)*NematicOrder(c)/2;
end

% now plot the tensor field
starts = CellCenters; % get the center of the cell
ends = [XComp YComp] + starts; % get direction
endsRev = [XCompRev YCompRev] + starts; % get direction (pi complement)

% remove random border stuff on case by case basis
starts(1,1) = 0; starts(1,2) = 0;
XComp(1) = 0; YComp(1) = 0; XCompRev(1) = 0; YCompRev(1) = 0;

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
figure(1); hold on;

% note that we're plotting '-starts' so that we can align with the
% segmented image; unitVectors don't need to be transformed because they
% are all relative to the start point, so don't take the negative of them
% or you'll alter the direction!
% plot unit vectors, color coded by direction from 0 to 180 (0 to pi)
ColorCode = colormap('jet'); % 64x3 for jet
% blah = 1:64; blah = blah*-1; blah = blah'; ColorCode2 = [ColorCode blah];
% ColorCode2 = sortrows(ColorCode2,4); ColorCode2 = ColorCode2(:,1:3);
% ColorCode2 = [ColorCode' ColorCode2']';
% ColorCode = ColorCode2;
for d=1:size(Phi,1)
    ChooseColor = ceil((size(ColorCode,1)-1)/pi*Phi(d)+1);
    quiver(starts(d,1),-starts(d,2),unitVector(d,1),unitVector(d,2),10,'color',ColorCode(ChooseColor,:),'LineWidth',5);
    quiver(starts(d,1),-starts(d,2),unitVectorRev(d,1),unitVectorRev(d,2),10,'color',ColorCode(ChooseColor,:),'LineWidth',5);
end
% ...or just plot the actual magnitudes
% quiver(starts(:,1),-starts(:,2),XComp,YComp);
% quiver(starts(:,1),-starts(:,2),XCompRev,YCompRev);
plot(starts(:,1),-starts(:,2),'ro');

% now overlay the segmented image
SegmentedImgInverse = SegmentedImg'; % take the inverse to make it have the right orientation
CellBoundaries = find(SegmentedImgInverse == 0);
[XCoords YCoords] = ind2sub(size(SegmentedImgInverse(:,:,1)),CellBoundaries);
plot(XCoords, -YCoords,'w.','MarkerSize',1);
axis square;
axis equal;
set(gca,'visible','off');
set(gca,'color',[0 0 0]);
set(gcf,'color',[0 0 0]);
set(gcf, 'InvertHardCopy', 'off'); % to prevent Matlab from auto-changing the background to white
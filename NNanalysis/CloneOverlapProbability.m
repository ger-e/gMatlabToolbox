% CloneOverlapProbability.m
% 09/20/2010: Gerry wrote it
% 03/02/2011: Optimizations for file loading; modifications on output plots
% plus a correction of a math error in initialization of matrix for taking
% all distance measurements; modifications for the type of distance
% measurements to get a probability distribution for
% 03/10/2011: Added complexity to the simulation: precursors are restricted
% to the DGVolume, but Astros, when present, can be in the ML or Hilus;
% added optimizations: removed use of Shuffle() because it's really slow.
% NOTE: option(1) for the original simulation and the simulation with
% astros is different!
% 03/15/2011: Fixed bug for option (3): the number of distances to expect
% between each induced cell and every other induced cell is in fact not
% n-1, rather, it depends on the distribution of the cells in space.  n-1
% is merely the max number of non-repeating distance measurements you can
% get.
% 03/22/2011: Added functionality to store simulation data from multiple
% different starting conditions
%
%
% This script will generate the probability distribution of minimum clone
% distances, given a set of binary mask images that, as a whole, represent
% the entire volume of the analyzed dentate gyrus (or any region). Each
% 'clone' is represented as a single point in space. By default, this
% script will bin numbers by rounding to the nearest integer
%
% Dependencies: d2points3d

% Things to edit-----------------------------------------------------------
ImagesLoaded = 1; % 1 = yes they have been loaded, 0 = no, they have not; this will speed up repeated use of the script when running different conditions
Astros = 0; % 1 = yes include astrocytes, 0 = no, just use the regular model
DownScale = 1; % additional downsampling to speed up the computation; does not significantly alter the resulting distributions
NIterations = 5000; % number of iterations to run the simulation for
% MicronsPerPix = 1/DownScale.*[1 1 1];
MicronsPerPix = [1/DownScale*2.4 1/DownScale*2.4 5]; % voxel dimensions; a vector of three numbers specifying the X,Y,Z transformations from pixels to microns; be careful of transformation of this factor with downsampled images!
RandSeed = sum(clock*100); % so you can always go back and re-generate the data
rand('state',RandSeed); % seed the pseudo-random number generator

% RootDir = 'C:\Users\Michael\Desktop\3D Reconstruction\Proof of Principle Reconstruction\Nes-Zeg\1X TMX\B9 RH 2d\z_3D DG\'; % root directory
% path to your masks; they should all have the same image dimensions
% MaskDir = 'D:\Gerry\Nes-Zeg 1x TMX B9 RH 2d _in publication\Prelim Masks (Photoshop)\masks'; % path to DGmasks; PRECURSOR ONLY SIMULATION
MaskDir = 'D:\Gerry\Nes-Zeg 1x TMX B9 RH 2d _in publication\Prelim Masks (Photoshop)\mask_strel265'; % path for ASTRO ONLY SIMULATION
NumClones = 25; % number of clones to model
        NumPrecursors = NumClones;
        NumAstros = 0;
        
% choose the distance measurement type you want to make; see below for description
Option = 3;
switch Option
    case 1
        ProbabilityDistribution = zeros(NIterations,NumClones*(NumClones-1)/2); % option(1) take all distances
    case 2
        ProbabilityDistribution = zeros(NIterations,1); % option(2) just take smallest dist
    case 3
        ProbabilityDistribution = zeros(NIterations,NumClones-1); % option(3) take the distance between each clone and the nearest clone; expect at most n-1 distances
end

if Astros
    clear NumClones ProbabilityDistribution Option
    ML_GCL_Hilus_MaskDir = 'D:\Gerry\Nes-Zeg 1x TMX B9 RH 2d _in publication\Prelim Masks (Photoshop)\mask_strel265'; % path to masks that includes ML and hilus
    NumPrecursors = 4; % number of precursors to model
    NumAstros = 8; % number of astros to model
    NumClones = NumPrecursors + NumAstros;
    Option = 4;
    switch Option
        case 1
            ProbabilityDistribution = zeros(NIterations,NumPrecursors); % option(1) take distance between each precursor and the nearest astro
        case 2
            ProbabilityDistribution = zeros(NIterations,1); % option(2) just take the smallest dist
        case 3
            ProbabilityDistribution = zeros(NIterations,NumClones-1); % option(3) take the distance between each induced cell to the nearest induced cell
        case 4
            ProbabilityDistribution = zeros(NIterations,NumPrecursors-1); % option(4) take the distance between each precursor to the nearest precursor or astro
    end
end

% Now run the simulation---------------------------------------------------
if ~ImagesLoaded % save time: only load images if they haven't been loaded into memory already
    % get a list of all the mask images
    cd(MaskDir);
    imgList = dir('*.bmp');

    % initialize a matrix to put our entire DGVolumes in
    tempImg = imread(imgList(1,1).name);
    tempImg = imresize(tempImg,DownScale);
    DGVolume = zeros(size(tempImg,1),size(tempImg,2),length(imgList));
    if Astros
        ML_GCL_Hilus_Volume = zeros(size(tempImg,1),size(tempImg,2),length(imgList));
    end

    % load in all the [downsampled] images, throw into DGVolume matrix
    fprintf(1,'\nLoading Images...');
    for a=1:length(imgList) % load the DG masks
        tempImg = imread(imgList(a,1).name);
        if max(tempImg(:)>1) % check to make sure masks are datatype = logical; convert as necessary
            fprintf(1,['\n' imgList(a,1).name]);
            tempImg = im2bw(tempImg,1);
        end
        tempImg = imresize(tempImg,DownScale);
        DGVolume(:,:,a) = tempImg;
    end
    % get all the available locations in the DGVolumes
    AllPossibleCloneLocations = find(DGVolume > 0);

    if Astros
        % now load in your other masks
        cd(ML_GCL_Hilus_MaskDir);
        imgList = dir('*.bmp');
        for a=1:length(imgList) % load the ML/GCL/Hilus masks
            tempImg = imread(imgList(a,1).name);
            if max(tempImg(:)>1) % check to make sure masks are datatype = logical; convert as necessary
                fprintf(1,['\n' imgList(a,1).name]);
                tempImg = im2bw(tempImg,1);
            end
            tempImg = imresize(tempImg,DownScale);
            ML_GCL_Hilus_Volume(:,:,a) = tempImg;
        end
    % get all the available locations in the DGVolumes    
    ML_GCL_Hilus_AllPossibleCloneLocations = find(ML_GCL_Hilus_Volume > 0);
    end
    fprintf(1,'\nImages loaded!\n');

    % toy DGvolume
    % DGVolume = zeros(100,100,15);
    % DGVolume(:,:,1) = 1;
    % DGVolume(:,:,end) = 1;
end
% original simulation------------------------------------------------------
if ~Astros
% for NumClones=2:10
    for b=1:NIterations
        % randomly throw NumClones clones into the DGVolume
        SampleClones = ceil(rand(1,NumClones).*length(AllPossibleCloneLocations));
        SampleClones = AllPossibleCloneLocations(SampleClones);
        SampleCloneXYZ = zeros(NumClones,3); % initialize matrix for xyz coords of random clone locations

        % get the xyz coords of the clones
        for c=1:NumClones
            [SampleCloneXYZ(c,1) SampleCloneXYZ(c,2) SampleCloneXYZ(c,3)]= ind2sub(size(DGVolume),SampleClones(c));

            % scale the xyz coords by voxel dimensions; now we're in microns
            SampleCloneXYZ(c,1) = SampleCloneXYZ(c,1).*MicronsPerPix(1);
            SampleCloneXYZ(c,2) = SampleCloneXYZ(c,2).*MicronsPerPix(2);
            SampleCloneXYZ(c,3) = SampleCloneXYZ(c,3).*MicronsPerPix(3);        
        end

        % now get the distance between each clone and every other clone
        CloneDistances = zeros(NumClones,NumClones);
        for d=1:NumClones
            for e=1:NumClones
                CloneDistances(d,e) = d2points3d(SampleCloneXYZ(d,1),SampleCloneXYZ(d,2),SampleCloneXYZ(d,3),SampleCloneXYZ(e,1),SampleCloneXYZ(e,2),SampleCloneXYZ(e,3));
            end
        end
        CloneDistances(CloneDistances == 0) = 999999; % just set distance from clone to self to be something really big

        % eliminate matrix symmetry
        for g=1:length(CloneDistances)
            CloneDistances(g,1:g) = 999999;
        end

        switch Option
            case 1
                % option(1) now pluck out all the distances between clones
                % expect (n^2-n)/2 distances
                Dists = CloneDistances(CloneDistances<999999);
                ProbabilityDistribution(b,:) = Dists(:);
            case 2
                % option(2) now pluck out the smallest distance between any two clones
                % expect 1 distance
                SmallestDist = min(CloneDistances(:));
                ProbabilityDistribution(b) = SmallestDist;
            case 3
                % option(3) now pluck out the smallest distance between each
                % clone and every other clone
                % expect at most n-1 distances, but will get fewer
                Dists = min(CloneDistances,[],2); % minimum distances along the rows
                Dists = unique(Dists); % get all the min distances with no repeats
                Dists = Dists(1:end-1); % remove the 999999 at the end
                ProbabilityDistribution(b,1:length(Dists)) = Dists(:);
        end

        fprintf(1,'.');
        if ~mod(b,50)
            fprintf('\n');
        end
    end
    % now remove zeros from ProbabilityDistribution
    ProbabilityDistribution = ProbabilityDistribution(find(ProbabilityDistribution~=0));
% end

% simulation w/ astros-----------------------------------------------------
else
% for NumClones=2:10
    for b=1:NIterations
        % randomly throw induced cells into the DGVolumes
        SamplePrecursors = ceil(rand(1,NumPrecursors).*length(AllPossibleCloneLocations));
        SamplePrecursors = AllPossibleCloneLocations(SamplePrecursors);
        SampleAstros = ceil(rand(1,NumAstros).*length(ML_GCL_Hilus_AllPossibleCloneLocations));
        SampleAstros = ML_GCL_Hilus_AllPossibleCloneLocations(SampleAstros);
        SampleCloneXYZ = zeros(NumClones,3); % initialize matrix for xyz coords of random clone locations

        % get the xyz coords of the clones; precursors get put in first,
        % then astros
        for c=1:NumPrecursors
            [SampleCloneXYZ(c,1) SampleCloneXYZ(c,2) SampleCloneXYZ(c,3)]= ind2sub(size(DGVolume),SamplePrecursors(c));

            % scale the xyz coords by voxel dimensions; now we're in microns
            SampleCloneXYZ(c,1) = SampleCloneXYZ(c,1).*MicronsPerPix(1);
            SampleCloneXYZ(c,2) = SampleCloneXYZ(c,2).*MicronsPerPix(2);
            SampleCloneXYZ(c,3) = SampleCloneXYZ(c,3).*MicronsPerPix(3);        
        end
        for h=1:NumAstros
            [SampleCloneXYZ(c+h,1) SampleCloneXYZ(c+h,2) SampleCloneXYZ(c+h,3)]= ind2sub(size(ML_GCL_Hilus_Volume),SampleAstros(h));

            % scale the xyz coords by voxel dimensions; now we're in microns
            SampleCloneXYZ(c+h,1) = SampleCloneXYZ(c+h,1).*MicronsPerPix(1);
            SampleCloneXYZ(c+h,2) = SampleCloneXYZ(c+h,2).*MicronsPerPix(2);
            SampleCloneXYZ(c+h,3) = SampleCloneXYZ(c+h,3).*MicronsPerPix(3);
        end

        % now get the distance between each clone and every other clone
        CloneDistances = zeros(NumClones,NumClones);
        for d=1:NumClones
            for e=1:NumClones
                CloneDistances(d,e) = d2points3d(SampleCloneXYZ(d,1),SampleCloneXYZ(d,2),SampleCloneXYZ(d,3),SampleCloneXYZ(e,1),SampleCloneXYZ(e,2),SampleCloneXYZ(e,3));
            end
        end
        CloneDistances(CloneDistances == 0) = 999999; % just set distance from clone to self to be something really big

        % eliminate matrix symmetry
        for g=1:length(CloneDistances)
            CloneDistances(g,1:g) = 999999;
        end

        switch Option
            case 1
                % option(1): take the dist between each precursor and nearest astro
                % expect NumPrecursors distances
                Dists = min(CloneDistances(1:NumPrecursors,NumPrecursors+1:end),[],2);
                ProbabilityDistribution(b,1:length(Dists)) = Dists(:);
            case 2
                % option(2) now pluck out the smallest distance between any two induced cells
                % expect 1 distance
                SmallestDist = min(CloneDistances(:));
                ProbabilityDistribution(b) = SmallestDist;
            case 3
                % option(3) now pluck out the smallest distance between each
                % induced cell and every other induced cell
                % expect at most n-1 distances
                Dists = min(CloneDistances,[],2); % minimum distances along the rows
                Dists = unique(Dists); % get all the distances with no repeats
                Dists = Dists(1:end-1); % remove the 999999 at the end
                ProbabilityDistribution(b,1:length(Dists)) = Dists(:);
            case 4
                % option(4) pluck out the smallest distance between each
                % precursor cell and the nearest precursor or astro
                % expect at most NumPrecursors-1 distances
                Dists = min(CloneDistances,[],2); % minimum distances along the rows
                Dists = Dists(1:NumPrecursors); % only get distances for precursors; recall that precursors were put in the matrix first
                Dists = unique(Dists);
                ProbabilityDistribution(b,1:length(Dists)) = Dists(:);
        end
        fprintf(1,'.');
        if ~mod(b,50)
            fprintf('\n');
        end
    end
    % now remove zeros from ProbabilityDistribution
    ProbabilityDistribution = ProbabilityDistribution(find(ProbabilityDistribution~=0));    
% end
end

% uniquely store data from multiple running instances of this script
if ImagesLoaded % assuming images already loaded and simulation run once
    Distributions(end+1).name = ['n' num2str(NumPrecursors) 'Precursors' num2str(NumAstros) 'Astros_Option' num2str(Option)];
    Distributions(end).data = ProbabilityDistribution;
else % first run through to load images
    Distributions.name = ['n' num2str(NumPrecursors) 'Precursors' num2str(NumAstros) 'Astros_Option' num2str(Option)];
    Distributions.data = ProbabilityDistribution;
end
%     figure(1); hold on; cdfplot(ProbabilityDistribution(:)); hold on;
%     clear ProbabilityDistribution;    

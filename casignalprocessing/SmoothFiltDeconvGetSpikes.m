function [spmat,DeconvMat,FiltMat,FiltMat2]=SmoothFiltDeconvGetSpikes(AllSig,PtsInRefVolwAnatID,bgnoise,settings,subset)
% function [spmat,DeconvMat]=SmoothFiltDeconvGetSpikes(AllSig,PtsInRefVolwAnatID,bgnoise,settings,subset)
% ~9/23/2015: Gerry wrote it
% This script will take as input a m by n cell signal matrix (AllSig) of m
% cells and n time points or frames, a corresponding m by p anatomical ID
% matrix of m cells and p anatomical IDs (plus 4 columns--xyz coords and AllSig
% index, as outputted by CMTK_AnatomicalRegistration_v2), a background
% noise smoothed vector (bgnoise), settings for signal processing, and the
% specified subset of n frames on which to perform the signal processing.
% Note that because bgnoise vector has extreme values on its edges, you
% should always choose subset to be within the limits of your total frame
% number (e.g. if frames are 1:4000, then choose 100:3900 or equivalent,
% based upon visual inspection of bgnoise vector and where there starts to
% be great divergence due to how the signal was smoothed)
% 
% Outputted will be a sparse matrix (spmat) corresponding to the spikes
% detected; also exported are the processed signals (DeconvMat)
%
% Dependencies: Yaksi and Friedrich 2006 deconvolution scripts and Cellsort
% processing scripts

% get the data
AllSigInVol = AllSig(PtsInRefVolwAnatID(:,4),:);
AllSigInVol = AllSigInVol(~logical(PtsInRefVolwAnatID(:,4+78)+PtsInRefVolwAnatID(:,4+260)),:); % exclude voxels in eyes and spinal cord
% AllSigInVol = AllSigInVol(logical(PtsInRefVolwAnatID(:,4+275)),:);

% subtract bgnoise
ImagingRate = 1/settings.dt;
Filter = fspecial('gaussian',[1,10*ImagingRate],ImagingRate); % filter for smoothing for background noise
XX = filter2(Filter,bgnoise); % smooth the background noise
BGsubtracted = bsxfun(@minus,AllSigInVol,XX);

% take subset of data (exclude lights on and KCl frames)
BGsubtracted = BGsubtracted(:,subset);

% convert to zscore
zsig = zscore(BGsubtracted'); % note that zscore calcs along columns...
zsig = zsig';

% filter (and deconvolve)
inmat = zsig;
tic;
[DeconvMat,FiltMat,FiltMat2]=RF3_CaDeconv_GJSedit(inmat,settings.tau,settings.thrup,settings.pfilt,settings.StrongSm,settings.maxcount,settings.tbin,settings.butterfilt);
toc;

% threshold to find spikes
[spmat,~,~] = CellsortFindspikes(DeconvMat,settings.SDthresh,settings.dt,settings.deconvtau,settings.normalization); % only impt thing here is the s.d. threshold for saying something is a spike
spmat = spmat';

% visualize
% figure; plot(zsig(1,:))
% figure; plot(DeconvMat(1,:))
% figure(5); hold on; plot(find(spmat>0),round(max(DeconvMat))*spmat(spmat>0),'rx')
end
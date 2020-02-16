function CCD_CropSmooth(rootdir,UniqueIdentifier,DatasetName,FilterSize)
% function CCD_CropSmooth(rootdir,UniqueIdentifier,DatasetName,FilterSize)
% 4/25/2015: Gerry wrote it
%
% This script will take in a root directory that contains HDF5 files all
% with some unique identifier (e.g. '*toprocess*') and go through them in
% parallel to crop off zeros (e.g. from TurboReg alignment, whereby the
% zero padded border may be oblique due to rigid body rotation). You can
% optionally smooth the data afterwards with an averaging filter of
% FilterSize (e.g. [3 3] is default in fspecial). Pass an empty matrix []
% if you do not wish to smooth the data.

% go to root directory and pluck out images that have the unique identifier
cd(rootdir);
Imgs = dir(['*' UniqueIdentifier '*']);

% open matlab pool if it's not already
if ~matlabpool('size')
    matlabpool open;
end

parfor a=1:length(Imgs)
    ImgName = Imgs(a).name;
    DotExtension = find(ImgName == '.',1,'last');
    OutputName = [ImgName(1:DotExtension-1) '_final.h5'];

    WholeVol = h5read(fullfile(rootdir,ImgName),DatasetName);
    WholeVolLogic = logical(WholeVol);
    CropWindow = sum(WholeVolLogic,3);

    % now figure out the cropping window
    CropWindowKeep = CropWindow;
    CropWindowKeep(CropWindow ~= max(CropWindow(:))) = 0; % set all pixels that are not in common with all slices to 0
    go=1;
    leftside=1;
    OldMax=0;
    while go % left crop
        CurrMax = sum(CropWindowKeep(:,leftside));
        if CurrMax > OldMax || CurrMax == 0 % keep going until CurrMax stops increasing
            leftside = leftside + 1;
            OldMax = CurrMax;
        else
            leftside = leftside - 1; % and then keep the prev iteration's index
            go = 0;        
        end
    end

    go=1;
    rightside=size(CropWindowKeep,2);
    OldMax=0;
    while go % right crop
        CurrMax = sum(CropWindowKeep(:,rightside));
        if CurrMax > OldMax || CurrMax ==0
            rightside = rightside - 1;
            OldMax = CurrMax;
        else
            rightside = rightside + 1;
            go = 0;        
        end
    end

    go=1;
    topside=1;
    OldMax=0;
    while go % top crop
        CurrMax = sum(CropWindowKeep(topside,:));
        if CurrMax > OldMax || CurrMax ==0
            topside = topside + 1;
            OldMax = CurrMax;
        else
            topside = topside - 1;
            go = 0;        
        end
    end

    go=1;
    botside=size(CropWindowKeep,1);
    OldMax=0;
    while go % right crop
        CurrMax = sum(CropWindowKeep(botside,:));
        if CurrMax > OldMax || CurrMax ==0
            botside = botside - 1;
            OldMax = CurrMax;
        else
            botside = botside + 1;
            go = 0;        
        end
    end

    % now smooth the data
    if ~isempty(FilterSize)
        H = fspecial('average',FilterSize); % default hsize is [3 3]
        WholeVol = imfilter(WholeVol,H);
    end

    WholeVol = WholeVol(topside:botside,leftside:rightside,:);        
    h5create(fullfile(rootdir,OutputName),DatasetName,size(WholeVol),'Datatype','single');
    h5write(fullfile(rootdir,OutputName),DatasetName,single(WholeVol));
end
end
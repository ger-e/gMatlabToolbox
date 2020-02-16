function alignimgs_raworca(ImgName,Directory,refFrameIdx,MaxOffset,WindowSize,mystack,Verbose)
% function alignimgs_raworca(ImgName,Directory,refFrameIdx,MaxOffset,WindowSize,mystack,Verbose)
% 5/18/2017: Gerry wrote it based upon alignimgs_h5_v2b--see that script
% for full documentation details
% 5/31/2017: Gerry modified to work exclusively with pseudo-raw images from
% the Hamamatsu Ora Flash and HCImage software
% refFrameIdx to a single frame; MaxOffset in pixels; WindowSize in pixels
%
% NOTE: the full stack is currently being passed to this function

[~,ImgNameStem,~] = fileparts(ImgName);
TotalAcquiredSlices = size(mystack,3);
NumFramesPerSlice = size(mystack,4);

if isempty(refFrameIdx) % default refFrameIdx is in the middle
    refFrameIdx = floor(NumFramesPerSlice/2);
end

if isempty(MaxOffset) % set default max offset if not specified
    MaxOffset=10; % max movement allowed, in pixels
end
Method='redxcorr2normimages'; %alignment method

% initialize variables here and in the hdf5 file
AlliOverlapX = zeros(NumFramesPerSlice,2,TotalAcquiredSlices); 
AlliOverlapY = zeros(NumFramesPerSlice,2,TotalAcquiredSlices); 
AlljOverlapX = zeros(NumFramesPerSlice,2,TotalAcquiredSlices); 
AlljOverlapY = zeros(NumFramesPerSlice,2,TotalAcquiredSlices); 
MaxLeft = zeros(TotalAcquiredSlices,1);
MaxRight = zeros(TotalAcquiredSlices,1);
MaxUp = zeros(TotalAcquiredSlices,1);
MaxDown = zeros(TotalAcquiredSlices,1);

parfor f=1:TotalAcquiredSlices
    substack = squeeze(mystack(:,:,f,:));
    % read the ref slice / bolus of slices (to avg across)
    refImage = mean(substack(:,:,refFrameIdx:refFrameIdx+WindowSize),3);
    dYTemp = zeros(1,NumFramesPerSlice);
    dXTemp = zeros(1,NumFramesPerSlice);
    iOverlapXTemp = zeros(NumFramesPerSlice,2);
    iOverlapYTemp = zeros(NumFramesPerSlice,2);
    jOverlapXTemp = zeros(NumFramesPerSlice,2);
    jOverlapYTemp = zeros(NumFramesPerSlice,2);
        
    for a=1:NumFramesPerSlice 
        % first get offsets
        if a-1 > (NumFramesPerSlice-WindowSize)
            % stick with your prev temp image the rest of the way
        else
            if a == 1
                ReplaceSlice = 1;
                tempimg2 = substack(:,:,1:WindowSize);
                OldSum = sum(tempimg2,3,'double'); % 16-bits not enough to hold the sum!
                CurrSum = OldSum;
            else
                % fastest method: just read in the extra slice you need to
                % move the window, but not worrying about order per se
                SliceReplaced = tempimg2(:,:,ReplaceSlice); %uint16
                tempimg2(:,:,ReplaceSlice) = substack(:,:,a-1+WindowSize);
                CurrSum = (OldSum-double(SliceReplaced)+double(tempimg2(:,:,ReplaceSlice))); % double
                ReplaceSlice = ReplaceSlice + 1;
                if ReplaceSlice > WindowSize
                    ReplaceSlice = 1;
                end
            end
        end
        FixedImg = single(CurrSum)./WindowSize; % single--keep as single; the following calc will be faster
        OldSum = CurrSum; %double

        % now do the alignment calculation
        unalignedFrame = FixedImg; %FixedImg(floor(size(FixedImg,1)/2)-128:floor(size(FixedImg,1)/2)+128,floor(size(FixedImg,2)/2)-128:floor(size(FixedImg,2)/2)+128);
        if std(unalignedFrame(:))~=0 % in case a blank frame existed in original datafile
            [dYTemp(a),dXTemp(a),~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
            if Verbose
                disp(['Inter-trial alignment: ' 'Frame ' num2str(a) filesep num2str(size(FixedImg,3)) '. XOffset: ' num2str(dXTemp(a)) ', YOffset: ' ...
                num2str(dYTemp(a)) ', Cmax: ' num2str(cmax)]);
            end

            [iOverlapXTemp(a,:),iOverlapYTemp(a,:),~,jOverlapXTemp(a,:),jOverlapYTemp(a,:)]=...
            fcn_get_overlap(1,1,0,size(FixedImg,2),size(FixedImg,1),0,dXTemp(a)+1,dYTemp(a)+1,0,size(FixedImg,2),size(FixedImg,1),0);
        else
            dYTemp(a) = 0; dXTemp(a) = 0;
            iOverlapXTemp(a,:) = [0 0]; iOverlapYTemp(a,:) = [0 0];
            jOverlapXTemp(a,:) = [0 0]; jOverlapYTemp(a,:) = [0 0];
        end
    end
    AlliOverlapX(:,:,f) = iOverlapXTemp;
    AlliOverlapY(:,:,f) = iOverlapYTemp;
    AlljOverlapX(:,:,f) = jOverlapXTemp;
    AlljOverlapY(:,:,f) = jOverlapYTemp;
    
    % figure out the max displacements to crop 0's out later
    MaxLeft(f) = max(dXTemp(:));
    MaxRight(f) = abs(min(dXTemp(:)));
    MaxUp(f) = max(dYTemp(:));
    MaxDown(f) = abs(min(dYTemp(:)));
end

% save testalignrun AlliOverlapX AlliOverlapY AlljOverlapX AlljOverlapY MaxLeft MaxRight MaxUp MaxDown;
save(fullfile(Directory,[ImgNameStem '_gAlign_result']), ...
    'AlliOverlapX','AlliOverlapY','AlljOverlapX', 'AlljOverlapY', ...
    'MaxLeft','MaxRight','MaxUp','MaxDown', ...
    'WindowSize','refFrameIdx','MaxOffset'); 
end
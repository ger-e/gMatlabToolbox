function NumsInBins = GetBins(Dists, BinSize, StartBin, EndBin)
% function NumsInBins = GetBins(Dists, BinSize, StartBin)
% Will return the numbers in each bin for specified binsize. Note behavior
% at the tail!
%     LargestDist = max(Dists); % get max distance
    LargestDist = EndBin;
    BinEdges = StartBin:BinSize:LargestDist; % specify bins

    % add additional bin at the tail, if needed
    if BinEdges(end) ~= LargestDist
        BinEdges(end+1) = ceil(LargestDist);
    end
    
    NumsInBins = histc(Dists,BinEdges);
end
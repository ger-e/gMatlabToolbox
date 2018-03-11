function handle = baroutline(Bins,NumsInBins,Fill)
% function baroutline(Bins,NumsInBins,Fill)
% 2/12/2014: Gerry wrote it
% 5/13/2016: Gerry made slight modification: any y-values that are 0 will
% be made very very very small (10^-320) such that log scale on y-axis will
% allow the baroutline to be drawn without breaks because log(0) is
% undefined
% This function will plot a bar graph by its outline (either just a line
% drawing outline or a filled area). Returns the plot's handle for you to
% specify plot properties.
% Inputs: Bins (Xcoord locations of your bins), NumsInBins (Y coord
% magnitudes that you'd normally pass to bar(), Fill = 0 means plot outline
% with plot(), Fill = 1 means plot outline with area()

    % figure;
    % Bins = StartBin:BinSize:EndBin+BinSize;

    X = [];
    for a=1:length(Bins)
        temp = repmat(Bins(a),1,2);
        X = [X temp];
    end
    X = [X Bins(a)];

    Y = 0;
    for b=1:length(NumsInBins)
        temp2 = repmat(NumsInBins(b),1,2);
        Y = [Y temp2];
    end
    
    Y(Y==0) = 10^-320;
    if Fill
        handle = area(X,Y);
    else
        handle = plot(X,Y);
    end
end
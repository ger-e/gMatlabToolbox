function FixedVec = interpolateMyVec(MyVec,ProblemDataIndices)
% function FixedVec = interpolateMyVec(MyVec,ProblemDataIndices)
% 4/14/2917: Gerry wrote it
% This script will take in a vector and indices of this vector that
% correspond to data you've flagged as requiring removal for whatever
% reason. It will then use data neighboring each of these indices (or if
% the indices are all sequential, then the data flanking all the indices)
% to interpolate the data in between these indices. As written, linear
% interpolation is used via interp1.

ZeroBreaks = diff(ProblemDataIndices);
ZeroBreaksMarks = find(ZeroBreaks~=1);
ZeroBreaksMarks = [0 ZeroBreaksMarks(:)' length(ProblemDataIndices)];

% in case MyVec starts with zeros
if ProblemDataIndices(1) == 1
    MyVec(1) = MyVec(ProblemDataIndices(ZeroBreaksMarks(2))+1);
    ProblemDataIndices = ProblemDataIndices(2:end);
    ZeroBreaks = diff(ProblemDataIndices);
    ZeroBreaksMarks = find(ZeroBreaks~=1);
    ZeroBreaksMarks = [0 ZeroBreaksMarks(:)' length(ProblemDataIndices)];
end

% in case MyVec ends with zeros
if ProblemDataIndices(end) == length(MyVec)
    MyVec(end) = MyVec(ProblemDataIndices(ZeroBreaksMarks(end-1))-1);
    ProblemDataIndices = ProblemDataIndices(1:end-1);
    ZeroBreaks = diff(ProblemDataIndices);
    ZeroBreaksMarks = find(ZeroBreaks~=1);
    ZeroBreaksMarks = [0 ZeroBreaksMarks(:)' length(ProblemDataIndices)];    
end

FixedVec = MyVec;
for i=1:length(ZeroBreaksMarks)-1
    % compute linear interpolation between areas flanking zero values
    result = interp1([ProblemDataIndices(ZeroBreaksMarks(i)+1)-1 ProblemDataIndices(ZeroBreaksMarks(i+1))+1], ...
        [MyVec(ProblemDataIndices(ZeroBreaksMarks(i)+1)-1) MyVec(ProblemDataIndices(ZeroBreaksMarks(i+1))+1)], ...
        ProblemDataIndices(ZeroBreaksMarks(i)+1)-1:ProblemDataIndices(ZeroBreaksMarks(i+1))+1);
    
    % then put this into the original vector
%     ConvAreaToPlot(ZeroVals(1)-1:ZeroVals(1)+1) = result;
    
    FixedVec(ProblemDataIndices(ZeroBreaksMarks(i)+1)-1:ProblemDataIndices(ZeroBreaksMarks(i+1))+1) = result;
end
end
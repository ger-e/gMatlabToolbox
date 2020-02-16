function String = DuplicateChar(String,Char)
% function DuplicateChar(String,Char)
% 12/18/2014: Gerry wrote it
% This script will replicate a particular character in your string. Useful
% for converting directory strings to contain ImageJ escape characters

Loc = find(String==Char);

for a=1:length(Loc)
    String = [String(1:Loc(a)+length(Char)*(a-1)) Char String(Loc(a)+length(Char)*(a-1)+1:end)];
end
end


function str2 = WinToLinuxPath(str1,startindx,escape)
% function str2 = WinToLinuxPath(str1,startindx,escape)
% 3/10/2015: Gerry wrote it
% 1/11/2016: Gerry modified to make optional the parenthesis escaping
% This script will take in a full windows path and convert it to be used
% with linux/unix. You can also specify a particular index on which to
% start converting the path from (e.g. if you wanted to exclude some
% portion of the windows path that isn't required for the linux/unix path.
% 
% Dependencies: DuplicateChar.m

% remove a specified portion
str1 = str1(startindx:end);

% find indices to back slashes
str1indx = strfind(str1,'\');

% replace these with forward slashes
str1(str1indx) = '/';

if escape
    % add escape characters for parenthesis
    str1 = DuplicateChar(str1,'(');
    str1indx1 = strfind(str1,'(');
    str1(str1indx1(1:2:end)) = '\';

    str1 = DuplicateChar(str1,')');
    str1indx2 = strfind(str1,')');
    str1(str1indx2(1:2:end)) = '\';
end
str2 = str1;

end
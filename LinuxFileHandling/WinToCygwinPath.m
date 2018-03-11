function str2 = WinToCygwinPath(str1,escape)
% function str2 = WinToCygwinPath(str1,escape)
% 4/26/2016: Gerry wrote it, based upon WinToLinuxPath
% This script will convert a windows path to one that is proper for use in
% cygwin
% Dependencies: DuplicateChar.m

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

% then convert the root directory letter to a cygwin-type path
str2 = ['/cygdrive/' str2(1) str2(3:end)];

end
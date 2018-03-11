function ProgenitorComposition(Rootdirs,Names,Classifications,DataType)
% ProgenitorComposition.m
% 06/17/2010: Gerry wrote it
% 08/03/2010: Modified to be called as a function from NNmain.m
%
% This script will read in the datafiles outputted by ReadSpotsXLS.m and
% output a pie graph of the percent composition of each progenitor subtype
% as compared to the entire population of progenitors

NumProgenitors = zeros(length(Classifications),1);

% get the number of each progenitor subtype
for b=1:length(Rootdirs)
    load([Rootdirs{b} Names{b}]);
    for a=1:length(Classifications)
        if b==1
            if exist(Classifications{a},'var')
                eval(['NumProgenitors(a) = size(' Classifications{a} ',1);'])
            else
                NumProgenitors(a) = 0;
            end
        else
            if exist(Classifications{a},'var')
                eval(['NumProgenitors(a) = NumProgenitors(a) + size(' Classifications{a} ',1);'])
            end
        end
    end
end

% total number of progenitors
TotalNumProgenitors = sum(NumProgenitors);

% make a pie chart
figure(5); pie(NumProgenitors,Classifications); title(['all progenitors - ' DataType]);
figure(6); pie(NumProgenitors(1:5),Classifications(1:5)); title(['just nestin - ' DataType]);
figure(7); pie(NumProgenitors(2:10),Classifications(2:10)); title(['just mcm2 - ' DataType]);
figure(8); pie(NumProgenitors(8:12),Classifications(8:12)); title(['just dcx - ' DataType]);
figure(9); pie([NumProgenitors(3) NumProgenitors(5) NumProgenitors(7:9)'],[Classifications(3) Classifications(5) Classifications(7:9)]); title(['just tbr2 - ' DataType]);
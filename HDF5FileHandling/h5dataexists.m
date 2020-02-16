function DataExists = h5dataexists(QueryStr,DataInfo)
% function DataExists = h5dataexists(QueryStr,DataInfo)
% 1/1/2015: Gerry wrote it
% This function will search the Datasets names of your HDF5 file to see if
% a particular dataset has already been created via h5create. If so, it
% returns 1, if not, it returns 0

StringExists = zeros(1,numel(DataInfo.Datasets));
for a=1:length(DataInfo.Datasets)
    StringExists(a) = strcmp(DataInfo.Datasets(a).Name,QueryStr);
end

DataExists = logical(sum(StringExists));

end
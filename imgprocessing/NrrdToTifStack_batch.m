function NrrdToTifStack_batch(inputDirPath)
% function NrrdToTifStack_batch(inputDirPath)
% 1/5/2017: Gerry wrote it
% 2/20/2017: Update: this script is somewhat obsolete, now that we are
% employing nrrdread and nrrdWriter
%
% This script will utilize MIJI to convert a directory of gzip compressed
% nrrd images (as outputted by CMTK, e.g.) into tiff stacks. Bioformats is
% not an option because, e.g., CMTK-exported nrrd files have gzip
% compression and bioformats cannot read files with compression

% get the list of nrrd images
inputDir = inputDirPath;
inputFiles = dir(fullfile(inputDir,'*.nrrd'));

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

for a=1:length(inputFiles)
    inputFileName = inputFiles(a).name;
    [~,FileNameStem,~] = fileparts(inputFileName);
    
    % now read nrrd stack and then export tif stack
    MIJ.run('Open...', ['path=[' inputDir '\\' inputFileName ']']);
    MIJ.run('Save',['path=[' inputDir '\\' FileNameStem '.tif]']);
end
MIJ.closeAllWindows; % note this does not clear java heap space

% reader = bfGetReader();
% reader = loci.formats.Memoizer(reader);
% reader.setId(fullfile(inputDir,inputFileName));
% omeMeta = reader.getMetadataStore();
% XDim = omeMeta.getPixelsSizeX(0).getValue();
% YDim = omeMeta.getPixelsSizeY(0).getValue();
% ZDim = omeMeta.getPixelsSizeZ(0).getValue();
% CurrVolume = zeros(YDim,XDim,ZDim,'uint16');
% tempslice = zeros(YDim,XDim,'uint16'); 
% for a=1:ZDim
%     Index = reader.getIndex(a-1,0,0) + 1;
%     success = 0;
%     while ~success % guard against network errors
%         try
%             tempslice = bfGetPlane(reader,Index);
%             success = 1;
%         catch
%             fprintf(1,'\nRead Error...trying again...\n');
%             pause(0.1);
%         end
%     end    
%     CurrVolume(:,:,a) = tempslice;
% end
% reader.close()
% ^^ the above wont work because of gzip compression on the nrrd files



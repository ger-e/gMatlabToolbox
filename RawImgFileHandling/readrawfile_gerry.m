function [data, ini] = readrawfile_gerry(filename,skipframes,frames)
% function [data, ini] = readrawfile_gerry(filename,skipframes,frames)
% 11/25/2014: Gerry wrote it
% 4/27/2015: Gerry modified to read in the proper number of frames when
% number of channels > 1
% This is a work in progress, based off of readrawfile, but working for the
% specific instance of single channel, single sweep through z-stack (each
% plane sampled multiple frames, but each plane visited only once).
%
% Writing this code was motivated by the fact that readrawfile has a bug
% whereby it does not properly skip frames, at least for this type of data

% read in the ini file-----------------------------------------------------
[pathstr, filenameWOext] = fileparts(filename);
inifilename=[filenameWOext '.ini'];
inistring=fileread(fullfile(pathstr,inifilename));

% get total number of frames acquired
ini.totalframes = readVarIni(inistring,'no..of.frames.to.acquire');

% get xy dimensions of stack
ini.y=readVarIni(inistring,'y.pixels');
ini.x=readVarIni(inistring,'x.pixels');

% Check Peizo status and mode.
ini.Piezo_active=readVarIni(inistring,'piezo.active'); % Peizo active?
ini.Piezo_active=strcmpi(ini.Piezo_active(2:5),'true');
ini.Piezo_mode=readVarIni(inistring,'piezo.mode'); % Peizo mode: False is default interleaved slicing mode; true = zig-zag
ini.Piezo_mode=strcmpi(ini.Piezo_mode(2:5),'true');
ini.Piezo_fpc=readVarIni(inistring,'frames.per.z.cycle'); % Peizo plane numbers.

% get additional relevant metadata
ini.FPS=readVarIni(inistring,'frames.p.sec'); % frame acquisition rate

% Check channels
savechan = zeros(5,1);
for channum=1:5
    temp = readVarIni(inistring,['save.ch.' num2str(channum)]);
    temp = strcmpi(temp(2:5),'true');
    savechan(channum) = temp;
end

% start reading in the data------------------------------------------------
fid=fopen(filename,'r','b');

% read in all frames unless otherwise specified
if ~exist('frames') || isempty(frames)
    frames=ini.totalframes*sum(savechan);
end

% move file pointer to skip frames requested
if exist('skipframes') && ~isempty(skipframes) && skipframes~=0
    status = fseek(fid,skipframes.*2.*prod([ini.x ini.y]),'bof');
    if status < 0 % gerry edit
        fprintf('\nError: frames not skipped. Likely skipped more frames than you have!\n');
    end
    clear status;
end
    
data=single(zeros(ini.x*ini.y,frames));

prevstr=[];
for fr=1:frames;
    if ~rem(fr,10) % display progress
        str=['loading frame ' num2str(fr) '/' num2str(frames)];
        refreshdisp(str,prevstr,fr);
        prevstr=str;
    end
    try
        data(:,fr)=fread(fid,prod([ini.x ini.y]),[num2str(prod([ini.x ini.y]))  '*uint16']);
    catch
        fr=fr-1;
        data=data(:,1:fr);
        break
    end
end
data=reshape(data,[ini.x ini.y fr]);    

fprintf(1,'\n'); % new line after progress bar
fclose(fid); % make sure to close the filestream!
end
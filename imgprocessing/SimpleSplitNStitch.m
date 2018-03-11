function SimpleSplitNStitch(ImgName,Directory,TileLayout)
% function SimpleSplitNStitch(ImgName,Directory,TileLayout)
% 2/24/2015: Gerry wrote it
% This simple script will read in a tiles LSM file (unstitched), pluck out
% the individual tiles, and then feed into ImageJ for stitching. As
% written, the ImageJ portion only works if you have just two tiles

% ImgName = 'Img.lsm';
% TileLayout = [2 1]; % number of tiles in each direction, [y x]

cd(Directory);
Img = LSMto4DMatrix(ImgName); % load in the whole image at once
TileDim = size(Img,1)/TileLayout(1); % calculate size of each tile

Count = 1;
for c=1:TileLayout(2)
    for d=1:TileLayout(1)
        OutputNames(Count).name = [ImgName(1:end-4) 'tile_x' num2str(c) 'y' num2str(d) '.tif'];
        for p=1:size(Img,3)
            Tile = Img(1+TileDim*(d-1):TileDim*d,1+TileDim*(c-1):TileDim*c,p);
            success = 0;
            while ~success
                try
                    imwrite(uint8(Tile),OutputNames(Count).name,'tiff','WriteMode','append');
                    success = 1;
                catch
                    pause(0.1);
                end
            end
        end
        Count = Count + 1;
    end
end


% then call MIJI
CurrDir = DuplicateChar(Directory,'\');

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

% read in your stacks
for c=1:TileLayout(2)
    for d=1:TileLayout(1)
        MIJ.run('Open...', ['path=[' CurrDir '\\' ImgName(1:end-4) 'tile_x' num2str(c) 'y' num2str(d) '.tif]']);
    end
end

% now stitch
MIJ.run('Pairwise stitching', ['first_image=' ...
OutputNames(1).name ...
' second_image=' ...
OutputNames(2).name ...
' fusion_method=[Linear Blending] fused_image=' ...
ImgName(1:end-4) '_stitched.tif ' ...
'check_peaks=5 compute_overlap subpixel_accuracy x=0 y=0 z=0 ' ...
'registration_channel_image_1=[Average all channels] ' ... 
'registration_channel_image_2=[Average all channels]']);

% now read virtual stack and then export tif stack
MIJ.run('Save',['path=[' CurrDir '\\' ImgName(1:end-4) '_stitched.tif]']);
end
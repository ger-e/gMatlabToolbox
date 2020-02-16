function Offsets = adjstartdelay_interlacing3(ImgName,Directory,tempdir,Swap)
% function Offsets = adjstartdelay_interlacing3(ImgName,Directory,tempdir,Swap)
% 12/16/2014: Gerry wrote it
% 12/17/2014: Gerry modified to instead take in a tif img stack, read slice
% by slice, calc offsets, then output to new image, slice by slice. This
% allows processing of arbitrarily large images. The fixed image will no
% longer be returned
% 12/18/2014: Gerry modified to force parfor and MIJI usage for massive
% processing and filehandling speedup, respectively. Note as currently
% written, we can only handle 99999 frames (filenaming) per stack (~30min)
% 12/22/2014: Gerry modified to discard first 6 lines, as these contain the
% y-mirror (galvo) flyback 'junk' data
% 1/8/2015: Gerry fixed bug whereby only one set of the two interlaced
% lines was being read in, thus leading to failure to adjust interlacing
%
% This function will take in your x by y by t raster scanned image and fix
% line interlacing / start delay issues. An optimal line scan offset will 
% be found by computing the corrcoef of each frame (comparing the frames 
% from each direction of scanning). Each full frame gets its offset value
% calculated independently. Thus, if the code is running slow, consider
% switching to parfor loops.
%
% Line interlacing can be fixed by just swapping the order of the 
% interlaced lines. Pass 0 to stay the same, 1 to swap.
%
% NOTE: an extra 1 pixel padding will occur if successive offset values
% differ by a value of only 1 pixel. This script will also automatically
% truncate the image to remove the jagged edges caused by shifting the
% scanned lines.
%
% Uncomment the code at the very end to see the restricted 3D and 2D cases
% in case you need them

mkdir(fullfile(Directory,tempdir)); % make temp directory
NumSlices = length(imfinfo(fullfile(Directory,ImgName)));

% initialize variables
Offsets = zeros(NumSlices,1);
PostFirst = zeros(NumSlices,1);
    
% determine offsets
parfor a=1:NumSlices
    Img = imread(fullfile(Directory,ImgName),'Index',a);
    Img = single(Img); % convert from uint16
    
    % auto-correct per frame
    % pluck out each set of lines
    lace1 = Img(:,7:2:end);
    lace2 = Img(:,8:2:end);

    % re-interlace by column, so invert
    lace1 = permute(lace1,[2 1]);
    lace2 = permute(lace2,[2 1]);

    % pad array to shift; change lace1 to 'pre' and lace2 to 'post', depending
    % on the direction you need to shift to get a coherent image
    CurrLace1 = lace1;
    CurrLace2 = lace2;
    CurrentCorr = corrcoef(CurrLace1(:,2:end-2),CurrLace2(:,2:end-2)); % note that we truncate the img so that we don't get spurious poor correlation from the padded 0's
    
    % initial guess shift
    templace1 = padarray(CurrLace1,[0 1],'post');
    templace2 = padarray(CurrLace2,[0 1],'pre');
    NewCorr = corrcoef(templace1(:,2:end-2),templace2(:,2:end-2));
    
    if NewCorr(2) > CurrentCorr(2)
        % you've chosen the right direction
        CurrentCorr = NewCorr;
        Optimal = 0;
        Offset = 2;
        while ~Optimal
            templace1 = padarray(CurrLace1,[0 Offset],'post');
            templace2 = padarray(CurrLace2,[0 Offset],'pre');
            NewCorr = corrcoef(templace1(:,(Offset+1):end-(Offset+1)),templace2(:,(Offset+1):end-(Offset+1)));
            if NewCorr(2) > CurrentCorr(2)
                CurrentCorr = NewCorr; % store the new best
                Optimal = 0; % try a new offset
                Offset = Offset + 1;
            else
                Offsets(a) = Offset - 1; % go back to prev offset
                Optimal = 1; % you found the right offset
                PostFirst(a) = 1; % flag for which direction to pad
            end
        end
    else
        % try the other direction
        % initial guess shift
        templace1 = padarray(CurrLace1,[0 1],'pre');
        templace2 = padarray(CurrLace2,[0 1],'post');
        NewCorr = corrcoef(templace1(:,2:end-2),templace2(:,2:end-2));
        if NewCorr(2) > CurrentCorr(2)
            % you've chosen the right direction
            CurrentCorr = NewCorr;
            Optimal = 0;
            Offset = 2;
            while ~Optimal
                templace1 = padarray(CurrLace1,[0 Offset],'pre');
                templace2 = padarray(CurrLace2,[0 Offset],'post');
                NewCorr = corrcoef(templace1(:,(Offset+1):end-(Offset+1)),templace2(:,(Offset+1):end-(Offset+1)));
                if NewCorr(2) > CurrentCorr(2)
                    CurrentCorr = NewCorr; % store the new best
                    Optimal = 0; % try a new offset
                    Offset = Offset + 1;
                else
                    Offsets(a) = Offset - 1; % go back to prev offset
                    Optimal = 1; % you found the right offset
                    PostFirst(a) = 0; % flag for which direction to pad
                end
            end
        else
            % you're already at the optimal offset
            Offsets(a) = 0;
            PostFirst(a) = NaN;
        end
    end
end

% edit and export fixed images
for b=1:NumSlices
    Img = imread(fullfile(Directory,ImgName),'Index',b);
    Img = single(Img); % convert from uint16
    lace1 = Img(:,1:2:end);
    lace2 = Img(:,2:2:end);
    lace1 = permute(lace1,[2 1]);
    lace2 = permute(lace2,[2 1]);
    CurrLace1 = lace1;
    CurrLace2 = lace2;

    % now apply the appropriate offset
    if isnan(PostFirst(b))
        % do nothing
    else
        if PostFirst(b)
            CurrLace1 = padarray(CurrLace1,[0 Offsets(b)],'post');
            CurrLace2 = padarray(CurrLace2,[0 Offsets(b)],'pre');
        else
            CurrLace1 = padarray(CurrLace1,[0 Offsets(b)],'pre');
            CurrLace2 = padarray(CurrLace2,[0 Offsets(b)],'post');
        end
    end
    % pad equally on both sides to allow final matrix dimensions to be the same
    if Offsets(b) < max(Offsets(:))
        if mod(max(Offsets(:))-Offsets(b),2) % if difference is odd number, we have issues with alignment...
            % ...take floor and add 1 pixel jitter for now (we'll address this later in registration/alignment step)
            CurrLace1 = padarray(CurrLace1,[0 floor((max(Offsets(:))-Offsets(b))/2)],'both');
            CurrLace2 = padarray(CurrLace2,[0 floor((max(Offsets(:))-Offsets(b))/2)],'both');
            CurrLace1 = padarray(CurrLace1,[0 1],'pre');
            CurrLace2 = padarray(CurrLace2,[0 1],'pre');            
        else
            CurrLace1 = padarray(CurrLace1,[0 (max(Offsets(:))-Offsets(b))/2],'both');
            CurrLace2 = padarray(CurrLace2,[0 (max(Offsets(:))-Offsets(b))/2],'both');
        end
    end
    
    % re-interlace; change the order of lace1 and lace2 if it looks like they
    % aren't interlaced correctly
    if Swap
        FixedSlice = reshape([CurrLace2(:) CurrLace1(:)]',[size(Img,1) size(CurrLace1,2)]);
    else
        FixedSlice = reshape([CurrLace1(:) CurrLace2(:)]',[size(Img,1) size(CurrLace1,2)]);
    end
    % optional: remove 0 padded pixels
    FixedSlice = FixedSlice(:,(max(Offsets(:))+1):end-(max(Offsets(:))+1));
    
    % restore original orientation
    FixedSlice = permute(FixedSlice,[2 1]);
    
    % export
    success = 0;
    while ~success
        try
            imwrite(uint16(FixedSlice),fullfile(Directory,tempdir,[ImgName(1:end-4) '_fixed' '_t' num2str(b,'%05d') '.tif']),'tiff','Compression','none');
            success = 1;
        catch
            fprintf(1,'\nWrite error, retrying...');
            pause(0.1);
        end
    end
end

% then call MIJI to export to tiff stack, and clean up
FullTempDir = DuplicateChar(fullfile(Directory,tempdir),'\');
IJOutputDir = DuplicateChar(Directory,'\');

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

% now read virtual stack and then export tif stack
MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' ImgName(1:end-4) '_fixed_t00001.tif sort use']);
MIJ.run('Save',['path=[' IJOutputDir '\\' ImgName(1:end-4) '_fixed.tif]']);

% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');

%% below is the 3D case, single offset value
% % pluck out each set of lines
% lace1 = blah(:,1:2:end,:);
% lace2 = blah(:,2:2:end,:);
% 
% % re-interlace by column, so invert
% lace1 = permute(lace1,[2 1 3]);
% lace2 = permute(lace2,[2 1 3]);
% 
% % pad array to shift; change lace1 to 'pre' and lace2 to 'post', depending
% % on the direction you need to shift to get a coherent image
% lace1 = padarray(lace1,[0 2 0],'post');
% lace2 = padarray(lace2,[0 2 0],'pre');
% 
% % re-interlace; change the order of lace1 and lace2 if it looks like they
% % aren't interlaced correctly
% test2 = reshape([lace2(:) lace1(:)]',[size(blah,1) size(lace1,2) size(blah,3)]);
% 
% % restore original orientation
% test2 = permute(test2,[2 1 3]);

%% below is the simple 2D case, single offset value
% % pluck out each set of lines
% lace1 = test(:,1:2:end);
% lace2 = test(:,2:2:end);
% 
% % re-interlace by column, so invert
% lace1 = lace1';
% lace2 = lace2';
% 
% % pad array to shift; change lace1 to 'pre' and lace2 to 'post', depending
% % on the direction you need to shift to get a coherent image
% lace1 = padarray(lace1,[0 2],'post');
% lace2 = padarray(lace2,[0 2],'pre');
% 
% % re-interlace; change the order of lace1 and lace2 if it looks like they
% % aren't interlaced correctly
% test2 = reshape([lace2(:) lace1(:)]',[size(test,2) size(lace1,2)]);
% 
% % restore original orientation
% test2 = test2';
end
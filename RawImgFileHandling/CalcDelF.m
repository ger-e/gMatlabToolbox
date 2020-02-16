function [delF, MindelF] = CalcDelF(Img,Baseline,ShiftMinToZero)
% function delF = CalcDelF(Img,Baseline,ShiftMeanToZero)
% 12/11/2014: This function will calculate normalized change in
% fluorescence. It also gives you the option to shift the minimum delF
% value to zero, for use with PCA/ICA (which cannot accept negative
% values). Pass ShiftMinToZero = 1 to evoke this.
%
% This function will output delF, plus the min(delF(:)).
%
% Baseline can either be a 2D single plane, or a 3D matrix that you want to
% average over


    if ndims(Baseline < 3)
        Baseline = repmat(Baseline,[1 1 2]); % dummy replicate it so you can still take a 'mean'
    end
    temp = Img - repmat(mean(Baseline,3),[1 1 size(Img,3)]);
    delF = temp./repmat(mean(Baseline,3),[1 1 size(Img,3)]);
%     delF = delF(:,:,21:end); %discard frames you used for baseline
    if ShiftMinToZero
        delF = delF+abs(min(delF(:))); %shift minimum to 0
        MindelF = min(delF(:));
    end
end
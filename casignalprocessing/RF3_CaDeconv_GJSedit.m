function [DeconvMat,FiltMat,FiltMat2]=RF3_CaDeconv_GJSedit(inmat,tau,thrup,pfilt,StrongSm,maxcount,tbin,butterfilt);


% inmat: input data: [Time x Neurons x Stimuli];
% tau: exponential time constant of kernel for deconv
% thrup: threshold for filtering, appropximately noise level, in % DF/F,
% normally between 0.5 and 5
% thrdc: set to 0
% pfilt: number of times for post-filtering, ie, filtering of whole trace
% after iterative filtering of segments around peaks. Normally 0.
% StrongSm: if 1, a slightly different smoothing algorkithm is used. This
% causes more distortions. Normally, set to 0.
% maxcount: maximum number of iterations in filter procedure. Normally 5000.
% tbin: frame time of input data in sec.
% butterfilt: cutoff frequency for butterworth filter. Usual settings:
% for preservation of fast signals, set to 0.38
% for stronger noise reduction, set to 0.27 (t-resolution reduced a bit)
% for strongest noise reduction, set to 0.16 (t-resolution reduced
% substantially)
% Example: CaDeconvShortRico(inmat,3,1,0,0,0,5000,0.256,0.2);


ntraces=size(inmat,1);
nodors=1; %size(inmat,3);


% FiltMat=inmat;
% FiltMat2=inmat;


% for a0=1:nodors,
%     disp(['Processing odor ',int2str(a0)]);
    Dmat=inmat';
    
    % First filtering step: butterworth
    
    if butterfilt>0,
        [B,A]=butter(4,butterfilt);
        for a1=1:ntraces,
            Dmat(:,a1)=filtfilt(B,A,Dmat(:,a1));
        end
    end
    
    FiltMat=Dmat;
    
    %Second filtering step: iterative filter
    
    if thrup>0,
        disp('smoothing...')
        parfor bb=1:ntraces
            Dmat(:,bb)=IterFilt2(Dmat(:,bb),thrup,pfilt,maxcount,StrongSm);
        end
        disp ('Done!');
    end
    FiltMat2=Dmat;
    
    % deconvolution
    
    if tau>0,
        Dmat=deconvtrace2(tau,tbin,Dmat,0);
    end
    inmat2=Dmat;
    
    
% end %for a0 loop
DeconvMat=inmat2'; 
function outmat=deconvtrace2(tconst,tbin,datamat,plotit)

%datamat=detrend(datamat);

matlength=size(datamat,1);

kernellength=round(2*tconst/tbin);
kernel1=(exp(-[0:kernellength-1]/(tconst/tbin)));
kernel2=abs(1-(exp(-[0:kernellength-1]/(tconst/(tbin*5)))));
kernel=kernel1.*kernel2;
kernel=kernel(2:length(kernel));

alength=kernellength;
if (size(datamat,1)<kernellength);
    alength=2*kernellength-size(datamat,1);
end
addmat=ones(alength,1)*ones(1,size(datamat,2));
datamat=[datamat;addmat];

kernel=kernel1;

if plotit,
figure;  
subplot(322);plot(kernel); %plot((0:kernellength-1)*tbin,kernel)
subplot(324);plot(kernel2);
subplot(323);plot(kernel1);
subplot(321); plot(datamat);
end

ntraces=length(datamat(1,:));
%outmat=zeros(size(datamat));
outmat=zeros(matlength,size(datamat,2));

for a1=1:ntraces
    [Q,R]=deconv(datamat(:,a1),kernel);
%     lengthdif=length(datamat(:,a1))-length(R);
    
%    outmat(1:length(Q),a1)=Q; 
   outmat(:,a1)=Q(1:matlength);
   
%     residuals(1:length(R),a1)=R;
end

%      if plotit
%      subplot(325);
%      plot(outmat(2:end,:)); hold on;
%      subplot(224);
%      plot(residuals(2:end,:)); hold on;
     
%      subplot(326); hold on;
%      test=conv(outmat(1:end,1),kernel);
%      plot(test(1:end),'r-');

%      subplot(222);
%      plot(outmat([1 3],:)); hold on;
%      subplot(224)
%      plot(residuals([1 3],:)); hold on;
%      
%      subplot(221); hold on;
%      test=conv(outmat([1 3],1),kernel);
%      plot(test([1 3]),'r-')

     end
% end

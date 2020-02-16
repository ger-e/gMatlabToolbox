function DMout=IterFilt2(Dmat,thrup,pfilt,maxcount,StrongSm)

minpeak=0.1;

% disp('smoothing...')
ntraces=size(Dmat,2);
for a1=1:ntraces,
    changed=1;
    count=1;
    lastpk=0;

    while ( (changed==1) && (count<=maxcount) ),
        [pospeaks,negpeaks]=peakdetect(Dmat(:,a1));
        if ( ~isempty(pospeaks) && ~isempty(negpeaks) )
            if (pospeaks(1)<negpeaks(1))
                peaks1=negpeaks;
                peaks2=pospeaks;
            else
                peaks1=pospeaks;
                peaks2=negpeaks;
            end
        else
            changed=0;
        end
        posindex=ones(size(pospeaks));
        negindex=ones(size(negpeaks));
        negindex=negindex*(-1);
        allindex=[posindex;negindex];
        allpeaks=[pospeaks;negpeaks];
        
%         stretch=find(allpeaks>=minpeak);
%         allindex=allindex(stretch);
%         allpeaks=allpeaks(stretch);
        
        if (length(allpeaks)==0)
            allpeaks=[1;allpeaks];
            if (Dmat(2,a1)<Dmat(1,a1)),
                allindex=[1;allindex];
            else
                allindex=[-1;allindex];
            end
        end

        if (allpeaks(1)>1),
            allpeaks=[1;allpeaks];
            if (Dmat(2,a1)<Dmat(1,a1)),
                allindex=[1;allindex];
            else
                allindex=[-1;allindex];
            end
        end
        if (allpeaks(length(allpeaks))<size(Dmat,1)),
            allpeaks=[allpeaks;size(Dmat,1)];
            if (Dmat(size(Dmat,1),a1)>Dmat(size(Dmat,1)-1,a1)),
                allindex=[allindex;1];
            else
                allindex=[allindex;-1];
            end
        end
        
        [allpeaks,sind]=sort(allpeaks,1); %CHECK: does allindex also have to be sorted??
        allindex=allindex(sind);
        %sort(allindex,1);

%         allamps=zeros(size(allpeaks));
%         for b1=2:(length(allamps)-1),
% %             allamps(b1)=( abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) ) + abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1+1),a1) ) ) /2;
% %             allamps(b1)=min( abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) ), abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1+1),a1) ) );
% %             allamps(b1)=max( abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) ), abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1+1),a1) ) );
%             allamps(b1)=abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) );
%         end
%         allamps(1)=abs(Dmat(1,a1)-Dmat(allpeaks(2),a1));
%         allamps(length(allpeaks))=abs(Dmat(size(Dmat,1))-Dmat(allpeaks(length(allpeaks)-1)));

        allamps=zeros(size(allpeaks));
        for b1=2:(length(allamps)),
%             allamps(b1)=( abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) ) + abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1+1),a1) ) ) /2;
%             allamps(b1)=min( abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) ), abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1+1),a1) ) );
%             allamps(b1)=max( abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) ), abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1+1),a1) ) );
            allamps(b1)=abs(Dmat(allpeaks(b1),a1) - Dmat(allpeaks(b1-1),a1) );
        end
        allamps(1)=abs(Dmat(1,a1)-Dmat(allpeaks(2),a1));
        allamps(1)=0;
        %allamps(length(allpeaks))=abs(Dmat(size(Dmat,1))-Dmat(allpeaks(length(allpeaks)-1)));
        
        
        
        %[allpeaks,allamps,Dmat(allpeaks,a1)]
        allamps2=allamps;
        [Y,allamps2ind]=sort(allamps2);
        allamps2=Y;

        count2=1;
        help3=0;
        take=0;
        %[allpeaks,allamps]

        while ( (count2<length(allamps2)) & (take==0) );
            help4=allamps2ind(count2);

            if StrongSm==0,
                %allamps2(count2)-allamps(help4)
                if ( (allamps(help4)<thrup) & (lastpk ~= allpeaks(help4)) & (allamps(help4) ~=0) ),
                %if ( (allamps(help4)<thrup) & (allamps(help4) ~=0) ),
                    take=1;
                end
            else
                if ( (allamps(help4)<thrup) & (lastpk ~= allpeaks(help4)) & (allindex(help4)==1) ),
                    take=1;
                elseif (allindex(help4)==(-1))
                    take=1;
                end
            end
            count2=count2+1;
        end %2nd while loop
        if (take==1),
            if (help4>1),
                if help4<length(allpeaks),
                    stretch=Dmat(allpeaks(help4-1):allpeaks(help4+1),a1);
                else
                    stretch=Dmat(allpeaks(help4-1):allpeaks(help4),a1);
                end
%                 disp([allpeaks(help4-1):allpeaks(help4+1)])
%                 
%                  allpeaks(help4)
%                 allpeaks
            else
                stretch=Dmat(allpeaks(help4):allpeaks(help4+1),a1);
            end
            if length(stretch)>0,
                stretch=itersmooth2(stretch,3);
            end
            if (help4>1),
                if help4<length(allpeaks),
                    Dmat(allpeaks(help4-1):allpeaks(help4+1),a1)=stretch;
                else
                    Dmat(allpeaks(help4-1):allpeaks(help4),a1)=stretch;
                end
            else
                Dmat(allpeaks(help4):allpeaks(help4+1),a1)=stretch;
            end



            lastpk=allpeaks(help4);
            changed=1;
        else
            changed=0;
        end
        count=count+1;
        
        stretch=find(abs(diff(Dmat(:,a1)))<1e-8);
        if length(stretch)>0;
            Dmat(stretch,a1)=Dmat(stretch,a1)+rand(size(stretch))*10e-6;
        end
        
%         allpeaks
%         lastpk
    end % 1st while loop
    if (pfilt>0),
        Dmat(:,a1)=itersmooth2(Dmat(:,a1),pfilt);
    end
end %for a1 loop
% disp ('Done!');
DMout=Dmat;
clear Dmat;

% function spineChanges(FileName)
function spineChanges(SpineChanges,ImgName)
% spineChanges.m
% 2/16/2010: Gerry wrote it
% 4/8/2010: Gerry modified to prevent overwriting artifacts

% spine patterns to analyze
SpinePatterns = zeros(5,3);
SpinePatterns(1,:) = [0 1 0]; % new
SpinePatterns(2,:) = [1 0 0]; % eliminated
SpinePatterns(3,:) = [1 1 0]; % stable
SpinePatterns(4,:) = [0 1 1]; % new
SpinePatterns(5,:) = [1 1 1]; % stable

SpinePatternsBgEnd = zeros(3,2);
SpinePatternsBgEnd(1,:) = [0 1]; % new
SpinePatternsBgEnd(2,:) = [1 0]; % eliminated
SpinePatternsBgEnd(3,:) = [1 1]; % stable

% use this if reading directly from Excel spreadsheet
% SpineChanges = xlsread('test.xls');
% SpineChanges = xlsread(FileName);
% SpineChanges(isnan(SpineChanges)) = 0;

% spine pattern results; note addition of one extra column at the end
PatternResults = zeros(size(SpineChanges,1),size(SpineChanges,2)-1);

% now find the patterns
for i=1:size(SpineChanges,1)
    for j=2:size(SpineChanges,2)
        if ~(j == size(SpineChanges,2))
            TestChanges = zeros(5,3);
            for k=1:size(SpinePatterns,1)
                TestChanges(k,:) = SpineChanges(i,j-1:j+1);
            end
            Test = (SpinePatterns == TestChanges);
            Test = sum(Test,2);
            PatternIdentity = find(Test == 3);
            if isempty(PatternIdentity)
                PatternIdentity = 0;
            end
            PatternResults(i,j) = PatternIdentity;
        end
        % special cases: beginning and end of the matrix
        % overwrite the previous beginning value and add a new value at the
        % end
        if j == 2 || j == size(SpineChanges,2)
            TestBgEnd = zeros(3,2);
            TestBgEnd(1,:) = SpineChanges(i,j-1:j);
            TestBgEnd(2,:) = SpineChanges(i,j-1:j);
            TestBgEnd(3,:) = SpineChanges(i,j-1:j);
            Test2 = (TestBgEnd == SpinePatternsBgEnd);
            Test2 = sum(Test2,2);
            PatternIdentityBgEnd = find(Test2 == 2);
            if isempty(PatternIdentityBgEnd)
                % no pattern to find, do nothing
            else
                PatternResults(i,j) = PatternIdentityBgEnd + 5;
            end
        end
    end
end

% make things look beautiful/interpretable
PatternResults(PatternResults == 3) = 255; % stable
PatternResults(PatternResults == 5) = 255; % stable
PatternResults(PatternResults == 2) = 100; % eliminated
PatternResults(PatternResults == 1) = 200; % new
PatternResults(PatternResults == 4) = 200; % new
PatternResults(PatternResults == 6) = 200; % new, at the beginning/end
PatternResults(PatternResults == 7) = 100; % eliminated, at the beginning/end
PatternResults(PatternResults == 8) = 255; % stable, at the beginning/end

% then count number of new, stable, or eliminated, per time point (column)
New = (PatternResults == 200);
New = sum(New,1);
Stable = (PatternResults == 255);
Stable = sum(Stable,1);
Eliminated = (PatternResults == 100);
Eliminated = sum(Eliminated,1);
NewStableEliminated = zeros(size(New,2),3);
NewStableEliminated(:,1) = New;
NewStableEliminated(:,2) = Stable;
NewStableEliminated(:,3) = Eliminated;

% output stuff
xlswrite([ImgName '.xls'],PatternResults,'PatternResults');
xlswrite([ImgName '.xls'],NewStableEliminated,'NewStableEliminated');
figure; imshow(uint8(PatternResults));
colormap('hot');

% 4/8/10 fix
% rename old image if it already exists to avoid overwriting artifacts
if exist([ImgName '.bmp'],'file')
    movefile([ImgName '.bmp'],[ImgName '_' num2str(sum(clock)) '.bmp']);
end

print('-dbitmap', ImgName);
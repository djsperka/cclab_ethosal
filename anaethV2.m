function [rates, logs] = anaethV2(results)
%anaethV2 Analyze ethological salience datasets. 
%   Input data is a results table. V2 refers to datasets with a single
%   response Yes/No = Change/NoChange. 

    rates = [];
    fig = [];

    % fix data is missing StimPairType. Assuming that Folder1Key and
    % Folder2Key exist!
    if ~ismember('sciTrialType', fieldnames(results))
        results.sciTrialType = strcat(results.Folder1Key, results.Folder2Key);
    end
    if ~ismember('AttendSide', fieldnames(results))
        results.AttendSide = zeros(height(results), 1);
    end

    % Neutral condition trials
    logs = ethlogs(results);
    rates = ethratesNone(results, logs);

    printRates(rates, 'NEUTRAL');

    % % Salience effect plot
    % figure;
    % fig = gcf;
    % Y=[rates.dpHH, rates.dpHL, rates.dpLL, rates.dpLH];
    % X=categorical({'HH', 'HL', 'LL', 'LH'});
    % X=reordercats(X, {'HH', 'HL', 'LL', 'LH'});
    % bar(X,Y);
    % ylim([-5,5]);
    % title('Salience effect');

end

function logs = ethlogs(A)
%ethlogs(A, attendedSide) Generate logical masks for analyzing data.


    %% logical indices that do not involve responses. These rely on trial paramters ONLY. 


    % These are just trial/stimulus types in the input trial list.
    % AND these with logs.completed and/or logs.correct for detection rates.    
    % The 'sci' indicates these are the "scientific" definitions of HH, HL,
    % etc.
    % In the etholog input parameters, the 'StimPairType' refers to the left-right
    % arrangement of the two stimuli: HL means HighSalience on left,
    % LowSalience on right, for example.
    % In the scientific discussions, the letter pairs have a slightly
    % different meaning: the first letter of the pair indicates which image
    % type changes. For example "HL" means that both high- and low-salience
    % images are on screen, and the high-salience image changes. No
    % information about which side of the screen each image resides on. In
    % analyzing the results, we fold the "attend-left" data and the
    % "attend-right" data together.
    % 
    % The logical indices below select out the trials according to those
    % "scientific" definitions.

    % Update 9/2024 djs
    % In V2 the stimuli may be generated with letters other than H and L. 
    % In the generator function, however, it is clear how to assign the 
    % type, and there is a fieldname 'sciTrialType'. 
    % TODO: this starts at a certain point in time, and older versions will
    % fail here. 

    % This is the original code....
    % logs.sciHH = ismember(A.StimPairType,{'HH'}) & ismember(A.StimChangeType,[1,2]);
    % logs.sciHL = (ismember(A.StimPairType, {'HL'}) & A.StimChangeType==1) | (ismember(A.StimPairType, {'LH'}) & A.StimChangeType==2);
    % logs.sciLH = (ismember(A.StimPairType, {'HL'}) & A.StimChangeType==2) | (ismember(A.StimPairType, {'LH'}) & A.StimChangeType==1);
    % logs.sciLL = ismember(A.StimPairType,{'LL'}) & ismember(A.StimChangeType,[1,2]);

    % this is the new V2 code that will fail for some older stuff and its a
    % TODO thing, ok? 
    logs.sciHH = ismember(A.sciTrialType,{'HH'}) & A.StimChangeTF;
    logs.sciHL = ismember(A.sciTrialType,{'HL'}) & A.StimChangeTF;
    logs.sciLH = ismember(A.sciTrialType,{'LH'}) & A.StimChangeTF;
    logs.sciLL = ismember(A.sciTrialType,{'LL'}) & A.StimChangeTF;



    % trials where there is no change - for HH, LL, and one of each.
    logs.sciHH0 = ismember(A.sciTrialType,{'HH'}) & ~A.StimChangeTF;
    logs.sciLL0 = ismember(A.sciTrialType,{'LL'}) & ~A.StimChangeTF;
    logs.sciHL0 = ismember(A.sciTrialType,{'HL'}) & ~A.StimChangeTF;
    logs.sciLH0 = ismember(A.sciTrialType,{'LH'}) & ~A.StimChangeTF;
    
    % These tell us if change happened on a given side.
    logs.changeLeft = A.StimChangeType==1;
    logs.changeRight = A.StimChangeType==2;
    logs.changeNone = A.StimChangeType==0;

    % DJS 9/2024 We use stim pairs, so left and right are not same image.
    %
    % % Is the same type on both sides - i.e. LL or HH?
    % logs.sameImages = ismember(A.StimPairType, {'HH', 'LL'});
    % logs.notSameImages = ismember(A.StimPairType, {'HL', 'LH'});

    % DJS 9/2024 Not doing any goal-directed attend left/right stuff.
    % % These tell if the attended-side contains a low- or high-salience
    % % image -- independent of whether it changes or not.
    % logs.attendToLow = (A.AttendSide==1 & ismember(A.StimPairType, {'LL', 'LH'})) | (A.AttendSide==2 & ismember(A.StimPairType, {'LL', 'HL'}));
    % logs.attendToHigh = (A.AttendSide==1 & ismember(A.StimPairType, {'HH', 'HL'})) | (A.AttendSide==2 & ismember(A.StimPairType, {'HH', 'LH'}));
    % 
    % % These will tell if the trial had a stim change, and that
    % % change happened on attended side or unattended side. 
    % logs.changeAttendedSide = (A.StimChangeType==A.AttendSide) & ismember(A.StimChangeType, [1,2]);
    % logs.changeUnattendedSide = (A.StimChangeType~=A.AttendSide) & ismember(A.StimChangeType, [1,2]) & ismember(A.AttendSide, [1,2]);

    % % Is test image on attended side?
    % logs.testIsAttendedSide = (A.StimTestType==A.AttendSide) & ismember(A.StimTestType, [1,2]);
    % logs.testIsUnattendedSide = (A.StimTestType~=A.AttendSide) & ismember(A.StimTestType, [1,2]) & ismember(A.AttendSide, [1,2]);

    % % Is the test image High or Low salience?
    % logs.testIsLow = (A.StimTestType==1 & ismember(A.StimPairType, {'LL', 'LH'})) | (A.StimTestType==2 & ismember(A.StimPairType, {'LL', 'HL'}));
    % logs.testIsHigh = (A.StimTestType==1 & ismember(A.StimPairType, {'HH', 'HL'})) | (A.StimTestType==2 & ismember(A.StimPairType, {'HH', 'LH'}));

    %% logical indices involving responses

    % completed and correct trials. 
    logs.completed = A.Started & A.tResp>0 & A.iResp>-1;
    logs.correct = logs.completed & A.StimChangeTF==A.iResp;
    

    % These indicate trials where the response was to the low-salience or
    % high-salience image
    % logs.responseLow = (A.iResp==1 & (ismember(A.StimPairType, {'LL', 'LH'}))) | (A.iResp==2 & (ismember(A.StimPairType, {'LL', 'HL'})));
    % logs.responseHigh = (A.iResp==1 & (ismember(A.StimPairType, {'HH', 'HL'}))) | (A.iResp==2 & (ismember(A.StimPairType, {'HH', 'LH'})));
    % 
    % % These indicate whether a response was to the attended side or not. 
    % logs.responseAttendedSide = (A.iResp==A.AttendSide) & (ismember(A.iResp, [1,2]));
    % logs.responseUnattendedSide = (A.iResp==1 & A.AttendSide==2) | (A.iResp==2 & A.AttendSide==1);
end



function rates = ethratesNone(A, logs)
%ethrates(A, logs, subset) Compute rates for the trials and logical masks
%given. The subset can be used to define a subset of the trials defined in
%the logs. 
    arguments
        A table
        logs struct
    end

    % Get detection rates. 
    % Reminder: logs.correct implies logs.completed
    rates.ncorrectHH = sum(logs.sciHH & logs.correct);
    rates.ncompletedHH = sum(logs.sciHH & logs.completed);
    rates.drateHH = rates.ncorrectHH/rates.ncompletedHH;

    rates.ncorrectHL = sum(logs.sciHL & logs.correct);
    rates.ncompletedHL = sum(logs.sciHL & logs.completed);
    rates.drateHL = rates.ncorrectHL/rates.ncompletedHL;

    rates.ncorrectLH = sum(logs.sciLH & logs.correct);
    rates.ncompletedLH = sum(logs.sciLH & logs.completed);
    rates.drateLH = rates.ncorrectLH/rates.ncompletedLH;

    rates.ncorrectLL = sum(logs.sciLL & logs.correct);
    rates.ncompletedLL = sum(logs.sciLL & logs.completed);
    rates.drateLL = rates.ncorrectLL/rates.ncompletedLL;

    % avg reaction time for correct trials
    rates.treactHH = sum(A{logs.sciHH & logs.correct,"tResp"}-A{logs.sciHH & logs.correct,"tBon"})/sum(logs.sciHH & logs.correct);
    rates.treactHL = sum(A{logs.sciHL & logs.correct,"tResp"}-A{logs.sciHL & logs.correct,"tBon"})/sum(logs.sciHL & logs.correct);
    rates.treactLH = sum(A{logs.sciLH & logs.correct,"tResp"}-A{logs.sciLH & logs.correct,"tBon"})/sum(logs.sciLH & logs.correct);
    rates.treactLL = sum(A{logs.sciLL & logs.correct,"tResp"}-A{logs.sciLL & logs.correct,"tBon"})/sum(logs.sciLL & logs.correct);
    
    % false alarm rate on no-change trials. Use logs.sciHH0, logs.sciLL0, and
    % logs.sciLHHL0.
    %
    % When "LH0" is used, it means a trial where both L,H are shown, L IS TEST IMAGE, 
    % no change, but L was chosen. 
    % 
    % Similarly, "HL0" means a trial where both L,H are shown, no change,
    % but H was chosen.

    rates.nincorrectHH0 = sum(logs.sciHH0 & logs.completed & ~logs.correct);
    rates.ncompletedHH0 = sum(logs.sciHH0 & logs.completed);
    rates.frateHH0 = rates.nincorrectHH0/rates.ncompletedHH0;

    rates.nincorrectLL0 = sum(logs.sciLL0 & logs.completed & ~logs.correct);
    rates.ncompletedLL0 = sum(logs.sciLL0 & logs.completed);
    rates.frateLL0 = rates.nincorrectLL0/rates.ncompletedLL0;

    % DJS 9/2024. sci types are fixes so the old logic not required.
    % rates.nincorrectLH0 = sum(logs.sciLHHL0 & logs.testIsLow &  logs.changeNone & logs.completed & logs.responseLow);
    % rates.ncompletedLH0 = sum(logs.sciLHHL0 & logs.testIsLow & logs.changeNone & logs.completed);
    % rates.frateLH0 = rates.nincorrectLH0/rates.ncompletedLH0;
    % 
    % rates.nincorrectHL0 = sum(logs.sciLHHL0 & logs.testIsHigh &  logs.changeNone & logs.completed & logs.responseHigh);
    % rates.ncompletedHL0 = sum(logs.sciLHHL0 &  logs.testIsHigh & logs.changeNone & logs.completed);
    % rates.frateHL0 = rates.nincorrectHL0/rates.ncompletedHL0;

    rates.nincorrectLH0 = sum(logs.sciLH0 & logs.completed & ~logs.correct);
    rates.ncompletedLH0 = sum(logs.sciLH0 & logs.completed);
    rates.frateLH0 = rates.nincorrectLH0/rates.ncompletedLH0;

    rates.nincorrectHL0 = sum(logs.sciHL0 & logs.completed & ~logs.correct);
    rates.ncompletedHL0 = sum(logs.sciHL0 & logs.completed);
    rates.frateHL0 = rates.nincorrectHL0/rates.ncompletedHL0;

    % dprime values;
    %fprintf('min %f max %f\n', min(0.99, rates.drateHH), max(0.01, rates.frateHH0));
    [rates.dpHH, rates.cHH] = dprime_simple(min(0.99, rates.drateHH), max(0.01, rates.frateHH0));
    %fprintf('Done\n');
    [rates.dpHL, rates.cHL] = dprime_simple(min(0.99, rates.drateHL), max(0.01, rates.frateHL0));
    [rates.dpLH, rates.cLH] = dprime_simple(min(0.99, rates.drateLH), max(0.01, rates.frateLH0));
    [rates.dpLL, rates.cLL] = dprime_simple(min(0.99, rates.drateLL), max(0.01, rates.frateLL0));

end









function printRates(rates, label)
    fprintf(1,'%s Correct detection\ntype\trate\tncorr/ntot\trxtime(s)\n', label);
    fprintf(1,'HH\t%.2f\t%d/%d\t%.3f\n', rates.drateHH, rates.ncorrectHH, rates.ncompletedHH, rates.treactHH);
    fprintf(1,'HL\t%.2f\t%d/%d\t%.3f\n', rates.drateHL, rates.ncorrectHL, rates.ncompletedHL, rates.treactHL);
    fprintf(1,'LH\t%.2f\t%d/%d\t%.3f\n', rates.drateLH, rates.ncorrectLH, rates.ncompletedLH, rates.treactLH);
    fprintf(1,'LL\t%.2f\t%d/%d\t%.3f\n', rates.drateLL, rates.ncorrectLL, rates.ncompletedLL, rates.treactLL);
    fprintf(1,'\n');
    fprintf(1, 'False alarms\ntype\trate\tnincorr/ntot\n');
    fprintf(1, 'HH  \t%.2f\t%d/%d\n', rates.frateHH0, rates.nincorrectHH0, rates.ncompletedHH0);
    fprintf(1, 'HL  \t%.2f\t%d/%d\n', rates.frateHL0, rates.nincorrectHL0, rates.ncompletedHL0);
    fprintf(1, 'LH  \t%.2f\t%d/%d\n', rates.frateLH0, rates.nincorrectLH0, rates.ncompletedLH0);
    fprintf(1, 'LL  \t%.2f\t%d/%d\n', rates.frateLL0, rates.nincorrectLL0, rates.ncompletedLL0);
end
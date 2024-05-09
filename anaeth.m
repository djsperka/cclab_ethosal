zLeft = load('/home/dan/git/cclab_ethosal/output/jodi-240-b.mat');
zRight = load('/home/dan/git/cclab_ethosal/output/jodi-240-c.mat');
zNeutral=load('/home/dan/git/cclab_ethosal/output/jodi-240-d.mat');
inputs=load('/home/dan/git/cclab_ethosal/input/contrast_60images_a.mat');



% Neutral condition trials
A=horzcat(inputs.blocks{3},zNeutral.results);
Nlogs = ethlogs(A);
Nrates = ethrates(A, Nlogs);
printRates(Nrates, 'NEUTRAL');


% Attend-left condition trials
L=horzcat(inputs.blocks{1},zLeft.results);
Llogs = ethlogs(L);

% Attend-right condition trials
R=horzcat(inputs.blocks{2},zRight.results);
Rlogs = ethlogs(R);

LratesIN = ethrates(L, Llogs, Llogs.changeLeft);
printRates(LratesIN, 'Left-IN');
LratesOUT = ethrates(L, Llogs, Llogs.changeRight);
printRates(LratesOUT, 'Left-OUT');





function logs = ethlogs(A)
    % completed trials, and correct trials. Note that logCorrect implies that a
    % trial was also completed. That means we can AND logCorrect with any of
    % the the trial types below (logSciHH, logSciHL, ...)
    logs.completed = A.Started & A.tResp>0;
    logs.correct = logs.completed & A.StimChangeType==A.iResp;
    
    % These are just trial/stimulus types in the input trial list.
    % AND these with logs.completed and/or logs.correct for detection rates.
    
    logs.sciHH = ismember(A.StimPairType,{'HH'}) & ismember(A.StimChangeType,[1,2]);
    logs.sciHL = (ismember(A.StimPairType, {'HL'}) & A.StimChangeType==1) | (ismember(A.StimPairType, {'LH'}) & A.StimChangeType==2);
    logs.sciLH = (ismember(A.StimPairType, {'HL'}) & A.StimChangeType==2) | (ismember(A.StimPairType, {'LH'}) & A.StimChangeType==1);
    logs.sciLL = ismember(A.StimPairType,{'LL'}) & ismember(A.StimChangeType,[1,2]);
    logs.sciHH0 = ismember(A.StimPairType, {'HH'}) & A.StimChangeType==0;
    logs.sciLL0 = ismember(A.StimPairType, {'LL'}) & A.StimChangeType==0;
    logs.sciLHHL0 = ismember(A.StimPairType, {'LH','HL'}) & A.StimChangeType==0;
    
    % These are used to get attention-in and attention-out, but only tell us if
    % change happened on either side. 
    
    logs.changeLeft = A.StimChangeType==1;
    logs.changeRight = A.StimChangeType==2;
    logs.changeNone = A.StimChangeType==0;
end

function rates = ethrates(A, logs, subset)
    arguments
        A table
        logs struct
        subset {mustBeNumericOrLogical} = []
    end

    if isempty(subset)
        subset = true(size(logs.completed));
    end

    % Get detection rates
    rates.drateHH = sum(logs.sciHH & subset & logs.correct)/sum(logs.sciHH & subset & logs.completed);
    rates.drateHL = sum(logs.sciHL & subset & logs.correct)/sum(logs.sciHL & subset & logs.completed);
    rates.drateLH = sum(logs.sciLH & subset & logs.correct)/sum(logs.sciLH & subset & logs.completed);
    rates.drateLL = sum(logs.sciLL & subset & logs.correct)/sum(logs.sciLL & subset & logs.completed);

    % avg reaction time for correct trials
    rates.treactHH = sum(A{logs.sciHH & subset & logs.correct,"tResp"}-A{logs.sciHH & subset & logs.correct,"tBon"})/sum(logs.sciHH & subset & logs.correct);
    rates.treactHL = sum(A{logs.sciHL & subset & logs.correct,"tResp"}-A{logs.sciHL & subset & logs.correct,"tBon"})/sum(logs.sciHL & subset & logs.correct);
    rates.treactLH = sum(A{logs.sciLH & subset & logs.correct,"tResp"}-A{logs.sciLH & subset & logs.correct,"tBon"})/sum(logs.sciLH & subset & logs.correct);
    rates.treactLL = sum(A{logs.sciLL & subset & logs.correct,"tResp"}-A{logs.sciLL & subset & logs.correct,"tBon"})/sum(logs.sciLL & subset & logs.correct);
    
    % false alarm rate on no-change trials. Use logs.sciHH0, logs.sciLL0, and
    % logs.sciLHHL0
    rates.frateHH0 = sum(logs.sciHH0 & logs.changeNone & ~logs.correct)/sum(logs.sciHH0 & logs.changeNone & logs.completed);
    rates.frateLL0 = sum(logs.sciLL0 & logs.changeNone & ~logs.correct)/sum(logs.sciLL0 & logs.changeNone & logs.completed);
    rates.frateLHHL0 = sum(logs.sciLHHL0 & logs.changeNone & ~logs.correct)/sum(logs.sciLHHL0 & logs.changeNone & logs.completed);
end

function printRates(rates, label)
    fprintf(1,'%s Correct detection\ntype\trate\trxtime(s)\n', label);
    fprintf(1,'HH\t%.2f\t%.3f\n', rates.drateHH, rates.treactHH);
    fprintf(1,'HL\t%.2f\t%.3f\n', rates.drateHL, rates.treactHL);
    fprintf(1,'LH\t%.2f\t%.3f\n', rates.drateLH, rates.treactLH);
    fprintf(1,'LL\t%.2f\t%.3f\n', rates.drateLL, rates.treactLL);
    fprintf(1,'\n');
    fprintf(1, 'False alarms\ntype\trate\n');
    fprintf(1, 'HH\t%.2f\n', rates.frateHH0);
    fprintf(1, 'LHHL\t%.2f\n', rates.frateLHHL0);
    fprintf(1, 'LL\t%.2f\n', rates.frateLL0);
end
function [ratesNone, ratesAttended, fig] = anaeth(varargin)
%anaeth Generate rates for ethological salience datasets. 
%   Input data is table of trials. If a single table, just do no-attend. 

    ratesNone = [];
    ratesAttended = [];
    fig = [];
    switch nargin
        case {1,2}
            bHaveLR = false;
            attendNone = varargin{1};
            if ~ismember('AttendSide', fieldnames(attendNone))
                attendNone.AttendSide = zeros(height(attendNone), 1);
            end
            if nargin==2
                figtitle = varargin{2};
                doPlot = true;
            else
                doPlot = false;
            end
        case {3,4}
            bHaveLR = true;
            attendLeft = varargin{1};
            % add attend side to data if it doesn't already exist.
            if ~ismember('AttendSide', fieldnames(attendLeft))
                attendLeft.AttendSide = ones(height(attendLeft), 1);
            end
            attendRight = varargin{2};
            if ~ismember('AttendSide', fieldnames(attendRight))
                attendRight.AttendSide = 2*ones(height(attendRight), 1);
            end
            attendNone = varargin{3};
            if ~ismember('AttendSide', fieldnames(attendNone))
                attendNone.AttendSide = zeros(height(attendNone), 1);
            end
            if nargin==4
                figtitle = varargin{4};
                doPlot = true;
            else
                doPlot = false;
            end

        otherwise
            error('Must have 2 or 4 args');
    end

    % Neutral condition trials
    logsNone = ethlogs(attendNone);
    ratesNone = ethratesNone(attendNone, logsNone);

    %printRates(ratesNone, 'NEUTRAL');

    % Salience effect plot
    if doPlot
        figure;
        fig = gcf;
        if bHaveLR
            subplot(2,1,1);
        end
        Y=[ratesNone.dpHH, ratesNone.dpHL, ratesNone.dpLL, ratesNone.dpLH];
        X=categorical({'HH', 'HL', 'LL', 'LH'});
        X=reordercats(X, {'HH', 'HL', 'LL', 'LH'});
        bar(X,Y);
        ylim([-5,5]);
        title('Salience effect');
    end

    % Congruence.
    % Using notation h,H to mean high salience without,with attention.
    % In the grant proposal (Aim 3), the notation uses a different-colored
    % letter to signify the attended image.
    % hH = both hi-salience images, unattended changes
    % Hh = both hi-salience images, attended changes
    % Hl = hi- and low-salience, hi-salience is attended, attended changes
    % hL = hi- and low-salience, hi-salience is attended, unattended changes
    % lL = both low-salience images, unattended changes

    % Stack Attend-left condition trials on top of attend-right trials. The
    % masks should be used to isolate the attendLeft or attendRight.

    % Hack - skip this if no LR data
    ratesAttended = [];
    if bHaveLR
    
        LR = [attendLeft;attendRight];
        logsLR = ethlogs(LR);
        ratesAttended = ethratesAttended(LR, logsLR);
    
%         YCong = [   dprime_simple(ratesAttended.dratehH, ratesAttended.fratehH0) - dprime_simple(ratesAttended.drateHh, ratesAttended.frateHh0), ...
%                 dprime_simple(ratesAttended.dratehL, ratesAttended.fratehL0) - dprime_simple(ratesAttended.drateHl, ratesAttended.frateHl0), ...
%                 dprime_simple(ratesAttended.dratelL, ratesAttended.fratelL0) - dprime_simple(ratesAttended.drateLl, ratesAttended.frateLl0), ...
%                 dprime_simple(ratesAttended.dratelH, ratesAttended.fratelH0) - dprime_simple(ratesAttended.drateLh, ratesAttended.frateLh0) ];
    
        Y01Cong = [ dprime_simple(min(0.99, ratesAttended.dratehH), max(0.01, ratesAttended.fratehH0)) - dprime_simple(min(0.99, ratesAttended.drateHh), max(0.01, ratesAttended.frateHh0)), ...
                dprime_simple(min(0.99, ratesAttended.dratehL), max(0.01, ratesAttended.fratehL0)) - dprime_simple(min(0.99, ratesAttended.drateHl), max(0.01, ratesAttended.frateHl0)), ...
                dprime_simple(min(0.99, ratesAttended.dratelL), max(0.01, ratesAttended.fratelL0)) - dprime_simple(min(0.99, ratesAttended.drateLl), max(0.01, ratesAttended.frateLl0)), ...
                dprime_simple(min(0.99, ratesAttended.dratelH), max(0.01, ratesAttended.fratelH0)) - dprime_simple(min(0.99, ratesAttended.drateLh), max(0.01, ratesAttended.frateLh0)) ];
    

        if doPlot

            XCong = categorical({'hH-Hh', 'hL-Hl', 'lL-Ll', 'lH-Lh'});
            XCong = reordercats(XCong, {'hH-Hh', 'hL-Hl', 'lL-Ll', 'lH-Lh'});
        
            subplot(2,1,2);
            bar(XCong, Y01Cong);
            ylim([-2,2]);
            title('Congruence');
    
        end
        %printRates(ratesAttended,'Attended');

    end
    if doPlot
        sgtitle(figtitle);
    end
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

    logs.sciHH = ismember(A.StimPairType,{'HH'}) & ismember(A.StimChangeType,[1,2]);
    logs.sciHL = (ismember(A.StimPairType, {'HL'}) & A.StimChangeType==1) | (ismember(A.StimPairType, {'LH'}) & A.StimChangeType==2);
    logs.sciLH = (ismember(A.StimPairType, {'HL'}) & A.StimChangeType==2) | (ismember(A.StimPairType, {'LH'}) & A.StimChangeType==1);
    logs.sciLL = ismember(A.StimPairType,{'LL'}) & ismember(A.StimChangeType,[1,2]);

    % trials where there is no change - for HH, LL, and one of each.
    logs.sciHH0 = ismember(A.StimPairType, {'HH'}) & A.StimChangeType==0;
    logs.sciLL0 = ismember(A.StimPairType, {'LL'}) & A.StimChangeType==0;
    logs.sciLHHL0 = ismember(A.StimPairType, {'LH','HL'}) & A.StimChangeType==0;
    
    % These tell us if change happened on a given side.
    logs.changeLeft = A.StimChangeType==1;
    logs.changeRight = A.StimChangeType==2;
    logs.changeNone = A.StimChangeType==0;

    % Is the same type on both sides - i.e. LL or HH?
    logs.sameImages = ismember(A.StimPairType, {'HH', 'LL'});
    logs.notSameImages = ismember(A.StimPairType, {'HL', 'LH'});

    % These tell if the attended-side contains a low- or high-salience
    % image -- independent of whether it changes or not.
    logs.attendToLow = (A.AttendSide==1 & ismember(A.StimPairType, {'LL', 'LH'})) | (A.AttendSide==2 & ismember(A.StimPairType, {'LL', 'HL'}));
    logs.attendToHigh = (A.AttendSide==1 & ismember(A.StimPairType, {'HH', 'HL'})) | (A.AttendSide==2 & ismember(A.StimPairType, {'HH', 'LH'}));

    % These will tell if the trial had a stim change, and that
    % change happened on attended side or unattended side. 
    logs.changeAttendedSide = (A.StimChangeType==A.AttendSide) & ismember(A.StimChangeType, [1,2]);
    logs.changeUnattendedSide = (A.StimChangeType~=A.AttendSide) & ismember(A.StimChangeType, [1,2]) & ismember(A.AttendSide, [1,2]);

    % Is test image on attended side?
    logs.testIsAttendedSide = (A.StimTestType==A.AttendSide) & ismember(A.StimTestType, [1,2]);
    logs.testIsUnattendedSide = (A.StimTestType~=A.AttendSide) & ismember(A.StimTestType, [1,2]) & ismember(A.AttendSide, [1,2]);

    % Is the test image High or Low salience?
    logs.testIsLow = (A.StimTestType==1 & ismember(A.StimPairType, {'LL', 'LH'})) | (A.StimTestType==2 & ismember(A.StimPairType, {'LL', 'HL'}));
    logs.testIsHigh = (A.StimTestType==1 & ismember(A.StimPairType, {'HH', 'HL'})) | (A.StimTestType==2 & ismember(A.StimPairType, {'HH', 'LH'}));

    %% logical indices involving responses

    % completed and correct trials. 
    logs.completed = A.Started & A.tResp>0 & A.iResp>-1;
    logs.correct = logs.completed & A.StimChangeType==A.iResp;
    

    % These indicate trials where the response was to the low-salience or
    % high-salience image
    logs.responseLow = (A.iResp==1 & (ismember(A.StimPairType, {'LL', 'LH'}))) | (A.iResp==2 & (ismember(A.StimPairType, {'LL', 'HL'})));
    logs.responseHigh = (A.iResp==1 & (ismember(A.StimPairType, {'HH', 'HL'}))) | (A.iResp==2 & (ismember(A.StimPairType, {'HH', 'LH'})));

    % These indicate whether a response was to the attended side or not. 
    logs.responseAttendedSide = (A.iResp==A.AttendSide) & (ismember(A.iResp, [1,2]));
    logs.responseUnattendedSide = (A.iResp==1 & A.AttendSide==2) | (A.iResp==2 & A.AttendSide==1);
end

function rates = ethratesAttended(A, logs)
%ethrates(A, logs, subset) Compute rates for the trials and logical masks
%given. The subset can be used to define a subset of the trials defined in
%the logs. 
    arguments
        A table
        logs struct
    end

    % Reminder: When using "H" and "L" here, it means the same as in the
    % no-attended data. When using "h" and "l" (lower case), it means that
    % stim is on the attended side. In the proposal, a different color is
    % used to indicate which stim was attended. Can't have multi-colored
    % text here, so I use lowercase to indicate which is attended. There
    % will only be one lower-case and one upper-case letter/stimulus for
    % all trials in the attended data. 
    % As with the no-change data, whenever two letters are used, the first 
    % letter indicates the stimulus that changes. 
    % When we consider false alarms, we are working with trials where there
    % is no change. The notation we use for false alarms will indicate the
    % RESPONSE (incorrect) that the subject chose.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % hH: both hi-salience, attended changes
    rates.ncompletedhH = sum(logs.completed & logs.sciHH & logs.changeAttendedSide);
    rates.ncorrecthH = sum(logs.completed & logs.sciHH & logs.changeAttendedSide & logs.correct);
    rates.dratehH = rates.ncorrecthH/rates.ncompletedhH;

    % FA hH0: both hi-salience, no change, response to attended
    rates.ncompletedhH0 = sum(logs.completed & logs.sciHH0 & logs.testIsAttendedSide);
    rates.nincorrecthH0 = sum(logs.completed & logs.sciHH0 & logs.testIsAttendedSide & logs.responseAttendedSide);
    rates.fratehH0 = rates.nincorrecthH0/rates.ncompletedhH0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Hh: both hi-salience, test unattended, unattended changes
    rates.ncompletedHh = sum(logs.completed & logs.sciHH & logs.testIsUnattendedSide & logs.changeUnattendedSide);
    rates.ncorrectHh = sum(logs.completed & logs.sciHH & logs.testIsUnattendedSide & logs.changeUnattendedSide & logs.correct);
    rates.drateHh = rates.ncorrectHh/rates.ncompletedHh;

    % FA Hh0: both hi-salience, no change, response to unattended
    rates.ncompletedHh0 = sum(logs.completed & logs.sciHH0 & logs.testIsUnattendedSide);
    rates.nincorrectHh0 = sum(logs.completed & logs.sciHH0 & logs.testIsUnattendedSide & logs.responseUnattendedSide);
    rates.frateHh0 = rates.nincorrectHh0/rates.ncompletedHh0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % lL: both low-salience, attended changes
    rates.ncompletedlL = sum(logs.completed & logs.sciLL & logs.changeAttendedSide);
    rates.ncorrectlL = sum(logs.completed & logs.sciLL & logs.changeAttendedSide & logs.correct);
    rates.dratelL = rates.ncorrectlL/rates.ncompletedlL;

    % FA lL0: both low-salience, no change, response to attended
    rates.ncompletedlL0 = sum(logs.completed & logs.sciLL0  & logs.testIsAttendedSide);
    rates.nincorrectlL0 = sum(logs.completed & logs.sciLL0 & logs.testIsAttendedSide & logs.responseAttendedSide);
    rates.fratelL0 = rates.nincorrectlL0/rates.ncompletedlL0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ll: both low-salience, unattended changes
    rates.ncompletedLl = sum(logs.completed & logs.sciLL & logs.changeUnattendedSide);
    rates.ncorrectLl = sum(logs.completed & logs.sciLL & logs.changeUnattendedSide & logs.correct);
    rates.drateLl = rates.ncorrectLl/rates.ncompletedLl;

    % FA Ll0: both low-salience, no change, response to unattended
    rates.ncompletedLl0 = sum(logs.completed & logs.sciLL0  & logs.testIsUnattendedSide);
    rates.nincorrectLl0 = sum(logs.completed & logs.sciLL0 & logs.testIsUnattendedSide & logs.responseUnattendedSide);
    rates.frateLl0 = rates.nincorrectLl0/rates.ncompletedLl0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % hL: one of each, attended is hi-salience, Test is attended, attended changes
    rates.ncompletedhL = sum(logs.completed & logs.sciHL & logs.attendToHigh & logs.changeAttendedSide);    % changeAttendedSide is redundant
    rates.ncorrecthL = sum(logs.completed & logs.sciHL & logs.attendToHigh & logs.changeAttendedSide & logs.correct);
    rates.dratehL = rates.ncorrecthL/rates.ncompletedhL;

    % FA hL0: one of each, no change, attended AND TEST is hi-salience, response to
    % attended
    rates.ncompletedhL0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToHigh & logs.testIsHigh);
    rates.nincorrecthL0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToHigh & logs.testIsHigh & logs.responseAttendedSide);
    rates.fratehL0 = rates.nincorrecthL0/rates.ncompletedhL0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lh: one of each, attended is hi-salience, unattended changes
    % (logs.testIsLow is redundant here, because
    % attendToHigh&changeUnattendedSide implies testIsLow)
    rates.ncompletedLh = sum(logs.completed & logs.sciLH & logs.attendToHigh & logs.changeUnattendedSide);    % changeUnattendedSide is redundant
    rates.ncorrectLh = sum(logs.completed & logs.sciLH & logs.attendToHigh & logs.changeUnattendedSide & logs.correct);
    rates.drateLh = rates.ncorrectLh/rates.ncompletedLh;

    % FA Lh0: one of each, no change, attended is hi-salience, test is low, response to
    % unattended
    rates.ncompletedLh0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToHigh & logs.testIsLow);
    rates.nincorrectLh0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToHigh & logs.testIsLow & logs.responseUnattendedSide);
    rates.frateLh0 = rates.nincorrectLh0/rates.ncompletedLh0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % lH: one of each, attended is low-salience, attended changes
    rates.ncompletedlH = sum(logs.completed & logs.sciLH & logs.attendToLow & logs.changeAttendedSide);    % changeAttendedSide is redundant
    rates.ncorrectlH = sum(logs.completed & logs.sciLH & logs.attendToLow & logs.changeAttendedSide & logs.correct);
    rates.dratelH = rates.ncorrectlH/rates.ncompletedlH;

    % FA lH0: one of each, no change, attended is low-salience, response to
    % attended
    rates.ncompletedlH0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToLow & logs.testIsLow);
    rates.nincorrectlH0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToLow & logs.testIsLow & logs.responseAttendedSide);
    rates.fratelH0 = rates.nincorrectlH0/rates.ncompletedlH0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Hl: one of each, attended is low-salience, unattended changes
    rates.ncompletedHl = sum(logs.completed & logs.sciHL & logs.attendToLow & logs.changeUnattendedSide);    % changeUnattendedSide is redundant
    rates.ncorrectHl = sum(logs.completed & logs.sciHL & logs.attendToLow & logs.changeUnattendedSide & logs.correct);
    rates.drateHl = rates.ncorrectHl/rates.ncompletedHl;

    % FA Hl0: one of each, no change, attended is low-salience, response to
    % unattended
    rates.ncompletedHl0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToLow & logs.testIsHigh);
    rates.nincorrectHl0 = sum(logs.completed & logs.sciLHHL0 & logs.attendToLow & logs.testIsHigh & logs.responseUnattendedSide);
    rates.frateHl0 = rates.nincorrectHl0/rates.ncompletedHl0;




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

    rates.nincorrectHH0 = sum(logs.sciHH0 & logs.changeNone & logs.completed & ~logs.correct);
    rates.ncompletedHH0 = sum(logs.sciHH0 & logs.changeNone & logs.completed);
    rates.frateHH0 = rates.nincorrectHH0/rates.ncompletedHH0;

    rates.nincorrectLL0 = sum(logs.sciLL0 & logs.changeNone & logs.completed & ~logs.correct);
    rates.ncompletedLL0 = sum(logs.sciLL0 & logs.changeNone & logs.completed);
    rates.frateLL0 = rates.nincorrectLL0/rates.ncompletedLL0;

    rates.nincorrectLH0 = sum(logs.sciLHHL0 & logs.testIsLow &  logs.changeNone & logs.completed & logs.responseLow);
    rates.ncompletedLH0 = sum(logs.sciLHHL0 & logs.testIsLow & logs.changeNone & logs.completed);
    rates.frateLH0 = rates.nincorrectLH0/rates.ncompletedLH0;

    rates.nincorrectHL0 = sum(logs.sciLHHL0 & logs.testIsHigh &  logs.changeNone & logs.completed & logs.responseHigh);
    rates.ncompletedHL0 = sum(logs.sciLHHL0 &  logs.testIsHigh & logs.changeNone & logs.completed);
    rates.frateHL0 = rates.nincorrectHL0/rates.ncompletedHL0;

    % rates.nincorrectLHHL0 = sum(logs.sciLHHL0 & logs.changeNone & logs.completed & ~logs.correct);
    % rates.ncompletedLHHL0 = sum(logs.sciLHHL0 & logs.changeNone & logs.completed);
    % rates.frateLHHL0 = rates.nincorrectLHHL0/rates.ncompletedLHHL0;

    % dprime values;
    [rates.dpHH, rates.cHH] = dprime_simple(min(0.99, rates.drateHH), max(0.01, rates.frateHH0));
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
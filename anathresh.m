function [outputArg1,outputArg2] = anaresults(trials, results, deltas)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


    % results for completed trials only
    resultsCompleted = results(results.trialIndex(results.Started & results.tResp>0), :);

    % same, from trials
    trialsCompleted=trials(resultsCompleted.trialIndex, {'ImageKey', 'LType', 'RType', 'Stim1Key', 'Stim2Key', 'Base', 'Delta', 'StimChangeType'});

    % combine them all into a single table
    rtCompleted = horzcat(resultsCompleted, trialsCompleted);
    rtCompleted.Correct = rtCompleted.StimChangeType==rtCompleted.iResp;
    fprintf('%d trials completed\n', height(rtCompleted));

    % from that table, get logical indices for each Delta value
    logByDelta = (rtCompleted.Delta == deltas);
    pctByDelta = zeros(1, length(deltas));
    sumByDelta = sum(logByDelta);
    for i=1:length(deltas)
        if sumByDelta(i) > 0
            pctByDelta(i) = sum(rtCompleted.Correct(logByDelta(:,i)))/sumByDelta(i);
        end
    end

    fprintf(1, 'Delta\tN\tCorrect\n');
    for i=1:length(deltas)
        fprintf(1, '%f\t%d\t%f\n', deltas(i), sumByDelta(i), pctByDelta(i));
    end
end
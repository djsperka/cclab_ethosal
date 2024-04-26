function [outputArg1,outputArg2] = anaetholog(trials, results)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


    % results for completed trials only
    resultsCompleted = results(results.trialIndex(results.Started & results.tResp>0), :);

    % same, from trials
    trialsCompleted=trials(resultsCompleted.trialIndex, {'StimPairType', 'Stim1Key', 'Stim2Key', 'Base', 'Delta', 'StimChangeType'});

    % combine them all into a single table
    rtCompleted = horzcat(resultsCompleted, trialsCompleted);
    rtCompleted.Correct = rtCompleted.StimChangeType==rtCompleted.iResp;
    fprintf('%d trials completed\n', height(rtCompleted));

%   from that table, get logical indices for each stim pair type
    stimPairTypes = ["HH","HL","LH","LL"];
    trialPairTypes = string(rtCompleted.StimPairType);
    logByPairType = (trialPairTypes == stimPairTypes);  % each column is logical for "am I the same type as the column in stimPairTypes"?
    pctByPairType = zeros(1, length(stimPairTypes));
    sumByPairType = sum(logByPairType);
    for i=1:length(stimPairTypes)
        if sumByPairType(i) > 0
            pctByPairType(i) = sum(rtCompleted.Correct(logByPairType(:,i)))/sumByPairType(i);
        end
    end
 
    fprintf(1, 'Type\tN\tCorrect\n');
    for i=1:length(stimPairTypes)
        fprintf(1, '%s\t%d\t%f\n', stimPairTypes(i), sumByPairType(i), pctByPairType(i));
    end

end
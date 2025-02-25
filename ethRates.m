function [rates] = ethRates(R)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % completed and correct trials. 
    logs.started = R.Started;
    logs.failed = R.Started & (R.tResp < 0 | R.iResp < 0);
    logs.completed = R.Started & R.tResp>0 & R.iResp>-1;
    logs.correct = logs.completed & R.StimChangeTF==R.iResp;
    logs.attendIn = (R.StimChangeType == R.CueSide);
    logs.attendOut = (R.StimChangeType ~= R.CueSide);

    % rates for all trials
    if sum(logs.completed) > 0
        rates.correctPct = sum(logs.correct)/sum(logs.completed);
        rates.treact = sum(R{logs.correct,"tResp"}-R{logs.correct,"tBon"})/sum(logs.completed);
    else
        rates.correctPct = 0;
        rates.treact = 0;
    end

    if sum(logs.attendIn & logs.completed) > 0
        rates.correctInPct = sum(logs.attendIn & logs.correct)/sum(logs.attendIn & logs.completed);
        rates.treactIn = sum(R{logs.correct & logs.attendIn,"tResp"}-R{logs.correct & logs.attendIn,"tBon"})/sum(logs.attendIn & logs.completed);
    else
        rates.correctInPct = 0;
        rates.treactIn = 0;
    end

    if sum(logs.attendOut & logs.completed) > 0
        rates.correctOutPct = sum(logs.attendOut & logs.correct)/sum(logs.attendOut & logs.completed);
        rates.treactOut = sum(R{logs.correct & logs.attendOut,"tResp"}-R{logs.correct & logs.attendOut,"tBon"})/sum(logs.attendOut & logs.completed);
    else
        rates.correctOutPct = 0;
        rates.treactOut = 0;
    end
    rates.logs = logs;

end
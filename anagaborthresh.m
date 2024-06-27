function [rates] = anagaborthresh(results)
%ANAGABORTHRESH Compute rates et al for etholog, single test image, with
%gabor images at multiple contrasts.
%   Detailed explanation goes here

    rates = struct;

    % Completed trials
    lgCompleted = r.Started & r.iResp>-1 & r.tResp > 0;

    % High-salience, Low-salience trials
    lgH = ismember(r.FolderKey,{'H'});
    lgL = ismember(r.FolderKey,{'L'});

    % Change trials = vertically-oriented gabor
    % NoChange trials = horizontally-oriented gabor
    lgChangeTrial = r.StimChangeType==1 | r.StimChangeType==2;
    lgNoChangeTrial = r.StimChangeType==0;

    % check for consistency
    if sum(lgChangeTrial) ~= sum(lgNoChangeTrial) || ...
        sum(lgChangeTrial&lgNoChangeTrial) > 0 || ...
        sum(lgChangeTrial|lgNoChangeTrial) ~= height(results)
        error('Data failed change trial consistency check.');
    end

    lgChangeTrial2 = lgChangeTrial & r.Delta==2;
    lgChangeTrial4 = lgChangeTrial & r.Delta==4;
    lgChangeTrial6 = lgChangeTrial & r.Delta==6;
    lgChangeTrial8 = lgChangeTrial & r.Delta==8;

    lgNoChangeTrial2 = lgNoChangeTrial & r.Delta==2;
    lgNoChangeTrial4 = lgNoChangeTrial & r.Delta==4;
    lgNoChangeTrial6 = lgNoChangeTrial & r.Delta==6;
    lgNoChangeTrial8 = lgNoChangeTrial & r.Delta==8;

    if sum(lgChangeTrial2|lgChangeTrial4|lgChangeTrial6|lgChangeTrial8) ~= sum(lgChangeTrial) || ...
        sum(lgNoChangeTrial2|lgNoChangeTrial4|lgNoChangeTrial6|lgNoChangeTrial8) ~= sum(lgNoChangeTrial)
        error('Data failed change trials sum check');
    end


    % left and right side tests
    lgLeftTrial = r.StimTestType==1;
    lgRightTrial = r.StimTestType==2;

    % correct and incorrect
    lgCorrect = (lgNoChangeTrial & lgCompleted & r.iResp==0) | (lgChangeTrial & lgLeft & lgCompleted & r.iResp==1) | (lgChangeTrial & lgRight & lgCompleted & r.iResp==2);
    lgCorrect = (lgNoChangeTrial & lgCompleted & r.iResp==0) | (lgChangeTrial & lgLeftTrial & lgCompleted & r.iResp==1) | (lgChangeTrial & lgRightTrial & lgCompleted & r.iResp==2);


    % now get rates....

end
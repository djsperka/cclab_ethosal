function [rates] = anagaborthresh(r)
%ANAGABORTHRESH Compute rates et al for etholog, single test image, with
%gabor images at multiple contrasts.
%   Assumes you have a complete set of trials - consistency checks will
%   fail if you use an incomplete set! To run this script, first load a
%   full set. Of the two full sets we have, these commands will load the 
%   set from dan (after you adjust for your own paths):
%
%   Y1=load('/home/dan/work/cclab/ethdata/output/gabor-threshold/thr-100-dan-1_none_000.mat');
%   Y2=load('/home/dan/work/cclab/ethdata/output/gabor-threshold/thr-100-dan-2_none.mat');
%   Y3=load('/home/dan/work/cclab/ethdata/output/gabor-threshold/thr-100-dan-3_none.mat');
%   fullresults = vertcat(Y1.results,Y2.results,Y3.results);
%
%   These lines will do the same for Rowan's data:
%
%   Z1=load('/home/dan/work/cclab/ethdata/output/gabor-threshold/thr-100-rowan-1_none.mat');
%   Z2=load('/home/dan/work/cclab/ethdata/output/gabor-threshold/thr-100-rowan-2_none.mat');
%   Z3=load('/home/dan/work/cclab/ethdata/output/gabor-threshold/thr-100-rowan-3_none.mat');
%   fullresults=vertcat(Z1.results,Z2.results,Z3.results);
%   
%   Once you have the full set of results, run the analysis:
%
%   rates=anagaborthresh(fullresults);
%
%   The rates struct contains a lot. The rates of interest include some 
%   arrays - in each case the columns correspond to the different contrast
%   values used: 2,4,6,8
%
%   rates.drateHChangeTrialByContrast - detection rate for H trials
%   rates.frateHChangeTrialByContrast - false alarm rate for H trials
%   rates.rxHChangeTrialByContrast - reaction time for successful H trials
%   rates.fxHChangeTrialByContrast - reaction time for FA H trials
%
%   rates.drateLChangeTrialByContrast - detection rate for L trials
%   rates.frateLChangeTrialByContrast - false alarm rate for L trials
%   rates.rxLChangeTrialByContrast - reaction time for successful L trials
%   rates.fxLChangeTrialByContrast - reaction time for FA L trials
%

    rates = struct;

    % Completed trials
    rates.lgCompleted = r.Started & r.iResp>-1 & r.tResp > 0;

    % High-salience, Low-salience trials
    rates.lgH = ismember(r.FolderKey,{'H'});
    rates.lgL = ismember(r.FolderKey,{'L'});

    % Change trials = vertically-oriented gabor
    % NoChange trials = horizontally-oriented gabor
    rates.lgChangeTrial = r.StimChangeType==1 | r.StimChangeType==2;
    rates.lgNoChangeTrial = r.StimChangeType==0;

    % check for consistency
    if sum(rates.lgChangeTrial) ~= sum(rates.lgNoChangeTrial) || ...
        sum(rates.lgChangeTrial&rates.lgNoChangeTrial) > 0 || ...
        sum(rates.lgChangeTrial|rates.lgNoChangeTrial) ~= height(r)
        error('Data failed change trial consistency check.');
    end

    % convenience - these are the different delta values. 
    deltas = [2,4,6,8];

    % these are arrays with each column being for a different Delta value, 
    % in the order [2,4,6,8]. When these are and'd, with another array of
    % the same height, the result will be a 4-column array.
    rates.lgChangeTrialByContrast = horzcat(rates.lgChangeTrial & r.Delta==deltas(1),rates.lgChangeTrial & r.Delta==deltas(2),rates.lgChangeTrial & r.Delta==deltas(3),rates.lgChangeTrial & r.Delta==deltas(4));
    rates.lgNoChangeTrialByContrast = horzcat(rates.lgNoChangeTrial & r.Delta==deltas(1),rates.lgNoChangeTrial & r.Delta==deltas(2),rates.lgNoChangeTrial & r.Delta==deltas(3),rates.lgNoChangeTrial & r.Delta==deltas(4));

    % left and right side tests
    rates.lgLeftTrial = r.StimTestType==1;
    rates.lgRightTrial = r.StimTestType==2;

    % correct and incorrect
    rates.lgCorrect = (rates.lgNoChangeTrial & rates.lgCompleted & r.iResp==0) | (rates.lgChangeTrial & rates.lgLeftTrial & rates.lgCompleted & r.iResp==1) | (rates.lgChangeTrial & rates.lgRightTrial & rates.lgCompleted & r.iResp==2);
    rates.lgIncorrect = (rates.lgNoChangeTrial & rates.lgCompleted & r.iResp~=0) | (rates.lgChangeTrial & rates.lgLeftTrial & rates.lgCompleted & r.iResp~=1) | (rates.lgChangeTrial & rates.lgRightTrial & rates.lgCompleted & r.iResp~=2);

    if sum(rates.lgCorrect) + sum(rates.lgIncorrect) ~= sum(rates.lgCompleted)
        error('Data failed correct/incorrect sum check');
    end

    
    % rates by contrast for all types
    rates.drateChangeTrialByContrast = sum(rates.lgChangeTrialByContrast & rates.lgCorrect)./sum(rates.lgChangeTrialByContrast & rates.lgCompleted);
    rates.frateChangeTrialByContrast = sum(rates.lgNoChangeTrialByContrast & rates.lgIncorrect)./sum(rates.lgNoChangeTrialByContrast & rates.lgCompleted);

    % rates by contrast for H
    rates.drateHChangeTrialByContrast = sum(rates.lgH & rates.lgChangeTrialByContrast & rates.lgCorrect)./sum(rates.lgH & rates.lgChangeTrialByContrast & rates.lgCompleted);
    rates.frateHChangeTrialByContrast = sum(rates.lgH & rates.lgNoChangeTrialByContrast & rates.lgIncorrect)./sum(rates.lgH & rates.lgNoChangeTrialByContrast & rates.lgCompleted);

    % rx times for H
    rates.rxHChangeTrialByContrast = zeros(1, length(deltas));
    lgTmpHOK = rates.lgH & rates.lgChangeTrialByContrast & rates.lgCorrect;
    lgTmpHFA = rates.lgH & rates.lgNoChangeTrialByContrast & rates.lgIncorrect;
    for i=1:length(deltas)
        rates.rxHChangeTrialByContrast(i) = sum(r.tResp(lgTmpHOK(:,i))-r.tBon(lgTmpHOK(:,i)))/sum(lgTmpHOK(:,i));
        rates.fxHChangeTrialByContrast(i) = sum(r.tResp(lgTmpHFA(:,i))-r.tBon(lgTmpHFA(:,i)))/sum(lgTmpHFA(:,i));
    end

    % rates by contrast for L
    rates.drateLChangeTrialByContrast = sum(rates.lgL & rates.lgChangeTrialByContrast & rates.lgCorrect)./sum(rates.lgL & rates.lgChangeTrialByContrast & rates.lgCompleted);
    rates.frateLChangeTrialByContrast = sum(rates.lgL & rates.lgNoChangeTrialByContrast & rates.lgIncorrect)./sum(rates.lgL & rates.lgNoChangeTrialByContrast & rates.lgCompleted);

    % rx times for L
    rates.rxLChangeTrialByContrast = zeros(1, length(deltas));
    lgTmpLOK = rates.lgL & rates.lgChangeTrialByContrast & rates.lgCorrect;
    lgTmpLFA = rates.lgL & rates.lgNoChangeTrialByContrast & rates.lgIncorrect;
    for i=1:length(deltas)
        rates.rxLChangeTrialByContrast(i) = sum(r.tResp(lgTmpLOK(:,i))-r.tBon(lgTmpLOK(:,i)))/sum(lgTmpLOK(:,i));
        rates.fxLChangeTrialByContrast(i) = sum(r.tResp(lgTmpLFA(:,i))-r.tBon(lgTmpLFA(:,i)))/sum(lgTmpLFA(:,i));
    end

end
function [rates] = anaimagethresh(r)
%ANAGABORTHRESH Compute rates et al for etholog, single test image, with
%modified images at multiple contrasts.
%   Assumes you have a complete set of trials - consistency checks will
%   fail if you use an incomplete set! To run this script, first load a
%   full set. Of the two full sets we have, these commands will load the 
%   set from dan (after you adjust for your own paths):
%
%     Y1=load('/home/dan/work/cclab/ethdata/output/image-threshold/dan_img_thr-1_thr.mat');
%     Y2=load('/home/dan/work/cclab/ethdata/output/image-threshold/dan_img_thr-2_thr.mat');
%     Y3=load('/home/dan/work/cclab/ethdata/output/image-threshold/dan_img_thr-3_thr.mat');
%     fullresults = vertcat(Y1.results,Y2.results,Y3.results);
%   
%   Once you have the full set of results, run the analysis:
%
%   rates=anaimagethresh(fullresults);
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
    rates.lgL = ismember(r.FolderKey,{'Q'});

    % convenience - these are the different delta values. 
    deltas = [0,10,20,30,40];

    % these are arrays with each column being for a different Delta value, 
    % When these are and'd, with another array of
    % the same height, the result will be a 4-column array.
%    rates.lgChangeTrialByContrast = horzcat(r.Delta==deltas(1),r.Delta==deltas(2),rates.lgChangeTrial & r.Delta==deltas(3),rates.lgChangeTrial & r.Delta==deltas(4));
    rates.lgChangeTrialByContrast = horzcat(r.Delta==deltas(1:end));

    % left and right side tests
    rates.lgLeftTrial = r.StimTestType==1;
    rates.lgRightTrial = r.StimTestType==2;

    % correct and incorrect
    rates.lgCorrect = rates.lgCompleted & r.iResp==r.StimChangeType;
    rates.lgIncorrect = rates.lgCompleted & r.iResp~=r.StimChangeType;

    if sum(rates.lgCorrect) + sum(rates.lgIncorrect) ~= sum(rates.lgCompleted)
        error('Data failed correct/incorrect sum check');
    end

    
    % rates by contrast for all types
    rates.drateChangeTrialByContrast = sum(rates.lgChangeTrialByContrast & rates.lgCorrect)./sum(rates.lgChangeTrialByContrast & rates.lgCompleted);

    % rates by contrast for H
    rates.drateHChangeTrialByContrast = sum(rates.lgH & rates.lgChangeTrialByContrast & rates.lgCorrect)./sum(rates.lgH & rates.lgChangeTrialByContrast & rates.lgCompleted);

    % rx times for H
    rates.rxHChangeTrialByContrast = zeros(1, length(deltas));
    lgTmpHOK = rates.lgH & rates.lgChangeTrialByContrast & rates.lgCorrect;
    for i=1:length(deltas)
        rates.rxHChangeTrialByContrast(i) = sum(r.tResp(lgTmpHOK(:,i))-r.tBon(lgTmpHOK(:,i)))/sum(lgTmpHOK(:,i));
    end

    % rates by contrast for L
    rates.drateLChangeTrialByContrast = sum(rates.lgL & rates.lgChangeTrialByContrast & rates.lgCorrect)./sum(rates.lgL & rates.lgChangeTrialByContrast & rates.lgCompleted);

    % rx times for L
    rates.rxLChangeTrialByContrast = zeros(1, length(deltas));
    lgTmpLOK = rates.lgL & rates.lgChangeTrialByContrast & rates.lgCorrect;
    for i=1:length(deltas)
        rates.rxLChangeTrialByContrast(i) = sum(r.tResp(lgTmpLOK(:,i))-r.tBon(lgTmpLOK(:,i)))/sum(lgTmpLOK(:,i));
    end


    figure;
    plot(deltas,rates.drateHChangeTrialByContrast, deltas,rates.drateLChangeTrialByContrast, 'LineWidth',2.0)
    xlabel('Contrast change %');
    ylabel('detection rate');
    title('Change detection by contrast change');


end
function [cclab] = load_local_config()
%load_local_config A struct with etholog() params is created and returned. 
%   Detailed explanation goes here


    cclab.dummymode_EYE = 1;
    cclab.SkipSyncTests = 1;
    cclab.Verbosity = 0;
    cclab.VisualDebugLevel = 1;
    
    % If 'Fovx' is defined, these two measurements are ignored, and don't
    % need to be present at all but don't hurt. Otherwise, make sure they
    % are correct for your experimental setup and screen. They should be in
    % the same units, MM aren't strictly required (ratio is what matters).
    cclab.ScreenWidthMM = 1000;
    cclab.EyeDistMM = 500;
    
    Type1 = ['H';'H';'H';'H';'H';'H';'H';'H';'H';'H'];
    Type2 = ['L';'L';'L';'L';'L';'L';'L';'L';'L';'L'];
    FName = {'1';'2';'3';'4';'5';'6';'7';'8';'9';'10'};
    Change = [1;2;1;2;0;1;2;1;2;0];
    ChangeContrast = [.5;.5;.5;.5;.5;.5;.5;.5;.5;.5];
    FixTime  = [1;1;1;1;1;1;1;1;1;1];
    SampTime = [2;2;2;2;2;2;2;2;2;2];
    TestTime = [2;2;2;2;2;2;2;2;2;2];
    RespTime = [2;2;2;2;2;2;2;2;2;2];
    
    cclab.trials = table(Type1, Type2, FName, Change, ChangeContrast, FixTime, SampTime, TestTime, RespTime);
    cclab.ITI = 1.0;
end


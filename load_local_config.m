function [cclab] = load_local_config()
%load_local_config A struct with etholog() params is created and returned. 
%   Detailed explanation goes here


    %cclab.dummymode_EYE = 0;
    %cclab.SkipSyncTests = 1;
    %cclab.Verbosity = 0;
    %cclab.VisualDebugLevel = 1;

    cclab.FixationTime = 0.5;
    cclab.MaxAcquisitionTime = 2.0;
    cclab.FixationBreakEarlyTime = 0.5;
    cclab.FixationBreakLateTime = 2.0;
    cclab.SampTimeRange = [1.0, 2.0];


    % The screen width (the width of all visible pixels) and the eye
    % distance are used for visual angle calculations. The definitions here
    % are overridden by the 'Fovx' arg on the command line. That arg is
    % meant for testing - where you are using a window on a screen, not
    % full screen. TODO - fix PsychImaging pipeline to correctly scale
    % stuff in that case. 
    cclab.ScreenWidthMM = 1000;
    cclab.EyeDistMM = 500;
    
    Type1 = ['H';'H';'H';'H';'H';'H';'H';'H';'H';'H'];
    Type2 = ['L';'L';'L';'L';'L';'L';'L';'L';'L';'L'];
    FName = {'N51';'N52';'N53';'N54';'N55';'N56';'N57';'N58';'N59';'N60'};
    Change = [1;2;1;2;0;1;2;1;2;0];
    ChangeContrast = [.5;.5;.5;.5;.5;.5;.5;.5;.5;.5];
    GapTime = [0;0;0;0;0;0;0;0;0;0];
    TestTime = [2;2;2;2;2;2;2;2;2;2];
    RespTime = [2;2;2;2;2;2;2;2;2;2];
    
    cclab.trials = table(Type1, Type2, FName, Change, ChangeContrast, SampTime, GapTime, TestTime, RespTime);
    cclab.ITI = 1.0;
end


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
    
    % Going to create a table called 'trials' using these arrays of vars.
    cclab.ImageFiles = {
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image1.bmp';  
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image2.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image3.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image4.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image5.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image13.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image15.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image16.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image17.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Natural/Image18.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image1.bmp';  
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image2.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image3.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image4.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image5.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image13.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image15.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image16.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image17.bmp';
        '/Users/dan/git/orhan-ptb-scripts/standAlone_learningAttention/Images/Texture/Image18.bmp'
        };
    Img1 = (1:10)';
    Img2 = (11:20)';
    Change = [1;2;1;2;0;1;2;1;2;0];
    ChangeContrast = [50;50;50;50;50;50;50;50;50;50];
    FixTime  = [1;1;1;1;1;1;1;1;1;1];
    SampTime = [3;3;3;3;3;3;3;3;3;3];
    TestTime = [3;3;3;3;3;3;3;3;3;3];
    RespTime = [2;2;2;2;2;2;2;2;2;2];
    
    cclab.trials = table(Img1, Img2, Change, ChangeContrast, FixTime, SampTime, TestTime, RespTime);
end


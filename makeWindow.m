function [windowPtr,windowRect] = makeWindow(wh,screen,a1,a2)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    PsychDefaultSetup(2);
    r=SetRect(0,0,wh(1),wh(2));
    sr=Screen('Rect', screen);
    mywr=AlignRect(r,sr,a1,a2);
    [windowPtr, windowRect] = PsychImaging('OpenWindow', screen, [.5 .5 .5], mywr);
end


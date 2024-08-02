function [tf, s] = visualFeedbackRectAnimator(t, mm, w, s)
%visualFeedbackRectAnimator Callback for AnimMgr - animate a fade-out rectangle.
%   User data arg must be a struct with fields color, on, ramp, off, thick
%   thick is the line thickness for 'FrameRect'
%   Rect is drawn at s

    [srcfactorOld, dstFactorOld, ~] = Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    color=s.color;
    if t < s.on
        color(4) = 0;
    elseif t < s.ramp
        color(4) = 1;
    elseif t < s.off
        color(4) = 1-(t-s.ramp)/(s.off-s.ramp);
    else 
        color(4) = 0;
    end
    Screen('FrameRect', w, color, s.rect, s.thick);
    Screen('BlendFunction', w, srcfactorOld, dstFactorOld);
    tf=true;
end

function [tf, sreturned] = ethologFixationCueCallback(ind, t, minmax, w, s)
%ethologFixationCueCallback Callback for ethologV2 - animate a cue.
%   User data arg must be a struct with fields UNKNOWN AT THIS TIME.

    tf = true;
    sreturned = s;

    % Draw fixation cross on screen
    if ind
        s.fixpt.draw(w, s.cueDirIndex);
    else
        s.fixpt.draw(w);
    end
end

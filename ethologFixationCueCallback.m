function [tf, sreturned] = ethologFixationCueCallback(ind, t, minmax, w, s)
%ethologFixationCueCallback Callback for ethologV2 - animate a cue.
%   User data arg must be a struct with fields UNKNOWN AT THIS TIME.

    tf = true;
    sreturned = s;

    % Draw fixation cross on screen
    Screen('DrawLines', w, s.fixLines, 4, s.fixColor);
    if ind
        % Get chevrons
        [~,segments] = getChevrons(s.fixXYScr, s.dirVecs(:,s.cueDirIndex), s.dpix, s.ipix, s.lpix, s.tpix, 1);
        Screen('DrawLines', w, segments, 4, s.fixColor);
    end
end

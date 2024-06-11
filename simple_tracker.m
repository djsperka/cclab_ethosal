function simple_tracker(dummy_mode)
%simple_tracker Simple fixation using tracker. Arg is 0 for real tracking,
%1 for mouse mode. 

    % ptb defaults
    PsychDefaultSetup(2);

    % open window
    [window ,window_rect] = PsychImaging('OpenWindow',0,[.5,.5,.5]);
    [fixpt_x, fixpt_y] = RectCenter(window_rect);
    
    % start tracker. 
    % When the class is instantiated, the tracker is put into 'Camera Setup'.
    % You can (should) calibrate at that point. When you hit "Exit Setup", the
    % call below (tracker = ...) returns. 

    screen_dimension_mm = [527, 298];
    screen_distance_mm = 550;
    edf_name = 'unused';
    tracker=eyetracker(dummy_mode, screen_dimension_mm, screen_distance_mm, edf_name, window);
    
    % rects for dot and fixation window
    fixpt_rect = [0, 0, 50, 50];
    fixation_window_rect = [0, 0, 100, 100];

    bQuit = 0;
    state = "START";
    tStateStart = -1;
    while ~bQuit && state ~= "DONE"
    
        % Check kb each time 
        [keyIsDown, ~, keyCode] = KbCheck();
        
        % TODO kb handling
        if keyIsDown && keyCode(KbName('q'))
            state = "DONE";
        end

        tNow = GetSecs;
        switch(state)
            case "START"
                fprintf("entering START\n");
                Screen('FillOval', window, rand(1,3), CenterRectOnPoint(fixpt_rect, fixpt_x, fixpt_y))
                Screen('Flip', window);
                
                % start tracker recording
                tracker.start_recording();

                state = "WAIT_FOR_ACQ";
                tStateStart = tNow;
            case "WAIT_FOR_ACQ"
                if tracker.is_in_rect(CenterRectOnPoint(fixation_window_rect, fixpt_x, fixpt_y))
                    fprintf("eye is in window - to WAIT_FIX\n");
                    tStateStart = tNow;
                    state = "WAIT_FIX";
                end
            case "WAIT_FIX"
                if ~tracker.is_in_rect(CenterRectOnPoint(fixation_window_rect, fixpt_x, fixpt_y))
                    fprintf('WAIT_FIX: fixation for %f sec.\n', tNow-tStateStart);
                    Screen('Flip', window);
                    tStateStart = tNow;
                    state = "WAIT_ITI";
                end
            case "WAIT_ITI"
                % stop tracker recording
                tracker.offline();

                if tNow-tStateStart > 2
                    tStateStart = tNow;
                    state = "START";
                end
            case "DONE"
                bQuit = true;
            otherwise
                error("Unhandled state %s\n", state);
        end                                 
    end

    ListenChar(0);
    sca;
end

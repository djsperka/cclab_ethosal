classdef eyetracker < handle
    %eyetracker Encapsulation of eye tracker functionality for cclab.
    %   Detailed explanation goes here
    
    properties (Access = private)
        DummyMode
        EyelinkDefaults
        Window
        ScreenWidthPix
        ScreenHeightPix
        ScreenWHMM
        ScreenDistanceMM
        Name
        Verbose
    end
    
    methods
        function obj = eyetracker(mode, screen_dimensions, screen_distance, name, window, varargin)
            %eyetracker Construct an instance of this class
            %   Detailed explanation goes here
            
            try
                p = inputParser;
                p.addRequired('DummyMode', @(x) isscalar(x) && (x == 0 || x == 1));
                p.addRequired('ScreenWH', @(x) isempty(x) || (isnumeric(x) && isvector(x) && length(x)==2));
                p.addRequired('ScreenDistance', @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
                p.addRequired('EDFName', @(x) ischar(x) && ~isempty(x) && length(x) < 9);
                p.addRequired('Window', @(x) isscalar(x));
                p.addParameter('Verbose', 0, @(x) isscalar(x) && isnumeric(x) && x>=0);
                p.parse(mode, screen_dimensions, screen_distance, name, window, varargin{:});
            catch ME
                rethrow(ME);
            end
            
            obj.DummyMode = true;
            if ~p.Results.DummyMode; obj.DummyMode = false; end
            obj.Name = p.Results.EDFName;
            obj.Window = p.Results.Window;
            rect = Screen('Rect', obj.Window);
            obj.ScreenWidthPix = rect(3);
            obj.ScreenHeightPix = rect(4);
            obj.Verbose = p.Results.Verbose>0;
            obj.ScreenWHMM = p.Results.ScreenWH;
            obj.ScreenDistanceMM = p.Results.ScreenDistance;

            if obj.DummyMode
                fprintf('Using eyetracker in dummy mode.\n');
            else
                obj.eyelink_setup();
            end
        end
        
        function delete(~)
            Eyelink('Shutdown');
        end
        
        function [] = command(obj, formatstring, varargin)
            %command Issues Eyelink('Command', cmdString) if not in dummy
            %mode. In dummy mode, nothing happens.
            %   Detailed explanation goes here
            if ~obj.DummyMode
                Eyelink('Command', formatstring, varargin{:});
            elseif obj.Verbose
                fprintf(1, 'Eyelink Command: %s', sprintf(formatstring, varargin{:}));
            end
        end
        
        function [] = message(obj, formatstring, varargin)
            %command Issues Eyelink('Command', cmdString) if not in dummy
            %mode. In dummy mode, nothing happens.
            %   Detailed explanation goes here
            if ~obj.DummyMode
                Eyelink('Message', formatstring, varargin{:});
            elseif obj.Verbose
                fprintf(1, 'No Eyelink(Message) in dummy mode: %s', cmdString);
            end
        end

        function start_recording(obj)
            if ~obj.DummyMode
                Eyelink('SetOfflineMode');
                Eyelink('StartRecording');
            elseif obj.Verbose
                fprintf('eyetracker.start_recording: dummy mode.\n');
            end
        end

        function offline(obj)
            if ~obj.DummyMode
                Eyelink('SetOfflineMode');
            elseif obj.Verbose
                fprintf('eyetracker.offline: dummy mode.\n');
            end
        end            

        function [tf] = is_in_rect(obj, rect)
            %is_in_rect Is current eye pos in the rect? Returns 1/0.
            [x, y] = obj.eyepos();
            tf = IsInRect(x, y, rect);
        end

        function [x, y] = eyepos(obj)
            persistent eyeUsedIndex;

            if ~obj.DummyMode
                if Eyelink('CurrentMode') ~= obj.EyelinkDefaults.IN_RECORD_MODE
                    exception = MException('eyetracker:eyepos', 'Tracker is not recording, call start_recording.');
                    throw(exception);
                end
    
                if isempty(eyeUsedIndex)
                    % Check which eye is available. Returns 0 (left), 1 (right) or 2 (binocular)
                    i = Eyelink('EyeAvailable');
                    switch i
                        case obj.EyelinkDefaults.LEFT_EYE
                            eyeUsedIndex = 1;
                        case obj.EyelinkDefaults.RIGHT_EYE
                            eyeUsedIndex = 2; 
                        case obj.EyelinkDefaults.BINOCULAR
                            eyeUsedIndex = 2; % Get samples from right eye if binocular
                        otherwise
                            exception = MException('eyetracker:eyepos', sprintf('Unknown response (%d) from Eyelink(''EyeAvailable'')', i));
                            throw(exception);
                    end
                end
            end

            % now get the actual eye position
            if obj.DummyMode
                [x, y] = GetMouse(obj.Window);
            else
                evt = Eyelink('NewestFloatSample');
                x = evt.gx(eyeUsedIndex);
                y = evt.gy(eyeUsedIndex);
            end

        end
    
        function S = saccade(obj, R)
            if size(R,1) ~= 4
                exception = MException('eyetracker.saccade', 'input should be 4xN array of rects');
                throw(exception);
            end
            S = zeros(1, size(R,2));
            [x, y] = obj.eyepos();
            for i=1:size(R,2)
                S(i) = IsInRect(x, y, R(:,i));
            end
        end

        function clear_screen(obj, c)
            if ~obj.DummyMode
                obj.command('clear_screen %d', c);
            end
        end

        function draw_box(obj, x1, y1, x2, y2, c)
            if ~obj.DummyMode
                obj.command('draw_box %ld %ld %ld %ld %ld', round(x1), round(y1), round(x2), round(y2), c);
            end
        end

        function draw_cross(obj, x, y, c)
            if ~obj.DummyMode
                obj.command('draw_cross %ld %ld %ld', round(x), round(y), c);
            end
        end

        function drift_correct(obj, x, y)
            %drift_correct(obj, x, y) Do drift correct for (already drawn)
            %item at x,y
            if ~obj.DummyMode
                obj.command('driftcorrect_cr_disable = OFF');
                %obj.command('online_dcorr_refposn 960, 540');
                obj.command('online_dcorr_button = OFF');
                obj.command('normal_click_dcorr = OFF');
                EyelinkDoDriftCorrect(obj.EyelinkDefaults, x, y, 0, 0);
            end
        end
    end
    
    methods (Access = private)
        function eyelink_setup(obj)
            [result, ~] = EyelinkInit(obj.DummyMode);
            if ~result
                errID = 'eyetracker:eyelink_setup';
                msg = sprintf('EyelinkInit failed to connect (mode %d).', obj.DummyMode);
                baseException = MException(errID,msg);
                throw(baseException);
            end

            % should be connected at this point, either as dummy or for real
            status = Eyelink('IsConnected');
            if ~status 
                errID = 'eyetracker:eyelink_setup';
                msg = 'EyelinkInit failed to connect.';
                baseException = MException(errID,msg);
                throw(baseException);
            end

            if ~obj.DummyMode
                % Open EDF file. Note that filename must be 8 char or less (like on windows, 
                % but somehow preserved on the Eyelink QNX version.
                status = Eyelink('OpenFile', obj.Name);
                if status
                    errID = 'eyetracker:eyelink_setup';
                    msg = sprintf('EyelinkInit failed open EDF file with name %s.', obj.Name);
                    baseException = MException(errID,msg);
                    throw(baseException);
                end

                % Add a line of text in the EDF file to identify the current experimemt name and session. This is optional.
                % If your text starts with "RECORDED BY " it will be available in DataViewer's Inspector window by clicking
                % the EDF session node in the top panel and looking for the "Recorded By:" field in the bottom panel of the Inspector.
                preambleText = sprintf('RECORDED BY etholog in session: %s', obj.Name);
                Eyelink('Command', 'add_file_preamble_text "%s"', preambleText);

                % Select which events are saved in the EDF file. Include everything just in case
                obj.command('file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
                obj.command('link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
                obj.command('file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
                obj.command('link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');

                % Set screen physical dimensions, or else warn
                if ~isempty(obj.ScreenWHMM)
                    halfW = obj.ScreenWHMM(1)/2;
                    halfH = obj.ScreenWHMM(2)/2;
                    obj.command(sprintf('screen_phys_coords = %0.1f %0.1f %0.1f %0.1f ', -halfW, halfH, halfW, -halfH));
                else
                    warning('SCREEN DIMENSIONS NOT PROVIDED. TRACKER IS GUESSING HERE!!!');
                end

                if ~isempty(obj.ScreenDistanceMM)
                    obj.command(sprintf('screen_distance = %0.1f', obj.ScreenDistanceMM));
                else
                    warning('SCREEN DISTANCE NOT PROVIDED. TRACKER IS GUESSING HERE!!!');
                end
                    

                % Provide EyeLink with some defaults, which are returned in the structure "el".
                obj.EyelinkDefaults = EyelinkInitDefaults(obj.Window);
                % set calibration/validation/drift-check(or drift-correct) size as well as background and target colors.
                % It is important that this background colour is similar to that of the stimuli to prevent large luminance-based
                % pupil size changes (which can cause a drift in the eye movement data)
                obj.EyelinkDefaults.calibrationtargetsize = 2; % Outer target size as percentage of the screen
                obj.EyelinkDefaults.calibrationtargetwidth = 0.7; % Inner target size as percentage of the screen

                % colors
                grey = [0.5, 0.5, 0.5];
                black = [0, 0, 0];

                obj.EyelinkDefaults.backgroundcolour = grey; % RGB grey
                obj.EyelinkDefaults.calibrationtargetcolour = black; % RGB black
                % set "Camera Setup" instructions text colour so it is different from background colour
                obj.EyelinkDefaults.msgfontcolour = black; % RGB black
                % Set calibration beeps (0 = sound off, 1 = sound on)
                obj.EyelinkDefaults.targetbeep = 1;  % sound a beep when a target is presented
                obj.EyelinkDefaults.feedbackbeep = 1;  % sound a beep after calibration or drift check/correction

                % You must call this function to apply the changes made to the el structure above
                EyelinkUpdateDefaults(obj.EyelinkDefaults);

                obj.command('screen_pixel_coords = %ld %ld %ld %ld', 0, 0, obj.ScreenWidthPix-1, obj.ScreenHeightPix-1);
                % Write DISPLAY_COORDS message to EDF file: sets display coordinates in DataViewer
                % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Pre-trial Message Commands
                obj.message('DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, obj.ScreenWidthPix-1, obj.ScreenHeightPix-1);
                obj.command('calibration_type = HV5'); % horizontal-vertical 9-points
                obj.command('button_function 5 "accept_target_fixation"');
                obj.command('clear_screen 0');

                % Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
                EyelinkDoTrackerSetup(obj.EyelinkDefaults);
            end
        end
    end
end


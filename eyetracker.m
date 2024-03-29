classdef eyetracker < handle
    %eyetracker Encapsulation of eye tracker functionality for cclab.
    %   Detailed explanation goes here
    
    properties (Access = private)
        DummyMode
        EyelinkDefaults
        Window
        ScreenWidthPix
        ScreenHeightPix
        Name
    end
    
    methods
        function obj = eyetracker(mode, name, window)
            %eyetracker Construct an instance of this class
            %   Detailed explanation goes here
            
            try
                p = inputParser;
                p.addRequired('DummyMode', @(x) isscalar(x) && (x == 0 || x == 1));
                p.addRequired('Name', @(x) ischar(x) && length(x) > 0 && length(x) < 9);
                p.addRequired('Window', @(x) isscalar(x));
                p.addOptional('DoSetup', false, @(x) islogical(x));
                p.parse(mode, name, window);
            catch ME
                rethrow(ME);
            end
            
            obj.DummyMode = true;
            if ~p.Results.DummyMode obj.DummyMode = false; end
            obj.Name = p.Results.Name;
            obj.Window = p.Results.Window;
            rect = Screen('Rect', obj.Window);
            obj.ScreenWidthPix = rect(3);
            obj.ScreenHeightPix = rect(4);

            if obj.DummyMode
                fprintf('Using eyetracker in dummy mode.\n');
            else
                obj.eyelink_setup();
            end
        end
        
        function delete(obj)
            Eyelink('Shutdown');
        end
        
        function [] = command(obj, formatstring, varargin)
            %command Issues Eyelink('Command', cmdString) if not in dummy
            %mode. In dummy mode, nothing happens.
            %   Detailed explanation goes here
            if obj.DummyMode
                warning('No Eyelink(Command) in dummy mode: %s', cmdString);
            else
                Eyelink('Command', formatstring, varargin{:});
            end
        end
        
        function [] = message(obj, formatstring, varargin)
            %command Issues Eyelink('Command', cmdString) if not in dummy
            %mode. In dummy mode, nothing happens.
            %   Detailed explanation goes here
            if obj.DummyMode
                warning('No Eyelink(Message) in dummy mode: %s', cmdString);
            else
                Eyelink('Message', formatstring, varargin{:});
            end
        end

        function start_recording(obj)
            if ~obj.DummyMode
                Eyelink('SetOfflineMode');
                Eyelink('StartRecording');
            else
                fprintf('eyetracker.start_recording: dummy mode.\n');
            end
        end

        function offline(obj)
            if ~obj.DummyMode
                Eyelink('SetOfflineMode');
            else
                fprintf('eyetracker.offline: dummy mode.\n');
            end
        end            

        function [tf] = is_in_rect(obj, rect)
            %is_in_rect Is current eye pos in the rect? Returns 1/0.
            [x, y] = obj.eyepos();
            tf = IsInRect(x, y, rect);
        end

        function [x y] = eyepos(obj)
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
                [x y] = GetMouse(obj.Window);
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

    end
    
    methods (Access = private)
        function eyelink_setup(obj)
            [result, ~] = EyelinkInit(obj.DummyMode)
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


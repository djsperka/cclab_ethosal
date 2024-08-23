classdef twotonebeeper < handle
    %beeper Generate one of two beeps.
    %   Detailed explanation goes here
    
    properties (Access = private)
        PAHandle
        Duration
        FreqCorrect
        FreqIncorrect
        SoundCorrect
        SoundIncorrect
        IsSoundFromFile
        SampleRate
        IsUsingSnd
    end

    methods
        function obj = twotonebeeper(varargin)
            %beeper Simple two tone beeper. 
            %   Correct (default 800) is freq of correct() tone, Incorrect (default 350) is freq of
            %   incorrect(). Duration (default 0.25s) is in sec.
            %   A filename of a sound file may be supplied for both Correct
            %   and Incorrect (both must be files, or else neither). In
            %   this case, the frequencies of the two files must be the
            %   same.
            
            try
                p = inputParser;
                p.addOptional('Correct', 1000, @(x) (isnumeric(x) && isscalar(x) && x>0) || (ischar(x) && isfile(x)) );
                p.addOptional('Incorrect', 800,  @(x) (isnumeric(x) && isscalar(x) && x>0) || (ischar(x) && isfile(x)) );
                p.addOptional('Duration', 0.25, @(x) isscalar(x) && x>0 );
                p.addOptional('OpenSnd', true, @(x) islogical(x));
                p.parse(varargin{:});
            catch ME
                rethrow(ME);
            end

            
            
            InitializePsychSound(1);

            bFileFlag = false;
            if ischar(p.Results.Correct) || ischar(p.Results.Incorrect)
                if ~(ischar(p.Results.Correct) && ischar(p.Results.Incorrect))
                    exception = MException('twotonebeeper:init', 'If using sound files, then both Correct and Incorrect must be files.');
                    throw(exception);
                else
                    bFileFlag = true;
                end 
            end

            
            
            % Open default audio device. 
            % If OpenSnd is true (the default), then use the handle to open
            % the Snd device. See "help Snd" notes section "Audio device 
            % sharing for interop with PsychPortAudio"
            obj.PAHandle = PsychPortAudio('Open');
            obj.IsUsingSnd = false;
            if (p.Results.OpenSnd)
                Snd('Open', obj.PAHandle, 1);
                obj.IsUsingSnd = true;
            end
            
            status = PsychPortAudio('GetStatus', obj.PAHandle);
            obj.SampleRate = status.SampleRate;


            if ~bFileFlag

                obj.FreqCorrect = p.Results.Correct;
                obj.FreqIncorrect = p.Results.Incorrect;
                obj.Duration = p.Results.Duration;
                obj.IsSoundFromFile = false;
    
                t = [0:1/obj.SampleRate:obj.Duration]; % 0.1 second duration
                soundTemp = sin(2 * pi * obj.FreqCorrect * t);
                obj.SoundCorrect = vertcat(soundTemp, soundTemp);
                soundTemp = sin(2 * pi * obj.FreqIncorrect * t);
                obj.SoundIncorrect = vertcat(soundTemp, soundTemp);

            else

                obj.IsSoundFromFile = true;
                [soundTemp, fTemp] = audioread(p.Results.Correct);
                if fTemp ~= obj.SampleRate
                    warning('Audio file (Correct) has sample rate (%d) different than default device rate (%d)', fTemp, obj.SampleRate);
                end
                obj.SoundCorrect = soundTemp';
                %size(obj.SoundCorrect)

                [soundTemp, fTemp] = audioread(p.Results.Incorrect);
                if fTemp ~= obj.SampleRate
                    warning('Audio file (Incorrect)has sample rate (%d) different than default device rate (%d)', fTemp, obj.SampleRate);
                end
                obj.SoundIncorrect = soundTemp';
                %size(obj.SoundIncorrect)

            end


        end
        
        function playsound(obj, ch1, ch2, dur)
            PsychPortAudio('FillBuffer', obj.PAHandle, [ch1; ch2]);
            PsychPortAudio('Start', obj.PAHandle, 1, 0, 1);
            WaitSecs(dur);
            PsychPortAudio('Stop', obj.PAHandle);
        end
            
        function correct(obj)
            if obj.IsSoundFromFile
                dur = size(obj.SoundCorrect, 2)/obj.SampleRate
            else
                dur = obj.Duration;
            end
            obj.playsound(obj.SoundCorrect(1,:), obj.SoundCorrect(2,:), dur);
        end

        function incorrect(obj)
            if obj.IsSoundFromFile
                dur = size(obj.SoundIncorrect, 2)/obj.SampleRate
            else
                dur = obj.Duration;
            end
            obj.playsound(obj.SoundIncorrect(1,:), obj.SoundIncorrect(2,:), dur);
        end

        function delete(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %PsychPortAudio('Close', obj.PAHandle);
            if (obj.IsUsingSnd)
                Snd('Close', 1);
            end
            PsychPortAudio('Close', obj.PAHandle);
        end
    end
end


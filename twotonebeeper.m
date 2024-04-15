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
        FreqPlayback
    end

    methods
        function obj = twotonebeeper(varargin)
            %beeper Simple two tone beeper. 
            %   Correct (default 800) is freq of correct() tone, Incorrect (default 350) is freq of
            %   incorrect(). Duration (default 0.25s) is in sec, Playback is playback freq
            %   (default 44100)
            
            try
                p = inputParser;
                p.addOptional('Correct', 800, @(x) isscalar(x) && x>0 );
                p.addOptional('Incorrect', 350,  @(x) isscalar(x) && x>0 );
                p.addOptional('Duration', 0.25, @(x) isscalar(x) && x>0 );
                p.addOptional('Playback', 44100, @(x) isscalar(x) && x > 0);    % can preobably do better
                p.addOptional('OpenSnd', true, @(x) islogical(x));
                p.parse(varargin{:});
            catch ME
                rethrow(ME);
            end

            
            
            InitializePsychSound(1);

            
            obj.FreqCorrect = p.Results.Correct;
            obj.FreqIncorrect = p.Results.Incorrect;
            obj.FreqPlayback = p.Results.Playback;
            obj.Duration = p.Results.Duration;
            
            % Open default audio device. 
            % If OpenSnd is true (the default), then use the handle to open
            % the Snd device. See "help Snd" notes section "Audio device 
            % sharing for interop with PsychPortAudio"
            obj.PAHandle = PsychPortAudio('Open');
            if (p.Results.OpenSnd)
                Snd('Open', obj.PAHandle, 1);
            end
            
            status = PsychPortAudio('GetStatus', obj.PAHandle);
            sampleRate = status.SampleRate;

            t = 0:1/sampleRate:obj.Duration; % 0.1 second duration
            obj.SoundCorrect = sin(2 * pi * obj.FreqCorrect * t);
            obj.SoundIncorrect = sin(2 * pi * obj.FreqIncorrect * t);

        end
        
        function playsound(obj, ch1, ch2, dur)
            PsychPortAudio('FillBuffer', obj.PAHandle, [ch1; ch2]);
            PsychPortAudio('Start', obj.PAHandle, 1, 0, 1);
            WaitSecs(dur);
            PsychPortAudio('Stop', obj.PAHandle);
        end
            
        function correct(obj)
            obj.playsound(obj.SoundCorrect, obj.SoundCorrect, obj.Duration);
        end

        function incorrect(obj)
            obj.playsound(obj.SoundIncorrect, obj.SoundIncorrect, obj.Duration);
        end

        function delete(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            PsychPortAudio('Close');
        end
    end
end


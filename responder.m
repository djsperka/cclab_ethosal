classdef responder < handle
    %responder Encapsulation of a response box-type keyboard device. 
    %   Class that takes a keyboard index and monitors a queue on that
    %   device, with convenience methods for use in a behavioral paradigm. 

    properties
        DevIndex
        Responses
    end

    methods
        function [keyPressed keyCode tPressed] = nextPress(obj)
            bDone = false;
            keyPressed = false;
            keyCode = 0;
            tPressed = -1;
            while ~bDone && KbEventAvail(obj.DevIndex) 
                [event, ~] = KbEventGet(obj.DevIndex);
                %fprintf('code %3d pressed %d t %f\n', event.Keycode, event.Pressed, event.Time);
                if event.Pressed
                    bDone = true;
                    keyPressed = true;
                    keyCode = event.Keycode;
                    tPressed = event.Time;
                end
            end
        end

        
        function obj = responder(index)
            %responder Construct a responder object for device with index.
            %   Detailed explanation goes here
            KbName('UnifyKeyNames');
            % This was the original setup - left and right-hand buttons were different. 
            % obj.Responses = { KbName('1!'), 1; KbName('return'), 0; KbName('2@'), 2; KbName('3#'), 1; KbName('4$'), 2};
            % New version (V2 - 8/22/2024) - center button is "no change",
            % all other buttons are "change". Not asking if change is left
            % or right.
            obj.Responses = { KbName('1!'), 1; KbName('return'), 0; KbName('2@'), 1; KbName('3#'), 1; KbName('4$'), 1};
            obj.DevIndex = index;
            KbQueueCreate(obj.DevIndex);
        end

        function delete(obj)
            KbQueueStop(obj.DevIndex);
            KbQueueRelease(obj.DevIndex);
        end

        function start(obj)
            KbQueueStart(obj.DevIndex);
        end

        function stop(obj, varargin)
        %stop(bFlush=false) Stops the queue, optionally flushes events
        %using flushType=3 (see KbQueueFlush; this type seems to be needed
        %by MilliKey)
            KbQueueStop(obj.DevIndex);
            if nargin > 1 && islogical(varargin{1}) && isscalar(varargin{1}) && varargin{1}
                obj.flush();
            end
        end

        function flush(obj, varargin)
            flushType = 3;
            if nargin > 1
                flushType = varargin{1};
            end
            KbQueueFlush(obj.DevIndex, flushType);
        end

        function dump(obj)
            %dump Dumps all events in queue to screen, for testing.

            while KbEventAvail(obj.DevIndex) 
                [event, ~] = KbEventGet(obj.DevIndex);
                fprintf('code %3d pressed %d t %f\n', event.Keycode, event.Pressed, event.Time);
            end
        end

        function [isResponse, responseIndex, tResponse] = response(obj)
            isResponse = false;
            responseIndex = -999;
            tResponse = -1;

            %look at key PRESSES
            [keyPressed, keyCode, tPressed] = obj.nextPress();
            while keyPressed
                A = cellfun(@(x) any(x==keyCode), obj.Responses(:,1));
                if any(A)
                    if sum(A) > 1
                        error('Found overlapping responses. Check responses arg to responder constructor.');
                    end
                    isResponse = true;
                    tResponse = tPressed;
                    responseIndex = obj.Responses{find(A), 2};
                    break;
                end
            end
        end
     end
end            

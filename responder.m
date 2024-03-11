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
                fprintf('code %3d pressed %d t %f\n', event.Keycode, event.Pressed, event.Time);
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
            obj.Responses = { KbName('1!'), 1; KbName('return'), 0; KbName('2@'), 2 };
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
            KbQueueStop(obj.DevIndex);
            if nargin > 0 && islogical(varargin{1}) && isscalar(varargin{1})
                KbQueueFlush(obj.DevIndex);
            end
        end

        function dump(obj)
            %dump Dumps all events in queue to screen, for testing.

            while KbEventAvail(obj.DevIndex) 
                [event, ~] = KbEventGet(obj.DevIndex);
                fprintf('code %3d pressed %d t %f\n', event.Keycode, event.Pressed, event.Time);
            end
        end

        function [isResponse, responseIndex] = response(obj)
            isResponse = false;
            responseIndex = -999;

            %look at key PRESSES
            [keyPressed, keyCode, tPressed] = obj.nextPress();
            while keyPressed
                A = cellfun(@(x) any(x==keyCode), obj.Responses(:,1));
                if any(A)
                    if sum(A) > 1
                        error('Found overlapping responses. Check responses arg to responder constructor.');
                    end
                    isResponse = true;
                    responseIndex = obj.Responses{find(A), 2};
                    break;
                end
            end
        end
     end
end            

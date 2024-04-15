classdef preamble < handle
    %preamble Instructions, directions, displayed in a pleasing way.
    %   Detailed explanation goes here

    properties
        Script
        TextRect
        DrawRect
        CharWidth
        CharHeight
        TextSize
        OldTextSize
    end

    methods
        function obj = preamble(cmds, textSize)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                cmds (:,2) cell
                textSize (1,1) {mustBeInteger}
            end
            obj.Script = cmds;
            obj.TextSize = textSize;
        end

        function play(obj,w)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            arguments
                obj (1,1) preamble
                w (1,1) {mustBeInteger}
            end

            % Get size of text

            obj.OldTextSize = Screen('TextSize', w, obj.TextSize);
            [~, ~, bbox] = DrawFormattedText(w, 'X',0,0);
            obj.CharWidth = RectWidth(bbox);
            obj.CharHeight = RectHeight(bbox);
            Screen('FillRect', w, [0.5 0.5 0.5]);   % get rid of text drawn for size
            for i=1:size(obj.Script, 1)
                cmd=obj.Script{i, 1};
                args=obj.Script{i, 2};
                fprintf(1, '%s\n', cmd);
                obj.do_cmd(w, cmd, args);
            end     
            Screen('TextSize', w, obj.OldTextSize);
        end

        function do_cmd(obj, w, cmd, args)
            switch(cmd)
                case 'split_screen'
                    proportions = args;  % this should be (1,2) or (2,1)
                    if isempty(proportions); proportions = [1 1]; end
                    rect=Screen('Rect', w);
                    if proportions(1)==0
                        obj.DrawRect = [];
                        obj.TextRect = rect;
                    elseif proportions(2)==0
                        obj.DrawRect = rect;
                        obj.TextRect = [];
                    else
                        yfrac=RectHeight(rect) * proportions(1)/(proportions(1)+proportions(2));
                        obj.DrawRect = rect;
                        obj.DrawRect(4) = obj.DrawRect(2)+yfrac;
                        obj.TextRect = rect;
                        obj.TextRect(2) = obj.TextRect(2)+yfrac;
                    end
                case 'draw'
                    if isa(args, 'function_handle')
                        args(obj.DrawRect);
                    else
                        warning(sprintf('Arg to draw should be a function_handle, i=%d', i));
                    end
                case 'text'
                    DrawFormattedText(w, args, 'center', obj.TextRect(2) + obj.CharHeight, [0,0,0]);
                case 'flip'
                    Screen('Flip', w);
                    WaitSecs(args);
                case 'clear_screen'
                    Screen('Flip', w);
                otherwise
                    fprintf(1, 'Command %s not implemented\n', cmd);
            end
        end
    end
end
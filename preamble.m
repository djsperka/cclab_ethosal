classdef preamble < handle
    %preamble Instructions, directions, displayed in a pleasing way.
    %   p=preamble(cmds, textSize, bbox, imgset)
    %   cmds is a cell array with two columns. Each row is a command
    %   followed by args for that command. See below for commands. 
    %   textSize is the font size to be used (*** see pixdegconverter)
    %   bbox is a responder object
    %   imgset is an imageset for displaying images as needed
    %   
    %   Commands and their args:
    %   'split_screen' The screen is divided (vertically) into a drawing
    %   area (above) and a text area (below). The only arg should be a two
    %   element vector representing the relative proportions of the two
    %   areas. An empty [] is taken to mean [1,1] (evenly divided). 
    %   'mkey' Draw millikey. Args are {frac, button_colors}. 'frac' is
    %   fraction of the largest square that fits in current draw rectangle,
    %   which the drawn mkey fills. 'button_colors' is a 3x5 array, where
    %   each column is the color of the corresponding button. Default is
    %   ones(3,5) - all white buttons. 
    %   'image' An image from the imageset is displayed. Args are the
    %   arguments to imageset.texture (minus the window arg). 
    %   'text' Text is displayed in the Text rectangle.
    %   'flip' After drawing commands (mkey, image, text), this displays.
    %   Optional arg is delay in seconds after the flip. 
    %   'wait_button' Waits until user hits a button on the bbox. First arg
    %   is a vector of buttons you want, e.g. [1,2,3] for top row, [4,5]
    %   for bottom, [1,2,3,4,5] for any button.
    %   'clear_screen' Clears screen to background, no waiting, no args. 

    properties
        Script
        TextYFractionFromTop
        TextYNext
        DrawRect
        CharWidth
        CharHeight
        TextSize
        OldTextSize
        Responder
        Imageset
        IsVerbose
    end

    methods
        function obj = preamble(cmds, textSize, resp, img, beVerbose)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                cmds (:,2) cell
                textSize (1,1) {mustBeInteger}
                resp responder
                img imageset
                beVerbose (1,1) {mustBeNumericOrLogical} = false
            end
            obj.Script = cmds;
            obj.TextSize = textSize;
            obj.Responder = resp;
            obj.Imageset = img;
            obj.IsVerbose = beVerbose;
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

            % DrawRect is entire screen, text location is middle by
            % default.
            obj.DrawRect = Screen('Rect', w)
            obj.TextYFractionFromTop = 0.8;
            obj.TextYNext = obj.TextYFractionFromTop * RectHeight(obj.DrawRect);

            for i=1:size(obj.Script, 1)
                cmd=obj.Script{i, 1};
                args=obj.Script{i, 2};
                if obj.IsVerbose
                    fprintf(1, '%d/%d: %s\n', i, size(obj.Script, 1), cmd);
                end
                obj.do_cmd(w, cmd, args);
            end     
            Screen('TextSize', w, obj.OldTextSize);

        end

        function [ok] = wait_for_button(obj, which_buttons, max_time_secs)
            ok = false;
            startTime = GetSecs;
            obj.Responder.start();
            while GetSecs - startTime < max_time_secs
                [isResp, resp] = obj.Responder.response();
                if isResp && any(resp==which_buttons)
                    ok=true;
                    break;
                end
                WaitSecs(0.5);
            end
            obj.Responder.stop(true);
        end

        function do_cmd(obj, w, cmd, args)
            switch(cmd)
                case 'mkey'
                    obj.mkey(w, obj.DrawRect, args{:});
                case 'image'
                    obj.image(w, obj.DrawRect, args{:});
                case 'text'
                    if length(args{1}) > 0
                        [~, obj.TextYNext, ~, ~] = DrawFormattedText(w, args{1}, 'center', obj.TextYNext + obj.CharHeight, [0,0,0]);
                    end
                    Screen('Flip', w);
                    if isnumeric(args{2})
                        obj.wait_for_button(args{2}, 30);
                    else
                        obj.opmsg_and_wait(args{2});
                    end                    
                case 'flip'
                    Screen('Flip', w);
                    % args are ignored!
                    % WaitSecs(args);
                case 'clear_screen'
                    Screen('Flip', w);
                case 'wait_button'
                    obj.wait_for_button(args, 30);
                case 'operator'
                    obj.opmsg_and_wait(w, args);
                case 'slide'
                    % equivalent of 
                    % 'image', {args{1}}; ...
                    % 'text', args{2}; ...
                    % 'flip', 0.0; ...
                    % If the third arg is numeric, then
                    % 'wait_button', args{3}; ...
                    % If its char, then print to screen and wait 
                    % for a keypress
                    % 'operator', args{3}; ...
                    
                    obj.image(w, obj.DrawRect, args{1});
                    if length(args{2}) > 0
                        obj.TextYNext + obj.CharHeight
                        [~, obj.TextYNext, ~, ~] = DrawFormattedText(w, args{2}, 'center', obj.TextYNext + obj.CharHeight, [0,0,0]);
                    end
                    Screen('Flip', w);
                    if isnumeric(args{3})
                        obj.wait_for_button(args{3}, 30);
                    else
                        obj.opmsg_and_wait(args{3});
                    end
                        
                otherwise
                    fprintf(1, 'Command %s not implemented\n', cmd);
            end
        end
    end

    methods (Access = private)

        function mkey(obj, w, rect, square_fraction, buttonColors)
        %drawMKey Draw millikey in center of rectangle.
        %   Detailed explanation goes here

            arguments
                obj (1,1) preamble
                w (1,1) {mustBeInteger}
                rect (1,4) 
                square_fraction (1,1) {mustBeFloat(square_fraction), mustBeInRange(square_fraction, 0, 1)} = 1
                buttonColors (3,5) = ones(3,5)
            end
            [rectCenterX, rectCenterY] = RectCenter(rect);
        
            % Determine largest square that will fit....
            if RectWidth(rect) > RectHeight(rect)
                d = RectHeight(rect) * square_fraction;
            else
                d = RectWidth(rect) * square_fraction;
            end
            useThisRect = CenterRectOnPoint([0, 0, d, d], rectCenterX, rectCenterY);
        
            rowHeight = RectHeight(useThisRect)/3;
            qWidth = RectWidth(useThisRect)/4;
            boxRect = SetRect(useThisRect(1), useThisRect(2) + rowHeight, useThisRect(3), useThisRect(4));
            buttonRect = [0, 0, qWidth/2, qWidth/2];
            buttonX = useThisRect(1) + [ qWidth, 2*qWidth, 3*qWidth, 1.5*qWidth, 2.5*qWidth]';
            buttonY = useThisRect(2) + [1.5*rowHeight, 1.5*rowHeight, 1.5*rowHeight, 2.5*rowHeight, 2.5*(rowHeight)]';
            buttonRects = CenterRectOnPoint(buttonRect, buttonX, buttonY);
        
            Screen('FillRect', w, 0, boxRect);
            Screen('DrawLine', w, 0, rectCenterX, useThisRect(2) + rowHeight, rectCenterX, useThisRect(2), 4);
            Screen('FillOval', w, buttonColors, buttonRects');
        
        end

        function image(obj, w, rect, varargin)
            t=obj.Imageset.texture(w, varargin{:});
            if isscalar(t)
                [x, y] = RectCenter(rect);
                Screen('DrawTexture', w, t, [], CenterRectOnPoint(obj.Imageset.UniformOrFirstRect, x, y));
            else
                [nrows,ncols]=size(t);
                [rects, x, y] = divvyRect(rect, nrows, ncols);
                Screen('DrawTextures', w, t(:), [], CenterRectOnPoint(obj.Imageset.UniformOrFirstRect', x', y'))
            end
        end

        function opmsg_and_wait(obj, msg)
            fprintf(1, '%s\n', msg);
            fprintf(1, 'Hit any key to continue preamble.\n');
            KbWait;
            WaitSecs(0.2);
        end

    end

end
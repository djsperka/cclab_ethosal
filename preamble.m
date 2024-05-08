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
        TextRect
        DrawRect
        CharWidth
        CharHeight
        TextSize
        OldTextSize
        Responder
        Imageset
    end

    methods
        function obj = preamble(cmds, textSize, resp, img)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                cmds (:,2) cell
                textSize (1,1) {mustBeInteger}
                resp responder
                img imageset
            end
            obj.Script = cmds;
            obj.TextSize = textSize;
            obj.Responder = resp;
            obj.Imageset = img;
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
                case 'mkey'
                    obj.mkey(w, obj.DrawRect, args{:});
                case 'image'
                    obj.image(w, obj.DrawRect, args{:});
                case 'text'
                    if length(args) > 0
                        [~, ny, ~, ~] = DrawFormattedText(w, args{1}, 'center', obj.TextRect(2) + obj.CharHeight, [0,0,0]);
                        if length(args)>1
                            DrawFormattedText(w, args{2}, 'center', ny+2*obj.CharHeight, [0,0,0]);
                        end
                    end
                case 'flip'
                    Screen('Flip', w);
                    WaitSecs(args);
                case 'clear_screen'
                    Screen('Flip', w);
                case 'wait_button'
                    obj.wait_for_button(args, 30);
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
            [x, y] = RectCenter(obj.DrawRect);
            Screen('DrawTexture', w, t, [], CenterRectOnPoint(obj.Imageset.UniformOrFirstRect, x, y));
        end

    end

end
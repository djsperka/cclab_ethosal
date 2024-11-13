function [status] = placedots(w, screenWidthMM, eyedistMM)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

    screenRect = Screen('Rect', w);
    cnv = pixdegconverter(screenRect, screenWidthMM, eyedistMM);

    % shape and size (degrees) of probe box
    pbSizeDeg = 0.25;
    pbRect = [0 0 cnv.deg2pix(pbSizeDeg) cnv.deg2pix(pbSizeDeg)];

    while true

        s = input('Coordinates (q to quit): ', 's');
        X = sscanf(s, '%d %d', [1 2]);
        if strcmp(s, 'q')
            break;
        elseif isnumeric(X) && length(X)==2
            xy = cnv.deg2scr(X);
            Screen('FillRect', w, [0 0 0], CenterRectOnPoint(pbRect, xy(1), xy(2)));
            Screen('Flip', w);
        end

    end        

    status = 1;
end
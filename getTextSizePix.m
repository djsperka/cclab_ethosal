function textSize = getTextSizePix(minPixels, w);
%getTextSizePix Find a text size that yields characters at least as large
%as minPixels. Uses 'X' as test character.
%   Detailed explanation goes here
    
    string='X';
    yPositionIsBaseline=0; % 0 or 1
    textSize = -1;
    ts = 10;
    while textSize < 0 && ts<100
        woff=Screen('OpenOffscreenWindow',w,[],[0 0 2*ts*length(string) 2*ts]);
        Screen(woff,'TextFont','Arial');
        Screen(woff,'TextSize',ts);
        bounds=TextBounds(woff,string,yPositionIsBaseline);
        if max(bounds(3),bounds(4)) > minPixels
            textSize = ts;
        end
        ts = ts+1;
        Screen('Close',woff);
    end

end
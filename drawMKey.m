function drawMKey(w, rect, buttonColors)
%drawMKey Summary of this function goes here
%   Detailed explanation goes here

    arguments
        w (1,1) {mustBeInteger}
        rect (1,4) 
        buttonColors (3,5) = ones(3,5)
    end
    [rectCenterX, rectCenterY] = RectCenter(rect);
    rowHeight = RectHeight(rect)/3;
    qWidth = RectWidth(rect)/4;
    boxRect = SetRect(rect(1), rect(2) + rowHeight, rect(3), rect(4));
    buttonRect = [0, 0, qWidth/2, qWidth/2];
    buttonX = rect(1) + [ qWidth, 2*qWidth, 3*qWidth, 1.5*qWidth, 2.5*qWidth]';
    buttonY = rect(2) + [1.5*rowHeight, 1.5*rowHeight, 1.5*rowHeight, 2.5*rowHeight, 2.5*(rowHeight)]';
    buttonRects = CenterRectOnPoint(buttonRect, buttonX, buttonY);

    Screen('FillRect', w, 0, boxRect);
    Screen('DrawLine', w, 0, rectCenterX, rect(2) + rowHeight, rectCenterX, rect(2), 4);
    Screen('FillOval', w, buttonColors, buttonRects');

end
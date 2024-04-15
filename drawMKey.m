function drawMKey(w, rect, square_fraction, buttonColors)
%drawMKey Summary of this function goes here
%   Detailed explanation goes here

    arguments
        w (1,1) {mustBeInteger}
        rect (1,4) 
        square_fraction (1,1) {mustBeFloat(square_fraction), mustBeInRange(square_fraction, 0, 1)} = 1
        buttonColors (3,5) = ones(3,5)
    end
    [rectCenterX, rectCenterY] = RectCenter(rect);

    fprintf(1, 'drawMKey...\n');
    rect
    square_fraction
    buttonColors

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
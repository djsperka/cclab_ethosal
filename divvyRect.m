function [rects,x,y] = divvyRect(rect, nrows, ncols)
%divvyRect(rect, nrows, ncols) Divide rect into a grid of equal sized rects.
%   Returned array is 4x(nrows*ncols), where each column is a rect. The
%   rects are ordered by row, then column (i.e. (r1,c1), (r2, c1),...
    theight = RectHeight(rect)/nrows;
    twidth = RectWidth(rect)/ncols;
    rects = zeros(4, nrows*ncols);
    for icol=1:ncols
        for irow=1:nrows
            rects(:,(icol-1)*nrows+irow) = [(icol-1)*twidth;(irow-1)*theight;icol*twidth;irow*theight];
        end
    end
    [x, y] = RectCenter(rects);
end
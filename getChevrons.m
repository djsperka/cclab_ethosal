function [n,linesegments] = getChevrons(p,vdir,dpix,ipix,lpix,tpix,just1)
%getChevrons Generate line segments that draw a series of chevrons
%   Chevrons are drawn along a line segment starting at p, along the
%   direction vdir, for a distance d. The chevrons are drawn with
%   parameters lpix (longitudinal component), tpix (transverse), and ipix
%   (spacing from tip of one chevron to start of next). If just1 is true,
%   then just return a single chevron (arrowhead?) at the endpoint.

    arguments
        p (2,1) {mustBeNumeric}
        vdir (2,1) {mustBeNumeric}
        dpix (1,1) {mustBeNumeric}
        ipix (1,1) {mustBeNumeric}
        lpix (1,1) {mustBeNumeric}
        tpix (1,1) {mustBeNumeric}
        just1 (1,1) {mustBeNumeric} = 0
    end

    % make sure direction vector is a unit vector. Make perpendicular
    % (transverse) vector.
    v = vdir/vecnorm(vdir);
    vt = [v(2); -v(1)];
 
    % How many will fit in the distance d?
    pixPerChevron = ipix + lpix;  % pixels along direction v

    if ~just1

        n = floor(dpix/pixPerChevron);
        linesegments = zeros(2,n*4);
        
        % There will be a slightly uneven division of space at front and end of the
        % chevron's because I'm being a little lazy.
        for i=1:n
            % Each line segment requires two points, and each chevron requires two
            % segments. 
            i0 = (i-1)*2;
            linesegments(:, i0*i + 1) = p + (i0*pixPerChevron + lpix)*v;
            linesegments(:, i0*i + 2) = p + (i0*pixPerChevron)*v + tpix*vt;
            linesegments(:, i0*i + 3) = p + (i0*pixPerChevron + lpix)*v;
            linesegments(:, i0*i + 4) = p + (i0*pixPerChevron)*v - tpix*vt;
        end
    else
        n = 1;
        linesegments = zeros(2,4);
        linesegments(:, 1) = p + dpix*v;
        linesegments(:, 2) = p + (dpix-lpix)*v + tpix*vt;
        linesegments(:, 3) = p + dpix*v;
        linesegments(:, 4) = p + (dpix-lpix)*v - tpix*vt;
    end
end
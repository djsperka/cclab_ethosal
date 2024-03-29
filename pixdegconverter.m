classdef pixdegconverter
    %pix_deg_converter Does deg <--> pixel conversions for a given setup, 
    %   and coordinate transformations from eye space (center of screen 
    %   is origin in degrees, positive degrees up & right) to screen space
    %   (origin top right, positive pixels down).
    %   Unsophisticated conversion. Assumes small angles, because we're
    %   taking tan(theta) = theta, and we don't care how big the number
    %   really is. Instantiate this in one of two ways. First, if you hvae
    %   a "rig" situation, where full screen is used, you've measured it
    %   and the eye distance is known. In this case, instantiate with
    %   pixdegconverter(rect, screen_width_mm, eye_dist_mm). Second, if
    %   you are using a small window for testing, instantiate with 
    %   pixdegconverter(rect, fovx), where fovx is desired field of view 
    %   in x), and the converter will simulate that system. 
    
    properties (Access = private)
        PPD
        W
        H
    end
    
    methods
        function obj = pixdegconverter(rect, varargin)
            %pix_deg_converter Construct an instance of this class
            %   Detailed explanation goes here
            obj.W = rect(3);
            obj.H = rect(4);
            if nargin == 2
                obj.PPD = rect(3)/varargin{1};
            elseif nargin == 3
                % args should be (rect, screenWidth, eyeDist), both in same
                % dimensions.
                fovx = atan2(varargin{1}/2, varargin{2}) * 180 / pi;
                obj.PPD = rect(3) / fovx;
            else
                error('One or two args to pixdeg converter');
            end
        end
        
        function PIX = deg2pix(obj, DEG)
            %deg2pix Convert values from degrees to pixels. 
            %   Use this for lengths, e.g. diameter, not coordinates. See deg2scr for x,y pairs.
            PIX = arrayfun(@(deg) obj.PPD*deg, DEG);
            if ~isscalar(DEG)
                warning('Using deg2pix on a non-scalar object. Use this method for lengths, use deg2scr to get screen coordinates.');
            end
        end
        
        function SCRPAIRS = deg2scr(obj, DEGPAIRS)
            %deg2scr Convert eye coord degrees x,y pairs to PTB screen
            %coords. Input must be nx2.
            
            if size(DEGPAIRS, 2) ~= 2
                error('deg2scr inputs must be Nx2');
            end
            SRCX = arrayfun(@(xdeg) obj.PPD*xdeg+obj.W/2, DEGPAIRS(:,1));
            SRCY = arrayfun(@(ydeg) -obj.PPD*ydeg+obj.H/2, DEGPAIRS(:,2));
            SCRPAIRS = horzcat(SRCX, SRCY); 
        end
        
        function DEG = pix2deg(obj, PIX)
            %deg2pix Summary of this method goes here
            %   Detailed explanation goes here            
            DEG = arrayfun(@(pix) pix/obj.PPD, PIX);
            if ~isscalar(PIX)
                warning('Using pix2deg on a non-scalar object. Use this method for lengths, not coordinates.');
            end
        end

    end
end


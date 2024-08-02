classdef AnimMgr < handle
    %AnimMgr Manages simple animations.
    %   Create a callback that looks like this
    %   callbackFunc(v,minmax,w,C)
    %   where v = value that animate() was called with,
    %   minmax is the min and max values the animator recognizes,
    %   w is the window index for drawing
    %   C is a cell supplied by user with data of your choosing
    % 
    %   Usage would be 
    %   
    %   C = { 'one', 'two', 'three', 'four', five' };
    %   am = AnimMgr([0,5], @callbackFunc, C);
    %
    %   t0 = GetSecs();
    %   elapsed = 0;
    %   while elapsed < 6
    %      if am.animate(elapsed)
    %        Screen('Flip', w);
    %      end
    %   end


    properties (Access = private)
        Callback
        UserData
        MinMax
        Started
        TeeZero
    end

    methods
        function obj = AnimMgr(minmax, cbFnc, userData)
            %AnimMgr Manage one or more animations
            %   Each animator needs a [min,max], a callback, and an
            %   optional cell of user data.

            obj.MinMax = minmax;
            obj.Callback = cbFnc;
            obj.UserData = userData;
            obj.Started = false;
            obj.TeeZero = -1;
        end

        function start(obj, varargin)
            obj.Started = true;
            obj.TeeZero = GetSecs;
            if nargin>1
                obj.UserData = varargin{1};
            end
        end

        function stop(obj)
            obj.Started = false;
            obj.TeeZero = -1;
        end

        function tf = animate(obj,w)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            if ~obj.Started
                error('AnimMgr is not started. Call start()');
            end
            tf = false;
            t1 = GetSecs;
            t = t1 - obj.TeeZero;
            if t >= obj.MinMax(1) && t <= obj.MinMax(2)
                [tfThisCallback, D] = obj.Callback(t, obj.MinMax, w, obj.UserData);
                obj.UserData = D;
                if tfThisCallback
                    tf = true;
                end
            end
        end
    end
end
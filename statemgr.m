classdef statemgr < handle
    
    %statemgr Keeps track of current state and when it started.
    %   This is a convenience class for keeping track of the current state,
    %   and when we entered this state. Call transitionTo('newState') when
    %   changing state - the start time of the new state is recorded.
    %   Properties are read-only (you set them when you call transitionTo).
    %
    %   statemgr Properties:
    %      Current - current state
    %      StartedAt - time that current state started
    %      Verbose - if true, prints msg on transitions
    %
    %   statemgr Methods:
    
    properties (SetAccess = private)
        Current
        StartedAt
        Verbose
    end
    
    methods
        function obj = statemgr(varargin)
            %statemgr Construct an instance of this class
            %   First arg (required) is initial state.
            %   Second arg can be true to make verbose
            if nargin == 0
                error('Must supply initial state: statemgr(''state''[, tfVerbose=false]');
            end
            if ~ischar(varargin{1})
                error('First arg must be char state name');
            end
            obj.Current = varargin{1};
            obj.StartedAt = GetSecs;
            obj.Verbose = false;
            if nargin >1 
                if islogical(varargin{2}) && isscalar(varargin{2})
                    obj.Verbose = varargin{2};
                else
                    error('Second arg must be logical true|false');
                end
            end
        end
        
        function [previousState, previousStateStartedAt] = transitionTo(obj,varargin)
            %transitionTo Change state and record transition time.
            %   transitionTo(obj, 'newState') - change current state to 
            %   'newState', the current time is recorded  with GetSecs. 
            %   transitionTo(obj, 'newState', startTime) - same but uses 
            %   startTime as the newState starting time. 
            %   Returns previous state and time. 
            %   If this obj is verbose, prints the old state, new state,
            %   and the time spent in the old state. 
            previousState = obj.Current;
            previousStateStartedAt = obj.StartedAt;
            if nargin > 1
                obj.Current = varargin{1};
                if nargin > 2                       % nargin counts the obj arg
                    obj.StartedAt = varargin{2};    % caller supplied the start time
                else
                    obj.StartedAt = GetSecs;
                end
            else
                error('transitionTo requires at least one arg.');
            end
            if obj.Verbose
                fprintf('statemgr: %s (%fsec) ==>> %s\n', previousState, obj.StartedAt-previousStateStartedAt, obj.Current);
            end
        end
        
        function [deltaT, gsecs] = timeInState(obj, varargin)
            %timeInState Returns time spent in current state. 
            %   [deltaT, gsecs] = timeInState(obj) - use GetSecs
            %   [deltaT, gsecs] = timeInState(obj, t) - use t to measure
            %   relative time spent in state. 
            %   Returns the time difference, and the time used to measure
            %   it.
            if nargin > 1
                gsecs = varargin{1};
            else
                gsecs = GetSecs;
            end
            deltaT = gsecs - obj.StartedAt;
        end
    end
end


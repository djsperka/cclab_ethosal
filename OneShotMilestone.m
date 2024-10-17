classdef OneShotMilestone < handle
    %OneShotMilestone Class to find when a monotonically increasing value
    %equals or passes one of a set of milestones. 
    %   Useful for this: you want to show a message to the user at the 1/4,
    %   1/2, and 3/4 marks of a block of trials. Create a OneShotMilestone 
    %   with [0.25, 0.5, 0.75]) as its lone arg. As your trials progress,
    %   you pass the fraction (trial#)/(total#of trials in block) to the 
    %   pass() method. If an index is returned, then that milestone was
    %   passed, and do the thing you wanted to do. 
    %   
    %   mst = OneShotMilestone([.25,.5,.75]);
    %   ...
    %   while (itrial < nTrialsInBlock)
    %      itrial = itrial+1;
    %      % run trial....
    %      % .............
    %      ind = mst.pass(itrial/nTrialsInBlock);
    %      if isempty(ind)
    %      %  whatevs....no milestone passed
    %      elseif isscalar(ind)
    %
    %      % single milestone passed, draw text for this milestone on
    %      % screen....
    %
    %      else
    %
    %      % you decide what to do here. More than one milestone passed at
    %      % once, so I would only draw the text for the last of the passed
    %      % milestones.
    %
    %      end
    %   end

    properties
        Milestones
        MilestonesPassed
    end

    methods
        function obj = OneShotMilestone(milestones)
            %OneShotMilestone Construct an instance of this class
            %   Detailed explanation goes here
            if ~isnumeric(milestones) || ~isvector(milestones)
                error('Milestones must be a numeric vector');
            end

            obj.Milestones = milestones;
            obj.MilestonesPassed = false(size(milestones));

        end


        function would_pass = check(obj, f)
            %check(f) Return true if a milestone (not already passed) 
            %would be passed with the value given. The milestones are not
            %marked as passed, however! Must call pass() for that. 
            %   Detailed explanation goes here

            passing_ind = find(~obj.MilestonesPassed & f >= obj.Milestones);
            would_pass = ~isempty(passing_ind);

        end

        function [passed, milestonesPassed] = pass(obj, f)
            %check(f) Return index of milestone (not already passed) 
            %where f>milestone. The result can be an empty vector, a scalar
            %index, or a vector of indices. Passed milestones are marked 
            %and will not be passed again before a reset().
            %   Detailed explanation goes here

            passed = find(~obj.MilestonesPassed & f >= obj.Milestones);
            milestonesPassed = obj.Milestones(passed);
            obj.MilestonesPassed(passed) = true;

        end

        function reset(obj,varargin)
            %reset(obj, index) Resets the milestone at index to un-passed.
            %reset(obj) Resets all milestones to un-passed.
            if nargin == 1
                obj.MilestonesPassed(:) = false;
            elseif nargin == 2
                obj.MilestonesPassed(varargin{1}) = false;
            else
                error('reset expecting 0 or 1 arg')
            end
        end

    end
end
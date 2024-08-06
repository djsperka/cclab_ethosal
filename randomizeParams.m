function [t] = randomizeParams(varargin)
%randomizeParams Generate a table randomized over a set of parameters. 0
%   Each of the first parameters is combined with each of the second, each
%   of which is combined with the next parameter, and so on. The cell
%   array reps determines the order and multiplicity at each step. 
%
%   e.g. 
%   numImages = 30;
%   imageIndices = randperm(imgset.BalancedFileKeys(1:100), numImages);
%   reps{1} = imgset.BalancedFileKeys(imageIndices);

    
    p = inputParser;
    %p.addOptional('Multiplicities',[],@(x) isnumeric(x) && isvector(x));
    %p.addRequired('Multiplicities', @(x) isnumeric(x) && isvector(x));
    p.addParameter('VariableNames', {}, @(x) iscell(x));
    p.addParameter('Replacements', {}, @(x) iscell(x));
    p.parse(varargin{:});

    % should check params more carefully
    if ~isempty(p.Results.VariableNames) && ~isempty(p.Results.Replacements)
        if size(p.Results.VariableNames, 1) ~= size(p.Results.Replacements, 1)
            error('VariableNames and Replacements should have same number of columns');
        end
    end

    t = [];

    % get multiplicities from the size of first dim of each element (the
    % height of each one).
    m = cellfun(@(x) size(x,1), p.Results.Replacements);
    n = prod(m);
    
    % generate list of values. Each value is a comb of params.
    z = randperm(n) - 1;
    pind = zeros(n, length(m));
    for i=1:n
        v = z(i);
        for j=length(m):-1:1
            pind(i, j) = rem(v, m(j)) + 1;
            v = fix(v/m(j));
        end
    end
    t = table;
    for i=1:length(m)
        if ~isempty(p.Results.Replacements)
            if ~isempty(p.Results.Replacements{i})
                s=size(p.Results.Replacements{i});
                if s(2)==1 && s(1)==m(i)
                    A = p.Results.Replacements{i}(pind(:,i));
                else
                    error('Replacements must be empty {} or column vectors with same multiplicity as corresponding column');
                end
            else
                A = pind(:, i);
            end
        else
            A = pind(:, i);
        end
        t{:,i} = A;
    end
    if ~isempty(p.Results.VariableNames)
        t.Properties.VariableNames = p.Results.VariableNames;
    end
end
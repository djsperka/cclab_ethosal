function [t] = randomizeParams(varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    
    p = inputParser;
    p.addRequired('Multiplicities', @(x) isnumeric(x) && isvector(x));
    p.addParameter('VariableNames', {}, @(x) iscell(x) && (length(x)==0 || length(x)==length(p.Results.Multiplicities)));
    p.addParameter('Replacements', {}, @(x) iscell(x) && (length(x)==0 || length(x)==length(p.Results.Multiplicities)));
    p.parse(varargin{:});

    t = [];
    m = p.Results.Multiplicities;
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
%     t = array2table(pind);
% 
%     if ~isempty(p.Results.VariableNames)
%         t.Properties.VariableNames = p.Results.VariableNames;
%     end
% 
%     if ~isempty(p.Results.Replacements)
%         for i=1:length(m)
%             if ~isempty(p.Results.Replacements{i})
%                 r = p.Results.Replacements{i};
%                 t(:,i) = r(t{:,i});
%             end
%         end
%     end
end
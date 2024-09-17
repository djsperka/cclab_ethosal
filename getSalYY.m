function [rr] = getSalYY(a,b)
%getSalYY Call with cellfun, expect a='anaeth' or 'anaethV2', and b=cell
%array of filenames.
%   Return two element row vector. First element is HL-HH, second element is
%   LL-LH. 

    rr=zeros(1,2);
    if strcmp(a,'anaeth')
        [rates, ~, ~] = anaeth(catres(b));
        rr(1) = rates.dpHL-rates.dpHH;
        rr(2) = rates.dpLL-rates.dpLH;
    elseif strcmp(a, 'anaethV2')
        [rates,~] = anaethV2(catres(b));
        rr(1) = rates.dpHL-rates.dpHH;
        rr(2) = rates.dpLL-rates.dpLH;
    end

end
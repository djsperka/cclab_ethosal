function [tf] = isValidEthologTrialsInput(tors)
    tf = 0;
    if istable(tors)
        tf = 1;
    elseif isstruct(tors)
        expectedFieldnames = {'trials', 'outputbase', 'goaldirected', 'text'};
        tf = all(ismember(expectedFieldnames, fieldnames(tors)));
    end
end        

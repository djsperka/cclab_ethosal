function [ind] = getKeyboardIndex(strNameToMatch)
%getKeyboardIndex(name) Returns the index for the keyboard named "name".
%getKeyboardIndex() Prints a list of keyboard names and their indices.
    arguments
        strNameToMatch (1,1) string
    end

    [indices, names, ~]=GetKeyboardIndices;

    if strlength(strNameToMatch) > 0
        l = (names==strNameToMatch);
        if sum(l) == 0
            error('Keyboard name "%s" not found.\n', strNameToMatch);
        elseif sum(l) > 1
            % this probably shouldn't happen? 
            error('Multiple keyboards found with name "%s".\n', strNameToMatch);
        else
            ind = indices(l);
        end
    else
        for i=1:length(indices)
            fprintf('%d %s\n', indices(i), names{i});
        end
    end


end
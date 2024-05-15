function [ind] = getKeyboardIndex(varargin)
%getKeyboardIndex(name) Returns the index for the keyboard named "name".
%getKeyboardIndex() Prints a list of keyboard names and their indices.

    % expect char arg 'Keyboard name' or '' (same as no arg) or '?'. 
    % 'Keyboard name' will attempt to file exact match.
    % '' or () will print list of indices and keyboard names.
    % '?' will print and query and test selection.

    bQueryAndTest = false;
    if nargin==1
        if ischar(varargin{1})
            if strcmp(varargin{1}, '?')
                bQueryAndTest = true;
                strNameToMatch = '';
            else
                strNameToMatch = varargin{1};
            end
        else
            strNameToMatch = '';
        end
    elseif nargin==0
        strNameToMatch = '';
    else
        error('0 or 1 arg, please.');
    end
        

    [indices, names, ~]=GetKeyboardIndices;

    if strlength(strNameToMatch) > 0
        l = ismember(names, {strNameToMatch});
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


        if bQueryAndTest
            [indx, tf] = listdlg('PromptString', 'Select a keyboard.', 'ListString', names, 'SelectionMode', 'single');
            if tf
                ind = indices(indx);
            end
        end

    end

end
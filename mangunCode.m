function [code_or_struct] = mangunCode(arg1, base)
%mangunCode Encodes a trial's parameters into an EEG code, or decodes same
%into consituent trial parameters. 
%   The second argument should always be the base used for the code. The
%   encoded integer (between 0-31) is added to the base if 'arg1' is a
%   table - i.e. a trial passed from ethologV2 for encoding. If 'arg1' is
%   numeric, it is interpreted as a code, and we decode it here and return
%   a struct with fields validCode, cuedSalience, uncuedSalience, and
%   change. NOTE: 'validCode' and 'change' are numeric 1 (true) or
%   0(false). 'cuedSalience' and 'uncuedSalience' are 0 for HIGH SALIENCE
%   and 1 for LOW SALIENCE. 
%
%   PLEASE BE CAREFUL - the salience values might be opposite what you
%   expect!



    % check the base value.
    if ~isnumeric(base) || ~isscalar(base) || base < 0 || base > 224
        error('base must be scalar 0 < x < 225');
    end

    if istable(arg1)
        % encode
        trial = arg1;
        code_or_struct = base;
    
        % lowest bit (bit 0) is whether cue is valid. 
        if trial.CueSide == trial.StimTestType
            code_or_struct = code_or_struct + 1;
        end
    
        % bit 1 is the salience of cued side (0=HIGH, 1=LOW)
        % bit 2 is salience of un-cued side (0=HIGH, 1=LOW)
        if trial.CueSide==1
            code_or_struct = code_or_struct + 2*(trial.Folder1KeyRow -1) + 4*(trial.Folder2KeyRow - 1);
        elseif trial.CueSide == 2
            code_or_struct = code_or_struct + 2*(trial.Folder2KeyRow -1) + 4*(trial.Folder1KeyRow - 1);
        else
            error('CueSide is %d, not handled', trial.CueSide);
        end
    
        % bit 3 is whether the tested side changed (1=change, 2=no change)
        code_or_struct = code_or_struct + 8*trial.StimChangeTF;

    else
        value = arg1 - base;
        if value < 0 || value > 31
            error('Cannot decode, value out of range 0 <= value <= 31');
        end

        code_or_struct = struct;
        code_or_struct.validCue = bitget(value, 1);
        code_or_struct.cuedSalience = bitget(value, 2);
        code_or_struct.uncuedSalience = bitget(value, 3);
        code_or_struct.change = bitget(value, 4);
    end


end


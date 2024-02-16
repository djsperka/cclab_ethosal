function [keyboardIndices]= cclabGetMilliKeyIndices()
% [keyboardIndices] = GetMilliKeyIndices()
%
% The PsychHID assigns each USB HID device connected to you computer a
% unique index. GetMilliKeyIndices returns the indices for those HID
% devices which are "LabHackers MilliKey". Based on 'GetKeyboardIndices',
% and assumes that the device is a "floating slave" device. This is
% achieved using the file '99-millikey-float.conf', placed in the
% xorg.conf.d folder. Yes, this will probably only work on linux. 
% 

% HISTORY
% 3/14/23     djs Modified GetKeyboardIndices.


% Init:
keyboardIndices=[];

% Enumerate all HID devices:
if ~IsLinux
    error('GetMilliKeyIndices will only work on linux');
else
    LoadPsychHID;
    d = PsychHID('Devices', 5);
end

% Iterate through all of them:
for i =1:length(d);
    % Keyboard or keyboard-like device?
    if strcmpi(d(i).product, 'LabHackers MilliKey')
        keyboardIndices(end+1)=d(i).index; %#ok<AGROW>
    end
end

return;

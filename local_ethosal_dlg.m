% Expecting to find 'local_ethosal' in your path
if isempty(which('local_ethosal'))
    error('Cannot find script local_ethosal.m - needed to set file locations on this machine.');
end
local_ethosal
ethodlg_exported(ethDataRoot, ethImgRoot);
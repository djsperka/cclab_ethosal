% Copy this file to your MATLAB path - a good place is 'userpath'
% >> userpath
%
% ans =
%
%     '/home/dan/Documents/MATLAB'
%
% this way your changes will not get picked up by git, and it's always
% available - you just type 'local_ethosal' to get the folders. 
%
% These folders point to fixed data locations used by the ethological
% salience code. 

%
% ethDataRoot is the location of an 'input' and 'output' folder. The
% 'input' folder is where we find input trials or blocks in *.mat files.
%

ethDataRoot='/home/dan/work/cclab/ethdata/';

%
% ethImgRoot is the location of the cclab-images archive. Expectuing
% subfolders of this root to have imagesets, and their associated params
% files. 
%

ethImgRoot='/home/dan/work/cclab/cclab-images/';

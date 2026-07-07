% load blockset
Y=load("C:/Users/cclab/Desktop/work/data/input/rimg_exp_60-20-left-A.mat");
%N=size(Y.blockset, 1);
N=8;
V=[];

% loop over blocks. Get all imagepairindices, along with their file keys. 
% Convert filekeys to integers to store in an array with image pair index.
% for i=1:N
%     IPI = Y.blockset(i).trials.ImagePairIndex;
%     F = Y.blockset(i).trials.File1Key;
%     FN = cellfun(@(x) str2num(x), F);
%     V=vertcat(V,[IPI,FN]);
%     size(V)
% end

for i=1:N
    IPI = Y.blocks{i}.ImagePairIndex;
    F = Y.blocks{i}.File1Key;
    FN = cellfun(@(x) str2num(x), F);
    V=vertcat(V,[IPI,FN]);
    size(V);
end



% sort on image pair index column (1)
Vsorted = sortrows(V);

% get unique pairs - this is what we need
% The first column is the (sorted) image pair index.
% This should be 1-N, where N is 80 for a LR set
U = unique(Vsorted, 'rows');

% In the color set, theimage pair index only runs 
% from 1-40. 
% File1Key = num2str(U(tab.ImagePairIndex, 2))


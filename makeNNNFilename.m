function [filenameOK, filename] = makeNNNFilename(folder, base)
%makeNewFilename(folder, basename) Forms a filename (after substitutions
%and checks whether it exists. If basename ends in any sequence of 'N',
%prior to the decimal, then consecutive digit values (with leading 0 if
%needed) are substituted until a free filename is found. Returns true if
%filename does not exist, and its a good "new" filename.

% see if base has iterator
[startInd, endInd] = regexp(base, '[N]+[.]');
if isempty(startInd)
    filename=fullfile(folder, base);
    filenameOK=~isfile(filename);
else
    fmt = sprintf('%%0%dd', endInd-startInd);
    i=0;
    imax = 10^(endInd-startInd);
    filenameOK=false;
    while ~filenameOK && i<imax
        trybase=replace(base, base(startInd:endInd-1), sprintf(fmt, i));
        filename=fullfile(folder, trybase);
        filenameOK=~isfile(filename);
        %fprintf(1, '%d %d %s\n', i, imax, trybase);
        i = i + 1;
    end
end
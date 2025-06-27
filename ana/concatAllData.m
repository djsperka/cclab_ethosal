% Concatenate all tables found in the folder below. 
% Load mat files, assumed to be results from ethosal.
% Add columns to each results table to denote the subject ID, input file
% base, block number, and the date/time data was collected. 
% As for a file to store the big table.

% Folder with all the mat files
folder='/home/dan/work/cclab/ethdata/EthologicalSalience/Ethdata/Interaction';

% list all mat files in folder
list = dir(fullfile(folder, '*.mat'));

% output initially empty, vertcat onto this.
output = [];

% load each file, append extra columns, vertcat to output
for i=1:length(list)

    Y=load(fullfile(list(i).folder, list(i).name));
    results = Y.results;


    % parse filename for parts
    % regex relies on the filename format:  
    % 
    % date_subjID_filebase_blkN
    %
    % 1 date in format YYYY-mm-dd-HHMM
    % 2 subjID is the subjectID entered at time of data collection
    % 3 filebase is the basename of the input data file (the mat file)
    % 4 N is the block number
    % 

    r=regexp(list(i).name, '^(\d{4}-\d{2}-\d{2}-\d{4})_([^_]+)_(.*)_blk(\d+)\.mat', 'tokens');

    % 'tokens' gets us the subgroups, returned as a cell array. 
    % There should only be a single match, and we expect each filename to
    % match!
    % The first match (entire pattern) is r{1}{1}. The subgroups follow:
    % the first subgroup (the part in the first pair of parentheses)
    fprintf('%d: %s %s %s\n', i, r{1}{2}, r{1}{3}, r{1}{4});

    % make a column vector, same height as the results table we just
    % loaded, with the values we just extracted from the filename.
    clear('DateTime', 'SubjID', 'InfileBase', 'BlockNum');
    DateTime(1:height(results), 1) = {r{1}(1)};
    SubjID(1:height(results), 1) = repmat(r{1}(2), height(results), 1);     %{r{1}(2)};
    InfileBase(1:height(results), 1) = {r{1}(3)};
    BlockNum(1:height(results), 1) = str2num(r{1}{4});

    Z = addvars(results, DateTime, SubjID, InfileBase, BlockNum, 'Before','ImagePairIndex');
    output = [output; Z];
end

[fname, loc] = uiputfile('','Save filename');
fprintf('saving %s\n', fullfile(loc, fname));
save(fullfile(loc, fname), "output", "-mat");
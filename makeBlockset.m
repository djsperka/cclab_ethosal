local_ethosal;   % get directory vars

%% must have L and R - loaded from etholog input file
if ~exist('L','var')
    L = load(getfn(ethDataRoot, 'Prompt', 'Select LEFT data file'));
end
if ~exist('R', 'var')
    R = load(getfn(ethDataRoot, 'Prompt', 'Select RIGHT data file'));
end

if ismember('blocks', fieldnames(L)) && ismember('blocks', fieldnames(R)) && all(size(L.blocks)==size(R.blocks))
else
    error('Expect equal-sized blocks field in each of L,R');
end

fprintf('Found %d blocks in each of L,R\n', length(L.blocks));

BS = struct('trials', {}, 'tag', {}, 'goaldirected', {}, 'text', {});

for i=1:length(L.blocks)

    % append LEFT
    BS(end+1).goaldirected = 'existing';
    BS(end).trials = L.blocks{i};
    BS(end).tag = sprintf('L_blk%d', i);
    BS(end).text = 'In this block, pay special attention to the LEFT image.';

    % append RIGHT
    BS(end+1).goaldirected = 'existing';
    BS(end).trials = R.blocks{i};
    BS(end).tag = sprintf('R_blk%d', i);
    BS(end).text = 'In this block, pay special attention to the RIGHT image.';

end
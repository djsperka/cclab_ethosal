function [outfile] = makeBlockset(varargin)

    local_ethosal;   % get directory vars

    if nargin==0
        %% must have L and R - loaded from etholog input file
        lfn = getfn(ethDataRoot, 'Prompt', 'Select LEFT data file');
        [lpath,lbase,~] = fileparts(lfn);
        L = load(lfn);
        rfn = getfn(ethDataRoot, 'Prompt', 'Select RIGHT data file');
        [rpath,rbase,~] = fileparts(rfn);
        R = load(rfn);
        
        % Get output base
        c_outbase = inputdlg('Enter blockset filename (base only)', 'Blockset Filename', [1, 45], {lbase}); 
        outbase = c_outbase{1};

    elseif nargin==3
        fprintf('left %s right %s base %s\n', varargin{1}, varargin{2}, varargin{3});
        L = load(varargin{1});
        R = load(varargin{2});
        [lpath,lbase,~] = fileparts(varargin{1});
        [rpath,rbase,~] = fileparts(varargin{2});
        outbase = varargin{3};
    else
        error('Expecting 0 args (choose L and R files by dialog) or 2 args (left_file, right_file)');
    end

    if ismember('blocks', fieldnames(L)) && ismember('blocks', fieldnames(R)) && all(size(L.blocks)==size(R.blocks))
        fprintf('Found %d blocks in each of L,R\n', length(L.blocks));
    else
        error('Expect equal-sized blocks field in each of L,R');
    end
    
    
    BS = struct('trials', {}, 'outputbase', {}, 'goaldirected', {}, 'text', {}, 'label', {});
    
    for i=1:length(L.blocks)
    
        % append LEFT
        BS(end+1).goaldirected = 'existing';
        BS(end).trials = L.blocks{i};
        BS(end).outputbase = sprintf('%s_L_blk%d', lbase, i);
        BS(end).text = 'In this block, pay special attention to the LEFT image.\nHit any button to continue.';
        BS(end).label = sprintf('L block %d', i);
    
        % append RIGHT
        BS(end+1).goaldirected = 'existing';
        BS(end).trials = R.blocks{i};
        BS(end).outputbase = sprintf('%s_R_blk%d', rbase, i);
        BS(end).text = 'In this block, pay special attention to the RIGHT image.\nHit any button to continue.';
        BS(end).label = sprintf('R block %d', i);
    
    end
    
    % Make struct for the input file. Start with L, then modify it to our
    % needs.
    
    S = L;
    S = rmfield(S,'blocks');
    S.blockset = BS;
    
    
    % and output file
    outfile = fullfile(lpath, ['rimg_exp_', outbase, '.mat']);
    save(outfile, '-struct', 'S');
end
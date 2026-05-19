function [outfile] = makeBlockset(varargin)

    % if two args, they must be left, right filenames
    whichType='';
    if nargin >= 2
        lfn = varargin{1};
        [lpath,lbase,~] = fileparts(lfn);
        rfn = varargin{2};
        [~,rbase,~] = fileparts(rfn);
        if nargin > 2
            whichType = varargin{3};
        end
    elseif nargin == 0
        %% must have L and R - loaded from etholog input file
        lfn = getfn(ethDataRoot, 'Prompt', 'Select LEFT data file');
        [lpath,lbase,~] = fileparts(lfn);
        rfn = getfn(ethDataRoot, 'Prompt', 'Select RIGHT data file');
        [~,rbase,~] = fileparts(rfn);
        whichType = input("Enter L for left-right files, C for color-cued: ", "s");
    else
        error('Expecting 0 or 2 or 3 args (filenames of left,right file, and maybe L or C)');
    end

    assert(ismember(whichType,'CL'), 'which type must be L or C');
    if whichType == 'L'
        sLongImageDesc = {'LEFT', 'RIGHT'};
        sShortImageDesc = {'L', 'R'};
        sGoalDirArg = 'lr';
    else
        sLongImageDesc = {'RED', 'GREEN'};
        sShortImageDesc = {'RED', 'GRN'};
        sGoalDirArg = 'color';
    end

    L = load(lfn);
    R = load(rfn);

    if ismember('blocks', fieldnames(L)) && ismember('blocks', fieldnames(R)) && all(size(L.blocks)==size(R.blocks))
    else
        error('Expect equal-sized blocks field in each of the two input files');
    end
    
    fprintf('Found %d blocks in each input file\n', length(L.blocks));
    
    nblocks =length(L.blocks) * 2;
    BS = struct('trials', cell(nblocks, 1), 'outputbase', cell(nblocks, 1), 'goaldirected', cell(nblocks, 1), 'text', cell(nblocks, 1), 'label', cell(nblocks, 1));
    
    for i=1:length(L.blocks)
    
        % append LEFT
        j = (i-1)*2 + 1;
        BS(j).goaldirected = sGoalDirArg;
        BS(j).trials = L.blocks{i};
        BS(j).outputbase = sprintf('%s_%s_blk%d', lbase, sShortImageDesc{1}, i);
        BS(j).text = sprintf('In this block, pay special attention to the %s image.\nHit any button to continue.', sLongImageDesc{1});
        BS(j).label = sprintf('%s block %d', sShortImageDesc{1}, i);
    
        % append RIGHT
        j = j+1;
        BS(j).goaldirected = sGoalDirArg;
        BS(j).trials = R.blocks{i};
        BS(j).outputbase = sprintf('%s_%s_blk%d', sShortImageDesc{2}, rbase, i);
        BS(j).text = sprintf('In this block, pay special attention to the %s image.\nHit any button to continue.', sLongImageDesc{2});
        BS(j).label = sprintf('%s block %d', sShortImageDesc{2}, i);
    
    end
    
    % Make struct for the input file. Start with L, then modify it to our
    % needs.
    
    S = L;
    S = rmfield(S,'blocks');
    S.blockset = BS;
    
    % Get output base
    outbase = inputdlg('Enter blockset filename (base only)', 'Blockset Filename', [1, 45], {lbase}); 
    
    % and output file
    outfile = fullfile(lpath, [outbase{1}, '.mat']);
    save(outfile, '-struct', 'S');
end

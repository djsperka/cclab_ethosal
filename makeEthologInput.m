function [filename] = makeEthologInput(varargin)
%makeEthologInput Make an input file for etholog.  
%   makeEthologInput(folder, ttype, etype, extra, img, blocksOrTrials, genFuncInputArgs,
%   genFuncParserResults, genFuncName)
%   
%   The folder arg is an output folder. It should be the root of data
%   files. A subfolder named 'input' is used for the *.mat files created by
%   this script. The args are:
%   ttype - test type, one of 'gab','mimg','rimg' (use rimg for flip)
%   etype - exp type, one of 'thr' or 'exp'
%   extra - becomes part of filename, ttype_etype_extra.mat
%   img - imageset used
%   blocksOrTrials - trials table or cell array of tables (i.e. blocks)
%   inputArgs - args passed to the generator function
%   parsedResults - results from the inputParser in the gen function
%   scriptName - name of the script that generated the trials
%   
%   Example: flip dataset, generated with this:
%
%   >> [blocks,inputArgs,parsedResults,scriptName]=generateEthBlocksImgV2(img.BalancedFileKeys, [20,30,0], Base=4, NumBlocks=2);
%   
%   is packaged with this:
%   
%   >> makeEthologInput(ethDataRoot,'rimg','exp','50img_20_30left',img,blocks,inputArgs,parsedResults,scriptName)
%

    % make defaults for everything
    okTtypes={'gab','mimg','rimg'};
    okEtypes={'thr','exp'};
    myEtype='';
    myTtype='';
    myExtra='';
    myImg=[];

    fprintf('nargin is %d\n', nargin);

    filename='TODO.MAT';

    if nargin < 6
        error('at least 4 args, please');
    end

    if isfolder(varargin{1})        
        myDataRoot = varargin{1};
    else
        error('Arg1 should be data root (file will go in input/ subfolder');
    end

    myTtype = validatestring(varargin{2}, okTtypes);
    myEtype = validatestring(varargin{3}, okEtypes);
    myExtra = varargin{4};
    
    if isa(varargin{5}, 'imageset')
        myImg = varargin{5};
    else
        error('Arg 5 must be an imageset');
    end

    if isa(varargin{6}, 'table')
        myHaveTrials = true;
        trials = varargin{6};
        blocks=[];
    elseif iscell(varargin{6}) && all(cellfun(@(x) isa(x,'table'), varargin{6}))
        myHaveTrials = false;
        blocks = varargin{6};
        trials=[];
    else
        error('Arg 6 should be trials or blocks');
    end

    % Start constructing the struct.
    % remaining args, if any, will added to this struct.

    S.imagesetName = myImg.Name;
    S.imagesetParamsFunc = myImg.ParamsFunc;
    
    if myHaveTrials
        S.trials = trials;
    else
        S.blocks = blocks;
    end

    if nargin > 6
        S.genFuncArgs = varargin{7};
    end
    if nargin > 7
        S.genFuncParserResults = varargin{8};
    end
    if nargin > 8
        S.genFuncName = varargin{9};
    end

    % Now make output filename
    filename = [myDataRoot, 'input/', myTtype, '_', myEtype, '_', myExtra, '.mat'];

    % and save
    save(filename, '-struct', 'S');

end
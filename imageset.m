classdef imageset
    %imageset Set of images, can be made into textures (in the PTB/OpenGL 
    %   sense of the word). Pre- processing can be done with a
    %   user-provided function, and processing can be done prior to
    %   generating textures as well. 
    %   Detailed explanation goes here
    
    properties
        Extensions
        Root
        Subfolders
        OnLoadFunc
        TextureParser
        Images
        IsBalanced
        BalancedFileKeys
        MissingKeys
        Bkgd
        IsUniform
        UniformOrFirstRect
    end
    
    methods (Static)
        function key = make_key(folder_key, file_key)
            if isempty(folder_key)
                key = file_key;
            elseif strcmp(folder_key,'*')
                key = 'BKGD';
            else
                key = strcat(folder_key, '/', file_key);
            end
        end

        function [keys] = make_keys(folder_keys, file_keys)
            if ~iscell(folder_keys) || ~iscell(file_keys)
                me = MException('imageset.make_keys.bad_input', 'Both args must be cell arrays.');
                throw(me);
            end
            keys = strcat(folder_keys, '/', file_keys);

            % corrections for blank folder keys
            blanks = matches(folder_keys, '');
            if any(blanks)
                keys(blanks) = file_keys(blanks);
            end

            % corrections for bkgd
            bkgds = matches(folder_keys, '*');
            if any(bkgds)
                keys(bkgds) = {'BKGD'};
            end
        end

        function [folder_key, file_key] = split_key(key)
            folder_key='';
            file_key='';
            if contains(key, '/')
                k = split(key, '/');
                folder_key = k{1};
                file_key = k{2};
            else
                file_key = key;
            end
        end

        function J = contrast(I, c)
            J = im2uint8((im2double(I)-0.5)*c + 0.5);
        end
            
    end
    
    methods (Access = private)
    
        function key = parse_key(obj, k)
            if ~ischar(k) && ~isstring(k)
                exception = MException('imageset:parse_key:wrongType', 'Wrong type, expecting char or string');
                throw(exception);
            elseif ~obj.Images.isKey(k)
                exception = MException('imageset:parse_key:NotAKey', ['Not a key: ' k]);
                throw(exception);
            else
                key = k;
            end
        end

        function [isUniformSize, rectUniformOrFirst] = check_sizes(obj)
            isUniformSize = true;
            rectUniformOrFirst = [];
            haveFirstSize = false;
            allKeys = obj.Images.keys;
            for i=1:length(allKeys)
                r = obj.rect(allKeys{i});
                if ~isequal(r, rectUniformOrFirst)
                    if haveFirstSize
                        isUniformSize = false;  % sorry, dude
                    else
                        rectUniformOrFirst = r;
                        haveFirstSize = true;
                    end
                end
            end
        end


        function [isBalanced, balancedFileKeys, missingKeys] = check_key_balance(obj)
            %check_key_balance Tests whether each file key has an image for
            %each folder key. Returns unique filel keys found. If any 
            %unbalanced keys are found, they are returned in nonUniqueKeys.
            
            isBalanced = false;
            balancedFileKeys = {};
            missingKeys = {};
            allKeys = obj.Images.keys;
            allFileKeys = {};
            for i=1:length(allKeys)
                [~,fil] = imageset.split_key(allKeys{i});
                allFileKeys{end+1} = fil;
            end
            uniqueFileKeys = unique(allFileKeys);
            
            % now check each folder for each key. Each row in
            % obj.Subfolders refers to a subfolder (and a folder key)
            for ikey=1:length(uniqueFileKeys)
                kfail = false;
                for itype = 1:size(obj.Subfolders, 1)
                    k=imageset.make_key(obj.Subfolders{itype, 1}, uniqueFileKeys{ikey});
                    if ~obj.Images.isKey(k)
                        missingKeys = vertcat(missingKeys, k);
                        kfail = true; 
                    end
                end
                
                % if kfail is false, then each subfolder had an image 
                % with that basename. 
                if ~kfail 
                    balancedFileKeys = vertcat(balancedFileKeys, uniqueFileKeys{ikey});
                end
            end
            isBalanced = isempty(missingKeys);
        end
    end
        
    methods
        function obj = imageset(varargin)
            %imageset Load images from a set of folders. Each folder has a
            %key prefix. Full key for each file is prefix + '/' + basename.
            %   Detailed explanation goes here
            
            p = inputParser;
            %addRequired(p, 'Root', @(x) ischar(x) && isdir(x));
            addRequired(p, 'Root');
            addOptional(p,'ParamsFunc','', @(x) isfile(fullfile(p.Results.Root,[x{:},'.m'])));
            addParameter(p, 'Subfolders', {'H', {'natT', 'naturalT'}; 'L', 'texture'}, @(x) iscellstr(x) && size(x, 2)==2);
            addParameter(p, 'Extensions', {'.bmp', '.jpg', '.png'});
            addParameter(p, 'OnLoad', @deal, @(x) isa(x, 'function_handle'));  % check if isempty()
            addParameter(p, 'Bkgd', [.5; .5; .5], @(x) isnumeric(x) && iscolumn(x) && length(x)==3);
            
            p.parse(varargin{:});

            obj.Root = p.Results.Root;

            % If a params func is used, load it and assign values
            if ~isempty(p.Results.ParamsFunc)
                currentDir=pwd;
                cd(p.Results.Root);
                Y=eval(p.Results.ParamsFunc{:});
                cd(currentDir);
            else
                Y=struct;
            end

            if isfield(Y,'Subfolders')
                obj.Subfolders = Y.Subfolders;
            else
                obj.Subfolders = p.Results.Subfolders;
            end
            if isfield(Y,'Extensions')
                obj.Extensions = Y.Extensions;
            else
                obj.Extensions = p.Results.Extensions;
            end
            if isfield(Y,'OnLoadFunc')
                obj.OnLoadFunc = Y.OnLoadFunc;
            else
                obj.OnLoadFunc = p.Results.OnLoad;
            end
            if isfield(Y,'Bkgd')
                obj.Bkgd = Y.Bkgd;
            else
                obj.Bkgd = p.Results.Bkgd;
            end

            % Holds images after loading.
            obj.Images = containers.Map;
            
            % create parser for texture() function
            obj.TextureParser = inputParser;
            addRequired(obj.TextureParser, 'Window', @(x) isscalar(x));
            addRequired(obj.TextureParser, 'Key', @(x) (ischar(x) && obj.Images.isKey(x)) || (isstring(x) && all(obj.Images.isKey(x))));
            addOptional(obj.TextureParser, 'PreProcessFunc', [], @(x) isempty(x) || isa(x, 'function_handle') || (iscell(x) && all(cellfun(@(x)isa(x,'function_handle'), x))));

            % now process files. Each row of the cell array is two elements
            % - the key and the subfolder. The subfolder arg itself can be
            % a cell array; the subfolder names are tested in order. Two
            % cannot exist - this is for 'natT' and 'naturalT'.
            for i=1:size(obj.Subfolders, 1)
                useSubFolderName = obj.Subfolders{i,2};
                if iscell(obj.Subfolders{i,2})
                    z=cellfun(@(x) isfolder(fullfile(obj.Root, x)), obj.Subfolders{i,2});
                    if length(find(z))==1
                        useSubFolderName = obj.Subfolders{i,2}{z};
                    else
                        exception = MException('imageset:imageset:BadInput', sprintf('No suitable subfolders found for key %s\n', obj.Subfolders{i,1}));
                        throw(exception);
                    end
                end
                c = add_images_from_folder(obj, fullfile(obj.Root, useSubFolderName), obj.Subfolders{i,1});
                fprintf('Found %d images in ''%s'' folder %s\n', c, obj.Subfolders{i,1}, fullfile(obj.Root, useSubFolderName));
            end
            
            % check key balance
            [obj.IsBalanced, obj.BalancedFileKeys, obj.MissingKeys] = check_key_balance(obj);

            % check for uniform size, make background image, add with key
            % BKGD
            [obj.IsUniform, obj.UniformOrFirstRect] = check_sizes(obj);
            image = ones(obj.UniformOrFirstRect(4), obj.UniformOrFirstRect(3), 3).*reshape(obj.Bkgd, 1, 1, 3);
            obj.Images('BKGD') = struct('fname', 'NO_FILENAME', 'image', image);
        end
        
        function add_image(obj, filename, key)
            if obj.Images.isKey(key)
                exception = MException('imageset:add_image:duplicateKey', sprintf('Adding a duplicate key %s with filename %s\n', key, filename));
                throw(exception);
            end
            try
                if isempty(obj.OnLoadFunc)
                    image = imread(filename);
                else
                    image = obj.OnLoadFunc(imread(filename));
                end
                obj.Images(key) = struct('fname', filename, 'image', image);
            catch ME
                fprintf('Error reading file %s\n', filename);
                rethrow(ME);
            end
        end
        
        function count = add_images_from_folder(obj, folder, folder_key)
            % look at all files in the folder
            if ~isfolder(folder)
                exception = MException('imageset:add_images_from_folder:NotAFolder', sprintf('This is not a folder: %s\n', folder));
                throw(exception);
            end
            d=dir(folder);
            count = 0;
            for i=1:height(d)
                fname = fullfile(d(i).folder, d(i).name);
                if isfile(fname)
                    [~,base,ext] = fileparts(fname);

                    % Check file extension
                    if any(strcmpi(ext, obj.Extensions))
                    
                        key = imageset.make_key(folder_key, base);                        
                        obj.add_image(fname, key);
                        count = count + 1;

                    else
                        fprintf('imageset - skipping file %s\n', fname);
                    end
                end
            end
        end
        
        function textureID = texture(obj, varargin)
            %texture call MakeTexture for this image, with opt. contrast
            %[0,1]
            %   Detailed explanation goes here
            
            
            % parse
            obj.TextureParser.parse(varargin{:});
            w = obj.TextureParser.Results.Window;
            key = obj.TextureParser.Results.Key;
            if ~iscell(key)
                if isempty(obj.TextureParser.Results.PreProcessFunc)
                    textureID = Screen('MakeTexture', w, obj.Images(key).image);
                else
                    textureID = Screen('MakeTexture', w, obj.TextureParser.Results.PreProcessFunc(obj.Images(key).image));
                end
            else
                % if preprocessfunc is empty, use @deal
                % if its a single function, apply it to all images. 
                % if its a cell array of same size() as the keys, then use
                % cellfun 
                ppfunc = obj.TextureParser.Results.PreProcessFunc;
                if isempty(ppfunc)
                    ppfunc = @deal;
                end
                if isa(ppfunc, 'function_handle')
                    textureID = cellfun(@(k) Screen('MakeTexture', w, ppfunc(obj.Images(k).image)), key);
                else
                    textureID = cellfun(@(k,f) Screen('MakeTexture', w, f(obj.Images(k).image)), key, ppfunc);
                end              
            end
        end
        
        function r = rect(obj, k)
            key = obj.parse_key(k);
            r = [0 0 size(obj.Images(key).image, 1:2)];
        end
        
        function flip(obj, varargin)
            obj.TextureParser.parse(varargin{:});
            w = obj.TextureParser.Results.Window;
            Screen('FillRect', w, [.5 .5 .5]);
            Screen('DrawTexture', w, obj.texture(varargin{:}));
            Screen('Flip', w);
        end

        function mflip(obj, w, keys, funcs)
            screenRect=Screen('Rect', w);

            % warn if not uniform
            if ~obj.IsUniform
                warning('Images in this imageset are not uniform size');
            end

            % divvy up into however many pieces are needed. Note - the
            % returned rects are in rows!
            divviedRects = ArrangeRects(length(keys), obj.UniformOrFirstRect, screenRect);

            % Find the center of each rect, then center rect on that point
            % for the image itself. Use columnar-rects for RectCenter
            [ctrX, ctrY] = RectCenter(divviedRects');
            textureRects = CenterRectOnPoint(obj.UniformOrFirstRect, ctrX', ctrY');
            textures = cellfun(@(k,f) obj.texture(w,k,f), keys, funcs);
            Screen('FillRect', w, obj.Bkgd);
            Screen('DrawTextures', w, textures, [], textureRects');
            Screen('Flip', w);
         end


        function fname = filename(obj, k)
            % keys expected folder,file
            key = obj.parse_key(k);
            fname = obj.Images(key).fname;
        end

        function image = get_image(obj, k)
            key=obj.parse_key(k);
            image = obj.Images(key).image;
        end
    end
end


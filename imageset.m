classdef imageset
    %imageset Set of images, can be made into textures (in the PTB/OpenGL 
    %   sense of the word) at a contrast.
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
    end
    
    methods (Static)
        function key = make_key(folder_key, file_key)
            if isempty(folder_key)
                key = file_key;
            else
                key = [folder_key '/' file_key];
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
            
    end
    
    methods (Access = private)
    
        function key = parse_key(obj, k)
            if ~ischar(k)
                exception = MException('imageset:parse_key:wrongType', 'Wrong type, expecting char');
                throw(exception);
            elseif ~obj.Images.isKey(k)
                exception = MException('imageset:parse_key:NotAKey', ['Not a key: ' k]);
                throw(exception);
            else
                key = k;
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
                        missingKeys{end+1} = k;
                        kfail = true; 
                    end
                end
                
                % if kfail is false, then each subfolder had an image 
                % with that basename. 
                if ~kfail 
                    balancedFileKeys{end+1} = uniqueFileKeys{ikey};
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
            addParameter(p, 'Subfolders', {'H', {'natT', 'naturalT'}; 'L', 'texture'}, @(x) iscellstr(x) && size(x, 2)==2);
            addParameter(p, 'Extensions', {'.bmp', '.jpg', '.png'});
            addParameter(p, 'OnLoad', @onLoadImage, @(x) isa(x, 'function_handle'));  % check if isempty()
            
            p.parse(varargin{:});

            obj.Root = p.Results.Root;
            obj.Subfolders = p.Results.Subfolders;
            obj.Extensions = p.Results.Extensions;
            obj.OnLoadFunc = p.Results.OnLoad;
            obj.Images = containers.Map;
            
            % create parser for texture() function
            obj.TextureParser = inputParser;
            addRequired(obj.TextureParser, 'Window', @(x) isscalar(x));
            addRequired(obj.TextureParser, 'Key', @(x) ischar(x) && obj.Images.isKey(x));
            addOptional(obj.TextureParser, 'PreProcessFunc', [], @(x) isa(x, 'function_handle'));

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
                add_images_from_folder(obj, fullfile(obj.Root, useSubFolderName), obj.Subfolders{i,1});
            end
            
            % check key balance
            [obj.IsBalanced, obj.BalancedFileKeys, obj.MissingKeys] = check_key_balance(obj);
            
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
        
        function add_images_from_folder(obj, folder, folder_key)
            % look at all files in the folder
            if ~isfolder(folder)
                exception = MException('imageset:add_images_from_folder:NotAFolder', sprintf('This is not a folder: %s\n', folder));
                throw(exception);
            end
            d=dir(folder);
            for i=1:height(d)
                fname = fullfile(d(i).folder, d(i).name);
                if isfile(fname)
                    [~,base,ext] = fileparts(fname);

                    % Check file extension
                    if any(strcmpi(ext, obj.Extensions))
                    
                        key = imageset.make_key(folder_key, base);                        
                        obj.add_image(fname, key);

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
            if isempty(obj.TextureParser.Results.PreProcessFunc)
                textureID = Screen('MakeTexture', w, obj.Images(key).image);
            else
                textureID = Screen('MakeTexture', w, obj.TextureParser.Results.PreProcessFunc(obj.Images(key).image));
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


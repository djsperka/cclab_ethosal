classdef imageset
    %imageset Set of images, can be made into textures (in the PTB/OpenGL 
    %   sense of the word) at a contrast.
    %   Detailed explanation goes here
    
    properties
        Images  % Will be a container.Map of image arrays
        ImageFilenames % container.Map of filename
    end
    
    methods (Static)
        function key = make_key(folder_key, file_key)
            if isempty(folder_key)
                key = file_key;
            else
                key = [folder_key '/' file_key];
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
    
        function [w, key, contrast] = parse_wkc(obj, varargin)
            persistent p;
            if isempty(p)
                p = inputParser;
                addRequired(p, 'Window', @(x) isscalar(x));
                addRequired(p, 'Key', @(x) ischar(x) && obj.Images.isKey(x));
                addOptional(p, 'Contrast', 1.0, @(x) isnumeric(x) && x >= 0 && x <= 1.0);
            end
            p.parse(varargin{:});
            w = p.Results.Window;
            key = p.Results.Key;
            contrast = p.Results.Contrast;
        end

    end
        
    methods
        function obj = imageset(varargin)
            %imageset Load images from a set of folders. Each folder has a
            %key prefix. Full key for each file is prefix + '/' + basename.
            %   Detailed explanation goes here
            p = inputParser;
            addRequired(p, 'Root', @(x) ischar(x) && isdir(x));
            addParameter(p, 'Subfolders', {'H', 'natT'; 'L', 'texture'}, @(x) iscellstr(x) && size(x, 2)==2);
            p.parse(varargin{:});
            
            % create container for images and filenames
            obj.Images = containers.Map;
            obj.ImageFilenames = containers.Map;
            

            % now process files. Each row of the cell array is two elements
            % - the key and the subfolder.
            root = p.Results.Root;
            subs = p.Results.Subfolders;
            for i=1:size(subs, 1)
                add_images_from_folder(obj, fullfile(root, subs{i,2}), subs{i,1});
            end
        end
        
        function add_image(obj, filename, key)
            if obj.Images.isKey(key)
                exception = MException('imageset:add_image:duplicateKey', sprintf('Adding a duplicate key %s with filename %s\n', key, filename));
                throw(exception);
            end
            obj.Images(key) = imread(filename);
            obj.ImageFilenames(key) = filename;
        end
        
        function add_images_from_folder(obj, folder, folder_key)
            % look at all files in the folder
            if ~isdir(folder)
                exception = MException('imageset:add_images_from_folder:NotAFolder', sprintf('This is not a folder: %s\n', folder));
                throw(exception);
            end
            d=dir(folder);
            for i=1:height(d)
                fname = fullfile(d(i).folder, d(i).name);
                if isfile(fname)
                    [~,base,~] = fileparts(fname);
                    
                    % the full key is folder_key/base, but if folder_key is
                    % empty, then the full key is just base
                    
                    if isempty(folder_key)
                        key = base;
                    else
                        key = [folder_key '/' base];
                    end
                    obj.add_image(fname, key);
                end
            end
        end
        
        function textureID = texture(obj, varargin)
            %texture call MakeTexture for this image, with opt. contrast
            %[0,1]
            %   Detailed explanation goes here
            
            % The use of a parser is maybe overkill, but I want the last
            % arg to be optional and I want to hide the tedious code that
            
            % parse
            [w, key, contrast] = obj.parse_wkc(varargin{:});
            if contrast == 1.0
                textureID = Screen('MakeTexture', w, obj.Images(key));
            else
                tmpImage = uint8((contrast * (double(obj.Images(key))-127)) + 127);
                textureID = Screen('MakeTexture', w, tmpImage);
            end
        end
        
        function r = rect(obj, k)
            key = obj.parse_key(k);
            r = [0 0 size(obj.Images(key), 1:2)];
        end
        
        function flip(obj, varargin)
            [w, key, contrast] = obj.parse_wkc(varargin{:});
            Screen('FillRect', w, [.5 .5 .5]);
            Screen('DrawTexture', w, obj.texture(w, key, contrast));
            Screen('Flip', w);
        end
        
        function fname = filename(obj, k)
            % keys expected folder,file
            key = obj.parse_key(k);
            fname = obj.ImageFilenames(key);
        end
    end
end

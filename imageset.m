classdef imageset
    %imageset Set of images, can be made into textures at a contrast.
    %   Detailed explanation goes here
    
    properties
        Images  % Will be a cell array of images
        TextureParser
    end
    
    methods
        function obj = imageset(varargin)
            %imageset Construct an instance of this class
            %   Detailed explanation goes here
            obj.Images = {};
            if nargin==1
                for i=1:length(varargin{1})
                    obj.Images{i} = imread(varargin{1}{i});
                end
            end
            
            % this is the parser used in texture() below
            obj.TextureParser = inputParser;
            addRequired(obj.TextureParser, 'Window');
            addRequired(obj.TextureParser, 'Index', @(x) isscalar(x) && x>0 && x<length(obj.Images));
            addOptional(obj.TextureParser, 'Contrast', 1.0, @(x) isnumeric(x) && x >= 0 && x <= 1.0);
            
        end
        
        function textureID = texture(obj, varargin)
            %texture call MakeTexture for this image, with opt. contrast
            %[0,1]
            %   Detailed explanation goes here
            
            % The use of a parser is maybe overkill, but I want the last
            % arg to be optional and I want to hide the tedious code that
            % deals with it.
            obj.TextureParser.parse(varargin{:});
            index = obj.TextureParser.Results.Index;
            w = obj.TextureParser.Results.Window;
            contrast = obj.TextureParser.Results.Contrast;

            if contrast == 1.0
                textureID = Screen('MakeTexture', w, obj.Images{index});
            else
                tmpImage = uint8((contrast * (double(obj.Images{index})-127)) + 127);
                textureID = Screen('MakeTexture', w, tmpImage);
            end
        end
        
        function r = rect(obj, index)
            r = [0 0 size(obj.Images{index}, 1:2)];
        end
    end
end


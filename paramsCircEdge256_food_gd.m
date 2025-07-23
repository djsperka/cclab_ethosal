function Y = paramsCircEdge256_food_gd()
% paramsCircEdge256_food_gd Imageset params for goal directed food study. 
    Y.Subfolders={ ...
    'H','refood';'L','refood-tex'
    };
    Y.MaskParameters = [256,128,100,100];
    %Y.OnLoadFunc=@(x) imresize(x,[256,256]);
end

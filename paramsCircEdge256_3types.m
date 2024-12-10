function Y = paramsCircEdge256_3types()
    Y.Subfolders={ ...
    'H','nat';'L','tex';
    'F','food';'f','food-tex';
    'N','nature';'n','nature-tex'
    };
    Y.MaskParameters = [256,128,100,100];
    %Y.OnLoadFunc=@(x) imresize(x,[256,256]);
end

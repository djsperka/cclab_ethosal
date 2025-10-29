function Y = paramsCircEdge256_natureHL()
    Y.Subfolders={ ...
    'H','nature';'L','nature-tex'
    };
    Y.MaskParameters = [256,128,100,100];
    %Y.OnLoadFunc=@(x) imresize(x,[256,256]);
end

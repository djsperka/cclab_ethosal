function Y = paramsCircEdge256_color()
    Y.Subfolders={ ...
    'H','bw';'L','bw-tex';'C','color';'D','color-tex'
    };
    Y.MaskParameters = [256,128,100,100];
    %Y.OnLoadFunc=@(x) imresize(x,[256,256]);
end

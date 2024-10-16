function Y = testparams1()
    Y.Subfolders={ ...
    'H','nat';'L','tex'
    };
    Y.MaskParameters = [256,128,100,100];
    %Y.OnLoadFunc=@(x) imresize(x,[256,256]);
end

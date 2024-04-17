function [J] = squuezeclampimage(I, region)
%squeezeclapimage Force image into region of pixel levels (0-255) by
% clamping, nothing fancy.
%   The input region should be a two-element vector. All pixel levels below
%   region(1) are set to region(1). All pixel levels above region(2) are
%   set to region(2). Goes without saying that each value should be integer
%   in [0:255]
    %img2 = histeq(inputImage);
    J = I;
    if region(1)>0
        J(I<region(1)) = region(1);
    end
    if region(2)<255
        J(I>region(2)) = region(2);
    end
end


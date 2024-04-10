function [img] = onLoadImage(inputImage)
%onLoadImage Convert to grayscale, clamp to range [clampRegionSize, 
% 255-clampRegionSize]
%   Detailed explanation goes here
    clampRegionSize = 30;
    %img2 = histeq(inputImage);
    img = inputImage;
    img2 = img;
    img(img2<clampRegionSize) = clampRegionSize;
    img(img2>(256-clampRegionSize)) = 256-clampRegionSize;
end


function [M] = makeGaussianEdgeMask(radius, c, r1)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

    [X,Y] = meshgrid(1:2*radius, 1:2*radius);
    Rsquared = (X-radius).^2 + (Y-radius).^2;
    F=exp(-0.5*Rsquared/c^2);

    % radial-linear fade out. Not what we want when r<r1 
    G = (radius-sqrt(Rsquared))/(radius-r1);
    G(Rsquared < r1^2) = 1;
    G(Rsquared > radius^2) = 0;

    % result...
    M = F.*G;
end
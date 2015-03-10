function [ field ] = sphericalwave( N,A0,lambda,w,verbose )
% [ field ] = sphericalwave( N,A0,lambda,w,verbose )
%   
% N = number of points across coordinate systems
% A0 = amplitude of spherical wave
% lambda = wavelength
% w = width of Gaussian for fall off
% verbose = true or false, true plots the gaussian and field, false doesn't


k = (2*pi)/lambda;

%% Make A Gaussian 
xg = linspace(-10,10,N);
[Xg,Yg] = meshgrid(xg);
gaus = exp(-((Xg.^2 ./ (2*w)) + (Yg.^2 ./(2*w))));

if verbose == true
    figure;
    mesh(xg,xg,gaus);
    xlim([-10,10]);
    ylim([-10,10])
    zlim([0,1]);
end
%% Make a Spherical Wave
x = linspace(-10*lambda,10*lambda,N);
[X,Y] = meshgrid(x);
z = lambda/25;
R = sqrt(X.^2 + Y.^2 + z.^2);
U0 = (A0 .* exp(1i*k.*R))./(4*pi.*R);

%% Apply the Gaussian Fall off
field = U0 .* gaus;

if verbose == true
    figure
    % plotCAmpl(U0,2);
    subplot(1,2,1)
    imagesc(x,x,abs(field));
    sqar;
    subplot(1,2,2);
    imagesc(x,x,angle(field))
    sqar;
end
end


% 528 Project 1
% Downward looking telescope
% A.T. Rodack
% 20150301

clear all; clc; close all;


%% Preliminary Important Stuff
lambda = AOField.VBAND; % Red light.
k = (2*pi)/lambda;

% Pupil Choices
D = 0.5; %meters
secondary = 0.3 * D;
spider = 0.0254/2;

% PSF Stuff
THld = lambda/D * 206265; % Lambda/D in arcsecs.
FOV =   25*THld; % FOV for PSF computation
PLATE_SCALE = THld/5; % Pixel Size for PSF computations -- set by our first order parameter
CCD1 = 0;

% Choose to Step Through Propagation
plotsteps = true;

N1=2; N2=2;

%% Make Our Telescope Pupil
SPACING = 0.001;           % 1 mm spacing (could probably be more)
aa = SPACING;              % for antialiasing.
PUPIL_DEFN = [
   0 0 D         1 aa 0 0 0 0 0
   0 0 secondary 0 aa/2 0 0 0 0 0
   0 0 spider   -2 aa 4 0 D/1.9 0 0
   ];

A = AOSegment;
A.spacing(SPACING);
A.name = 'PAJ Pupil';
A.pupils = PUPIL_DEFN;
A.make;
clf;
colormap(gray);

A.show;
drawnow;
fprintf('\n');


%% Make a multi-layer atmosphere.
% Make an AOAtmo with 3 layers all of the same strength.
altitude = [10,5000,9990];
thickness = [altitude(1),altitude(2)-altitude(1),altitude(3)-altitude(2)];
% r0_mat = [0.15,0.3,0.5];
Cn2_HV = [thickness(1)*HVModel(0,thickness(1)/2),(thickness(2))*HVModel(50,altitude(2)-thickness(2)/2),(thickness(3))*HVModel(85,altitude(3)-thickness(3)/2)];
% Cn2_SLC = [SLCModel('day',altitude(1)),SLCModel('day',altitude(2)),SLCModel('day',altitude(3))];

ATMO = AOAtmo(A);
ATMO.name = 'Layered Atmosphere';

for n=1:3
    ps = AOScreen(2*1024);
    ps.name = sprintf('Layer %d',n);
    ps.spacing(0.02);
    ps.setCn2(Cn2_HV(n),thickness(n));
%     ps.setR0(r0_mat(n));
    ATMO.addLayer(ps,altitude(n));
    ATMO.layers{n}.Wind = randn([1 2])*15; % random wind layers.
end

% Define some beacons from which to calculate ATMO OPLs...
%% Guide star selection
CAMERA = [0 0 1] * 10000;
ATMO.BEACON = CAMERA; % Set this so ATMO knows how to compute the wavefront.

fprintf('\n Making ATMO....\n');
ATMO.make;

%% Make an AOField object.
F = AOField(A);
F.name = 'Field';
F.resize(1024); % make it big to study the field before the pupil.
F.FFTSize = 1024; % Used to compute PSFs, etc.
F.lambda = lambda;

F.planewave*A;
[x,y] = F.coords;

F.planewave*A;
[PSF_DL,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
PSFmax = max(PSF_DL(:));


input 'Press a key to Continue'

h = figure(1);
ATMO.useGeometry(true);
counter = 1;
for t=0:.01:0.05
    ATMO.setObsTime(t);
    F.planewave*ATMO*A;
    
    subplot(N1,N2,1);
    ATMO.show;
    title(sprintf('wavefront:time=%.3fs',t));
    colorbar off;
    
    subplot(N1,N2,2);
    F.show;
    colorbar off;
    title('Field');

    
    subplot(N1,N2,3);
    [PSF,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
    imagesc(thx,thy,log10(PSF/PSFmax),[-4 0]);
    daspect([1 1 1]);
    axis xy;
    colorbar off;
    title('PSF');
    
    subplot(N1,N2,4);
    CCD1 = CCD1 + PSF;
    imagesc(thx,thy,CCD1);
    title('Long Exposure');
    axis xy
    colormap(gray);
    
    
    drawnow;
%     M1(counter) =getframe(h);
    counter = counter + 1;
end

%% Propagate Between Screens
fprintf('**************************************************************\n\n');
input 'Press a key to Continue'
fprintf('Preparing Propatation Section......\n');

%% Make a Spherical Wave
fprintf('Making a Spherical Wave\n');
% x = linspace(-0.01,0.01,256);
% [X,Y] = meshgrid(x);
% Z = altitude(1);
% R = sqrt(X.^2 + Y.^2 + Z^2);
% spherical_wave = exp((1i*k*R))./R;
% 
% R_mask = sqrt(X.^2 + Y.^2);
% mask = double(R_mask <= 0.0035);
% spherical_wave = spherical_wave .* mask;

N = 256;
A0 = 1;
w = 0.0085;
verbose = true;
spherical_wave = sphericalwave(N,A0,lambda,w,verbose);


%% Make Screens
fprintf('\nBuilding Phase Screens\n');
figure(2);
ps1 = AOScreen(2*1024);
ps1.name = 'Ground Layer';
ps1.spacing(0.02);
ps1.setCn2(Cn2_HV(1));
% ps1.setR0(0.15);
ps1.make;
clf;
ps1.show;
drawnow;
% input 'Continue...'
pause(2);

ps2 = AOScreen(2*1024);
ps2.name = 'Mid Layer';
ps2.spacing(0.02);
ps2.setCn2(Cn2_HV(2));
% ps2.setR0(0.3);
ps2.make;
clf;
ps2.show;
drawnow;
% input 'Continue...'
pause(2);

ps3 = AOScreen(2*1024);
ps3.name = 'Camera Layer';
ps3.spacing(0.02);
ps3.setCn2(Cn2_HV(3));
% ps3.setR0(0.5);
ps3.make;
clf;
ps3.show;
drawnow;
% input 'Continue...'
pause(2);

plotCAmpl(spherical_wave,1.0);
CCD2 = 0;


fprintf('\nPropagating Spherical Wave through Phase Screens to Camera\n');
if plotsteps == true
    fprintf('Stepping Through Propagation...\n');
end

%% Go through the screens
if plotsteps == false
    fprintf('t = \n');
end
counter = 1;
h2 = figure(2);
spherical_wave = padarray(spherical_wave,[3.5*length(spherical_wave),3.5*length(spherical_wave)]);
for t=0:.01:0.15
    if plotsteps == false
        fprintf('%0.3f \t',t);
    elseif plotsteps == true
        fprintf('t = %0.3f',t);
    end
    
    if mod(counter,7) == 0
        fprintf('\n');
    end
    ps1.shiftPixels([1 1]);
    ps2.shiftPixels([1 1]*10);
    ps3.shiftPixels([1 1]*25);
    
    F.planewave;
    % Set the field to be a spherical wave
    F.grid(spherical_wave);
    if plotsteps == true;
        F.show
        title('Spherical Wave');
        input '\nPropagate to ps1...';
    end
    
    F.propagate(altitude(1));
    if plotsteps == true;
        F.show;
        title('Complex Field at ps1');
        input 'Go through ps1...';
    end
    
    F * ps1;
    if plotsteps == true;
        F.show;
        title('Complex Field through ps1');
        input 'Propagate to ps2...';
    end
    PSF1 = F.mkPSF(FOV,PLATE_SCALE);
    F.touch;
    
    F.propagate(altitude(2));
    if plotsteps == true;
        F.show;
        title('Complex Field at ps2');
        input 'Go through ps2...';
    end
    
    F * ps2;
    if plotsteps == true;
        F.show;
        title('Complex Field through ps2');
        input 'Propagate to ps3...';
    end
    PSF2 = F.mkPSF(FOV,PLATE_SCALE);
    F.touch;
    
    F.propagate(altitude(3));
    if plotsteps == true;
        F.show;
        title('Complex Field at ps3');
        input 'Go through ps3...';
    end
    
    F * ps3;
    if plotsteps == true;
        F.show;
        title('Complex Field through ps3');
        input 'Continue...';
    else
        final_field = F.grid;
    end
    PSF3 = F.mkPSF(FOV,PLATE_SCALE);
    F.touch;
    
    F.propagate(10);
    F * A;
    
    
    subplot(2,2,1);
    F.show;
    colorbar off;
    title('Field at Telescope Aperture');
    
    
    subplot(2,2,2);
    [PSF_final,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
    PSFmax_final = max(max(PSF_final));
    imagesc(thx,thy,log10(PSF_final/PSFmax_final),[-4,0]);
    daspect([1 1 1]);
    axis xy;
    colorbar off;
    title(sprintf('PSF:time=%.3fs',t));
    colormap(gray);
    
    subplot(2,2,3)
    CCD2 = CCD2 + PSF_final;
    imagesc(thx,thy,CCD2);
    title('Long Exposure');
    axis xy
    colormap(gray);
    
    if plotsteps == true;
        subplot(2,2,4);
    else
        subplot(2,2,4);
        plotCAmpl(final_field);
        sqar;
        title('Field after ps3');
        axis off
        axis xy;
    end
    drawnow;
    
    if counter == 1
        plotsteps = false;
    end
%     M2(counter) = getframe(h2);
    counter = counter + 1;
end

%% Check Performance
input 'Press Enter to Continue'


CCD1max = max(CCD1(:));
CCD2max = max(CCD2(:));

CCD1 = CCD1 / CCD1max;
CCD2 = CCD2 / CCD2max;

% Load in Image of Steward Observatory from Google Earth
img = imread('youngJLC.jpg');
img = double(img(:,:,1));

figure(4);
imagesc(img);
colormap(gray);
axis off;
title('Un-blurred Image of Steward Observatory');
drawnow;

% Diffraction Limited Case
fprintf('Computing blurred image with diffraction limited PSF\n');
img_DL = conv2(img,PSF_DL);

% Atmo Model Case
fprintf('Computing blurred image with CCD PSF from Atmo Case\n');
img_atmo_CCD = conv2(img,CCD1);
fprintf('Computing blurred image with single realization of Atmo Case PSF\n');
img_atmo_inst = conv2(img,PSF);

% Propagation Case
fprintf('Computing blurred image with CCD PSF from Propagation Case\n');
img_prop_CCD = conv2(img,CCD2);
fprintf('Computing blurred image with single realization of Propagation Case PSF\n');
img_prop_inst = conv2(img,PSF_final);

figure(4)
clf;
subplot(1,2,1)
imagesc(img);
colormap(gray);
sqar;
title('Un-blurred Image');
axis off

subplot(1,2,2)
imagesc(img_DL);
sqar;
title('Diffraction Limited Case');
axis off
drawnow;

figure(5)
subplot(1,2,1)
imagesc(img_atmo_CCD);
sqar;
title('Atmo CCD Case');
axis off
colormap(gray)

subplot(1,2,2)
imagesc(img_atmo_inst);
sqar;
title('Atmo Single PSF Case');
axis off
drawnow;

figure(6);
subplot(1,2,1)
imagesc(img_prop_CCD)
colormap(gray);
sqar;
title('Propagation CCD Case');
axis off;

subplot(1,2,2);
imagesc(img_prop_inst);
sqar;
title('Propagation Single PSF Case');
axis off;
drawnow;

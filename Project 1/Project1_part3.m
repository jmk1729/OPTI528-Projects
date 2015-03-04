% 528 Project 1
% Downward looking telescope
% A.T. Rodack
% 20150301

clear all; clc; close all;



lambda = AOField.RBAND; % Red light.
k = (2*pi)/lambda;
N = 512;

%% Make Our Telescope Pupil
D = 0.5; %meters
secondary = 0.3 * D;
% secondary = 0;

SPACING = 0.001;           % 1 mm spacing (could probably be less)
aa = SPACING;              % for antialiasing.
spider = 0.0254;
% spider = 0;

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
input 'Press ENTER to Continue...'


%% Make a multi-layer atmosphere.
% Make an AOAtmo with 3 layers all of the same strength.
altitude = [10,6800,9980];
Cn2_HV = [HVModel(0,altitude(1)),HVModel(50,altitude(2)),HVModel(85,altitude(3))];
Cn2_SLC = [SLCModel('day',altitude(1)),SLCModel('day',altitude(2)),SLCModel('day',altitude(3))];

ATMO = AOAtmo(A);
ATMO.name = 'Layered Atmosphere';

for n=1:3
    ps = AOScreen(2*1024);
    ps.name = sprintf('Layer %d',n);
    ps.spacing(0.02);
    ps.setCn2(Cn2_HV(n));
    ATMO.addLayer(ps,altitude(n));
    ATMO.layers{n}.Wind = randn([1 2])*15; % random wind layers.
end    

% Define some beacons from which to calculate ATMO OPLs...
%% Guide star selection
CAMERA = [0 0 1] * 10000;

ATMO.BEACON = CAMERA; % Set this so ATMO knows how to compute the wavefront.

ATMO.make;

N1=2; N2=2;




%% Make an AOField object.
F = AOField(A);
F.name = 'Field';
F.resize(1024); % make it big to study the field before the pupil.
F.FFTSize = 1024; % Used to compute PSFs, etc.
F.lambda = lambda;

F.planewave*A;

[x,y] = F.coords;

% This adds a reference wave to the field and computes the intensity.
% imagesc(x,y,F.interferometer(1),[0 3]);
% sqar;
% axis xy;
% drawnow;
% input 'Continue...'

THld = F.lambda/D * 206265; % Lambda/D in arcsecs.
FOV = 4*THld;
PLATE_SCALE = THld/5;

F.planewave*A;
[PSF,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
PSFmax = max(PSF(:));

fprintf('Use light from a finite-distance beacon.\n')

ATMO.useGeometry(true);

for t=0:.01:0.01
    ATMO.setObsTime(t);
    F.planewave*ATMO*A;
    
    subplot(N1,N2,1);
    ATMO.show;
    title(sprintf('wavefront:time=%.3fs',t));
    
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
    imagesc(x,y,F.interferometer(1),[0 4]); sqar;
    axis xy;
    title('interferometer');
    
    
    drawnow;
end

%% Propagate Between Screens

%% Make a Spherical Wave
x = linspace(-0.01,0.01,256);
[X,Y] = meshgrid(x);
Z = altitude(1);
R = sqrt(X.^2 + Y.^2 + Z^2);
spherical_wave = exp((1i*k*R))./R;

R_mask = sqrt(X.^2 + Y.^2);
mask = double(R_mask <= 0.0035);
spherical_wave = spherical_wave .* mask;

%% Make Screens
figure(2);
ps1 = AOScreen(2*1024);
ps1.name = 'Ground Layer';
ps1.spacing(0.02);
% ps1.setCn2(Cn2_HV(1));
ps1.setR0(0.15);
ps1.make;
clf;
ps1.show;
input 'Continue...'

ps2 = AOScreen(2*1024);
ps2.name = 'Mid Layer';
ps2.spacing(0.02);
% ps2.setCn2(Cn2_HV(2));
ps2.setR0(0.3);
ps2.make;
clf;
ps2.show;
input 'Continue...'

ps3 = AOScreen(2*1024);
ps3.name = 'Camera Layer';
ps3.spacing(0.02);
% ps3.setCn2(Cn2_HV(3));
ps3.setR0(0.5);
ps3.make;
clf;
ps3.show;
input 'Continue...'

clf;
plotCAmpl(spherical_wave,1.0);
CCD = 0;
plotsteps = false;
%% Go through the screens
for t=0:.01:0.5
    ps1.shiftPixels([1 1]);
    ps2.shiftPixels([1 1]*10);
    ps3.shiftPixels([1 1]*25);
    
    F.planewave;
    % Set the field to be a spherical wave
    F.grid(padarray(spherical_wave,[2.5*length(spherical_wave),2.5*length(spherical_wave)]));
    if plotsteps == true;
        F.show
        input 'Propagate to ps1...';
    end
    
    F.propagate(altitude(1));
    if plotsteps == true;
        F.show;
        input 'Go through ps1...';
    end
    
    F * ps1;
    if plotsteps == true;
        F.show;
        input 'Propagate to ps2...';
    end
    PSF1 = F.mkPSF(FOV,PLATE_SCALE);
    F.touch;
    
    F.propagate(altitude(2));
    if plotsteps == true;
        F.show;
        input 'Go through ps2...';
    end
    
    F * ps2;
    if plotsteps == true;
        F.show;
        input 'Propagate to ps3...';
    end
    PSF2 = F.mkPSF(FOV,PLATE_SCALE);
    F.touch;
    
    F.propagate(altitude(3));
    if plotsteps == true;
        F.show;
        input 'Go through ps3...';
    end
    
    F * ps3;
    if plotsteps == true;
        F.show;
        input 'Continue...';
    end
    PSF3 = F.mkPSF(FOV,PLATE_SCALE);
    F.touch;
    
    F.propagate(10);
    F * A;
    
    
    subplot(2,2,1);
    F.show;
    colorbar off;
    title('Field');
    
    
    subplot(2,2,2);
    [PSF_final,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
    PSFmax_final = max(max(PSF_final));
    imagesc(thx,thy,log10(PSF_final/PSFmax));
    daspect([1 1 1]);
    axis xy;
    colorbar off;
    title(sprintf('PSF:time=%.3fs',t));
    colormap(gray);
    
    subplot(2,2,3)
    CCD = CCD + PSF_final;
    imagesc(thx,thy,CCD);
    title('Long Exposure');
    colormap(gray);
    
    if plotsteps == true;
        subplot(2,2,4);
    end
    drawnow;
end



test1 = conv2(PSF1,PSF2);
test2 = conv2(test1,PSF3);
% figure(3);
% imagesc(thx,thy,test2);
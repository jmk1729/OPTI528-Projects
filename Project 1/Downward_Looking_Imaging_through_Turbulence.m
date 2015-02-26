% Downward Looking Imaging through Turbulence
% Authors: Alexander Rodack, R. Philip Scott, Justin Knight
% Project 1
%
%
% **********************************************************************
clear all; clc; close all;

%% Initial Parameters

% Wavelength
LAMBDA = AOField.VBAND;
% Initialize a CCD just in case
CCD = 0;
% Set the number of pixels across the Segment (the Aperture will pick up a
% couple more)
pixels_across_aper = 254;

%Set the r0 for the Phase Screens
r0_1 = 0.15;
r0_2 = 0.25;
r0_3 = 0.5;
r0_4 = 1;

%% Make a Pupil

% To start with, why not just a simple circular pupil
Seg = AOSegment;
Seg.name = 'Pupil Segment';
D = 2.4; % This is in meters....we probably want to go smaller than this
SPACING = D/pixels_across_aper; % Get good resolution on the aperture
SMOOTHING = SPACING/5;
PUPIL_DEF1 = [0 0 D 1 SMOOTHING 0 0 0 0 0];
Seg.spacing(SPACING);
Seg.pupils = PUPIL_DEF1;
Seg.make;
% Get the Coordinate System
[x1,y1] = Seg.coords;
[X1,Y1] = Seg.COORDS;

% Make an Aperture out of the Segment
A = AOAperture;
A.spacing(SPACING);
A.addSegment(Seg);
A.name = 'Circular Pupil';
A.show;
colormap(gray);
drawnow;


% Recalculate Diameter to Match AOSim2 Coordinate System (should be very
% close to D, so this probably isn't necessary, but whatever).
D = max(Seg.extent)

%% Make a Field
F = AOField(A);
% Set the wavelength
F.lambda = LAMBDA;
% Resize to larger than the pupil to avoid aliasing later
F.resize(1024);
% Set a finer FFT Resolution
F.FFTSize = 2048;
% Calculate Diffraction Angle in arcseconds
THld = F.lambda/D * 206265;
% Set the Field of View and Plate Scale
FOV = 30 * THld; %arbitrary, can be set to whatever
PLATE_SCALE = THld/3; %pixel size, also arbitrary for now

%% Make Some Phase Screens

% Make them HUGE for plausible large wind speeds aloft
PS1 = AOScreen(2^12);
PS1.name = 'Ground Level, z = 0';
PS1.setR0(r0_1); %This will set Cn2 as well
PS1.setOuterScale(30); %This sets L0
PS1.altitude = 0; %This sets the altitude
PS1.lambdaRef = LAMBDA; %This sets the reference wavelength
PS1.make;

PS2 = AOScreen(2^12);
PS2.name = 'Troposphere, z = 5 km';
PS2.setR0(r0_2);
PS2.setOuterScale(30);
PS2.altitude = 5000; %Middle of Troposphere
PS2.lambdaRef = LAMBDA;
PS2.make;

PS3 = AOScreen(2^12);
PS3.name = 'Tropopause, z = 10 km';
PS3.setR0(r0_3);
PS3.setOuterScale(30);
PS3.altitude = 10000; %Tropopause (Airplane Height)
PS3.lambdaRef = LAMBDA;
PS3.make;

PS4 = AOScreen(2^12);
PS4.name = 'Stratosphere, z = 30 km';
PS4.setR0(r0_4);
PS4.setOuterScale(30);
PS4.altitude = 30000; % Stratosphere (Weather Balloon Height)
PS4.lambdaRef = LAMBDA;
PS4.make;

% Sounding Rocket Height is in Mesosphere at 60 km

% % Look at the Phase Screen
clf;
figure(1)
subplot(2,2,1)
PS1.show;
subplot(2,2,2)
PS2.show;
subplot(2,2,3)
PS3.show;
subplot(2,2,4)
PS4.show
colormap(jet);

%% Make the Atmosphere
ATMO = AOAtmo(A);
ATMO.name = '4 Layer Atmosphere';
% Add the Phase Screens In
ATMO.addLayer(PS1);
ATMO.addLayer(PS2);
ATMO.addLayer(PS3);
ATMO.addLayer(PS4);

% Set the Wind in m/s
ATMO.layers{1}.Wind = [5 0];
ATMO.layers{2}.Wind = [1 -1]*3;
ATMO.layers{3}.Wind = [-1 1]*9;
ATMO.layers{4}.Wind = [0 -1]*13;

ATMO.GEOMETRY = true;
% Calculate the "total" r0
r0 = ATMO.totalFriedScale

%% Guide Star Selection (not sure if we need this, but it might work as a point source if we set it to the camera height)
% SODIUM_LAYER = 90e3;

% LGS_BEACON0 = [0 0 1] * SODIUM_LAYER;
% LGS_BEACON = [0 1/206265 1] * SODIUM_LAYER;  % Offset by 1 arcsec.

% RAYLEIGH_ALTITUDE = 30e3;
% RAYLEIGH_BEACON = [0 1/206265 1] * RAYLEIGH_ALTITUDE;  % Offset by 1 arcsec.


% STAR = [0 0 1e10];
% LEO_TARGET = [0 0 400e3];
% GEOSYNC_TARGET = [0 0 42e6];

% NGS CASE
% GUIDE_STAR = STAR; % pick one.  
% SCIENCE_OBJECT = STAR; % pick one.  

% Na LGS CASE
% GUIDE_STAR = LGS_BEACON; 
% SCIENCE_OBJECT = STAR; 

% Looking at GeoSynchronous satellites using LGS
% GUIDE_STAR = LGS_BEACON; 
% SCIENCE_OBJECT = GEOSYNC_TARGET; 

CAMERA_LAYER = PS4.altitude + 250; %Put the camera slightly above the layer
POINT_SOURCE = [0 0 1] * CAMERA_LAYER;
ATMO.BEACON = POINT_SOURCE; % Set this so ATMO knows how to compute the wavefront.

% Just Look at it......for now
figure(2)
for t = 0:0.01:5 %5 seconds in hundreths (my PS's might be too small to handle longer than this)
    ATMO.time = t;
    imagesc(ATMO.grid);
    axis off
    sqar;
    bigtitle(sprintf('ATMO at time t = %0.2f',t),12);
    drawnow;
end

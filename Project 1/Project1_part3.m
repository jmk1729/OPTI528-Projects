% 528 Project 1
% Downward looking telescope
% A.T. Rodack
% 20150301

clear all; clc; close all;



lambda = AOField.RBAND; % Red light.

%% Make Our Telescope Pupil
D = 0.5; %meters
secondary = 0.3 * D;

SPACING = 0.001;           % 1 mm spacing (could probably be less)
aa = SPACING;              % for antialiasing.
spider = 0.0254;

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

altitude = [10,6500,9950];
Cn2_HV = [HVModel(0,altitude(1)),HVModel(80,altitude(2)),HVModel(85,altitude(3))];
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
ATMO.show

input 'Continue...'

N1=2; N2=2;

%% Make an AOField object.

F = AOField(A);
F.name = 'Field';
F.resize(1024); % make it big to study the field before the pupil.
F.FFTSize = 1024; % Used to compute PSFs, etc.
F.lambda = lambda;

F.planewave*A;
F.show;

[x,y] = F.coords;

input 'Continue...'

% This adds a reference wave to the field and computes the intensity.
imagesc(x,y,F.interferometer(1),[0 3]);
sqar;
axis xy;
drawnow;
input 'Continue...'

THld = F.lambda/D * 206265; % Lambda/D in arcsecs.
FOV = 4;
PLATE_SCALE = THld/5;

F.planewave*A;
[PSF,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
PSFmax = max(PSF(:));

fprintf('Use light from a finite-distance beacon.\n')


%% This doesn't include the geometry, just the OPD from the layers...
% ATMO.useGeometry(false);
% 
% for t=0:.01:1
%     ATMO.setObsTime(t);
%     F.planewave*ATMO*A;
%     
%     subplot(N1,N2,1);
%     ATMO.show;
%     title(sprintf('wavefront:time=%.3fs',t));
%     
%     subplot(N1,N2,2);
%     F.show;
%     colorbar off;
%     title('Field');
% 
%     
%     subplot(N1,N2,3);
%     [PSF,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
%     imagesc(thx,thy,log10(PSF/PSFmax),[-4 0]);
%     daspect([1 1 1]);
%     axis xy;
%     colorbar off;
%     title('PSF');
%     
%     subplot(N1,N2,4);
%     imagesc(x,y,F.interferometer(1),[0 4]); sqar;
%     axis xy;
%     title('interferometer');
%     
%     
%     drawnow;
% end

%% Propagate Between Screens

% Make Screens
ps1 = AOScreen(2*1024);
ps1.name = 'Ground Layer';
ps1.spacing(0.02);
ps1.setCn2(Cn2_HV(1));
ps1.make;
clf;
ps1.show;
input 'Continue...'

ps2 = AOScreen(2*1024);
ps2.name = 'Mid Layer';
ps2.spacing(0.02);
ps2.setCn2(Cn2_HV(2));
ps2.make;
clf;
ps2.show;
input 'Continue...'

ps3 = AOScreen(2*1024);
ps3.name = 'Camera Layer';
ps3.spacing(0.02);
ps3.setCn2(Cn2_HV(3));
ps3.make;
clf;
ps3.show;
input 'Continue...'










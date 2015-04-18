% 528 Project 1
% Running some tests
% Justin Knight

clear all; clc; close all;

lambda = AOField.RBAND; % Red light.
k = (2*pi)/lambda;
N = 512;

% Choose to Step Through Propagation
plotsteps = true;

N1=2; N2=2;

%% Make our telescope pupil
D = 0.5; % meters
secondary = 0.3 * D;
% secondary = 0;

% PSF Stuff
THld = lambda/D * 206265; % Lambda/D in arcsecs.
FOV =   25*THld; % FOV for PSF computation
PLATE_SCALE = THld/5; % Pixel Size for PSF computations -- set by our first order parameter
CCD1 = 0;

SPACING = 0.001;           % 1 mm spacing (could probably be less)
aa = SPACING;              % for antialiasing.
spider = 0.0254/2;
% spider = 0;

PUPIL_DEFN = [
    0 0 D         1 aa 0 0 0 0 0
    0 0 secondary 0 aa/2 0 0 0 0 0
    0 0 spider   -2 aa 4 0 D/1.9 0 0
    ];

A = AOSegment;
A.spacing(SPACING);
A.name = 'Circular Pupil';
A.pupils = PUPIL_DEFN;
A.make;
% clf;
% colormap(gray);

% A.show;
input 'Press ENTER to Continue...'


%% Make a test phase screen
ATMO = AOAtmo(A);
ATMO.name = 'Testing the Atmosphere';
height = 10000;

% for z = 1:1000:height
ps = AOScreen(2*1024);
ps.name = 'Propagating';
ps.spacing(0.02);
% ps.setCn2(1e-17);
ps.setR0(0.15);
ATMO.addLayer(ps,0);
% ATMO.layers{1}.Wind = randn([1 2])*15;
% ATMO.make;
% ps.make;
% end

%% Guide star selection
CAMERA = [0 0 1] * height;
ATMO.BEACON = CAMERA; % Set this so ATMO knows how to compute the wavefront.

% fprintf('\n Making ATMO....\n');
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

ATMO.useGeometry(false);
count = 1;

for z=0:250:height
    ATMO.layers{count}.screen.altitude = z;
%     ps = AOScreen(2*1024);
%     ps.name = 'Propagation';
%     ps.spacing(0.02);
    %     ps.setCn2(1e-17);
%     ps.setR0(0.07)
%     ATMO.addLayer(ps,z);
%     ATMO.make
    %         ATMO.setObsTime(t);
    F.planewave*ATMO*A;
    
    subplot(N1,N2,1);
    ATMO.show;
    title(sprintf('Wavefront at z = %.1f km',1e-3*(height - z)));
    %     title(sprintf('wavefront:time=%.3fs',t));
    
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
    ATMO.layers{count}.screen.show;
    title('Turbulence');
    
    drawnow;
%     input 'Press a key to continue'
%     ATMO.deleteLayer(count);
%     count = count + 1;
end

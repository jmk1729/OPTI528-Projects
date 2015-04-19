% 528 Project 1
% Downward looking telescope
% A.T. Rodack
% 20150301

clear all; clc; close all;


%% Preliminary Important Stuff
lambda = AOField.VBAND; % Red light.
k = (2*pi)/lambda;
endtime = 0.5;

% Pupil Choices
D = 0.5592; %meters
secondary = 0.3 * D;
spider = 0.0254/2;

% Set Flags
turbulence = true; %use to set whether or not turbulence is included
checkperformance = true; %does the convolution with the PSFs to estimate image quality

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
% altitude = [10,5000,9990];
% thickness = [altitude(1),altitude(2)-altitude(1),altitude(3)-altitude(2)];
% windSpeed = 0.0024 .* altitude; %only valid up to 10 km
% HV_alts = [thickness(1)/2,altitude(2)-thickness(2)/2,altitude(3) - thickness(3)/2];
% Cn2_HV = thickness .* HVModel(windSpeed,HV_alts);
% Cn2_SLC = [SLCModel('day',altitude(1)),SLCModel('day',altitude(2)),SLCModel('day',altitude(3))];

% for n=1:3
%     ps = AOScreen(2*1024);
%     ps.name = sprintf('Layer %d',n);
%     ps.spacing(0.02);
%     ps.setCn2(Cn2_HV(n),thickness(n));
% %     ps.setR0(r0_mat(n));
%     ATMO.addLayer(ps,altitude(n));
%     ATMO.layers{n}.Wind = randn([1 2])*15; % random wind layers.
% end

%% Use r0 instead
[windSpeed, Vrms, r0] = estr0(5,1:0.1:10000,true);
layerr0 = [r0,0.05];
r0thickness = [9000,1000];
r0heights = [0,9000];
ATMO = AOAtmo(A);
ATMO.name = 'Layered Atmosphere';

for n=1:2
    ps = AOScreen(2*1024);
    ps.name = sprintf('Layer %d',n);
    ps.spacing(0.02);
    ps.setR0(layerr0(n),r0thickness(n));
    ATMO.addLayer(ps,r0heights(n));
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

% PSF Stuff
THld = lambda/D * 206265; % Lambda/D in arcsecs.
FOV =   15*THld; % FOV for PSF computation
PLATE_SCALE = THld/2; % Pixel Size for PSF computations -- set by our first order parameter
CCD1 = 0;


F.planewave*A;
[x,y] = F.coords;

F.planewave*A;
[PSF_DL,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
PSFmax = max(PSF_DL(:));

%%
input 'Press a key to Continue'

h = figure(1);
ATMO.useGeometry(false);
counter = 1;
for t=0:.01:endtime
    ATMO.setObsTime(t);
    if turbulence == true
        F.planewave*ATMO*A;
    else
        F.planewave*A;
    end
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
    daspect([1,1,1]);
    colormap(gray);
    
    
    drawnow;
%     M1(counter) =getframe(h);
    counter = counter + 1;
end



%% Check Performance
if checkperformance == true

    input 'Press Enter to Continue'
    
    
    CCD1max = max(CCD1(:));
    
    CCD1 = CCD1 / CCD1max;
    
    % Load in Image of Steward Observatory from Google Earth
    img = imread('full_size_SO_pic.PNG');
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

    
    figure(4)
    clf;
    subplot(1,2,1)
    imagesc(img_DL);
    sqar;
    title('Diffraction Limited Case');
    axis off
    drawnow;
    
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

end
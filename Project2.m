% 528 Project 1
% Downward looking telescope
% A.T. Rodack
% 20150301

clear all; clc; close all;


%% Preliminary Important Stuff
lambda = AOField.VBAND; % Red light.
k = (2*pi)/lambda;
endtime = 1e-3;

% Pupil Choices
D = 1.12; %meters
secondary = 0.3 * D;
spider = 0.0254;

% Set Flags
turbulence = true; %use to set whether or not turbulence is included
AO = false;
checkperformance = false; %does the convolution with the PSFs to estimate image quality

correction_layer = 3;
N1=2; N2=2;

%% Make Our Telescope Pupil
SPACING = 0.005;           % 1 mm spacing (could probably be more)
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
r0heights  = [7050,3800,1290];
[Vrms, r0, Cn2List,windSpeed] = estr0(1,true,45,r0heights);
flightwind = (35 * (r0heights/7070));
layerwinddir = round(2*rand(1,2)-1);

ATMO = AOAtmo(A);
ATMO.name = 'Layered Atmosphere';

for n=1:length(r0);
    ps = AOScreen(2^12);
    ps.name = sprintf('Layer %d',n);
    ps.spacing(0.02);
    ps.setR0(r0(n));
    ATMO.addLayer(ps,r0heights(n));
    Wind = [0,1]*flightwind(n) + layerwinddir * windSpeed(n);
    ATMO.layers{n}.Wind = Wind;
end
fprintf('*********************************************\n');
fprintf('The total r0 is %0.4f cm\n',ATMO.totalFriedScale * 10^2); 
fprintf('The Isoplanatic Angle is %0.4f arcseconds\n',(ATMO.totalFriedScale / 10000)*206265);
fprintf('The Coherence Time is %0.4f ms\n',0.314*(ATMO.totalFriedScale/sqrt(ATMO.layers{1}.Wind(1)^2 + ATMO.layers{1}.Wind(2)^2))*10^3);
fprintf('The required AO servo rate is at least %0.4f Hz\n',(0.314*(ATMO.totalFriedScale/sqrt(ATMO.layers{1}.Wind(1)^2 + ATMO.layers{1}.Wind(2)^2)))^-1)
fprintf('*********************************************\n');

% Define some beacons from which to calculate ATMO OPLs...
%% Guide star selection
CAR = [0 0 1] * 9000;
ATMO.BEACON = CAR; % Set this so ATMO knows how to compute the wavefront.

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
% PLATE_SCALE = THld/3; % Pixel Size for PSF computations -- set by our first order parameter
PLATE_SCALE = 0.0187;
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
for t=0:1e-5:endtime
    ATMO.setObsTime(t);
    if turbulence == true
        if AO == false
            F.planewave*ATMO*A;
        elseif AO == true
            correction = AOScreen(1);
            correction.spacing(SPACING);
            OPL = -ATMO.grid;
            correction.grid((0.5*rand(1,1)+0.5)*OPL);
            F.planewave*ATMO*A*correction;
        end
    else
        F.planewave*A;
    end
    subplot(N1,N2,1);
% subplot(1,2,1)
    ATMO.show;
    title(sprintf('wavefront:time=%.3f ms',t*10^3));
    colorbar off;
    
    subplot(N1,N2,2);
% subplot(1,2,2)
    F.show;
    colorbar off;
    title('Field');

    
    subplot(N1,N2,3);
    [PSF,thx,thy] = F.mkPSF(FOV,PLATE_SCALE);
    PSF_turbmax = max(PSF(:));
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
    M1(counter) =getframe(h);
    counter = counter + 1;
end

fprintf('The Strehl Ratio is about %0.4f\n',max(CCD1(:))/PSFmax);

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
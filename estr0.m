function [windSpeed, Vrms, r0] = estr0(month,altitude,rmsFlag)
% Outputs the wind speed for the input month (1-12) and list of altitudes,
% option for rms wind speed and r0 estimation

%% Initializations
Tucson = load('Tucson.mat'); % Load table data from Optics Express, Vol. 19, Issue 2, pp. 820-837 (2011) http://dx.doi.org/10.1364/OE.19.000820
AConst = Tucson.a;
ACMonth = AConst(month,1:4);
LowAlt = 1000; % meters
HighAlt = 10000; % meters
lambda = AOField.VBAND;
k = 2*pi/lambda; % meters
%% Wind Speed Calculation
% Start with non-linear least squares data fit, this should be a Gaussian
A0 = ACMonth(1);
A1 = ACMonth(2);
A2 = ACMonth(3);
A3 = ACMonth(4);

windSpeed = A0 + A1*exp(-((altitude-A2)/A3).^2); % Equation (3) in the reference paper, altitude in meters

% Sanity check
% figure(1);
% plot(windSpeed, altitude);
% xlabel('Wind Speed (m/s)');
% ylabel('Altitude from mean sea level (m)');
% title('Wind Profile');

%% Integrate for RMS Wind Speed
if rmsFlag == true
    Vsq = @(z) (A0 + A1*exp(-((z-A2)/A3).^2)).^2;
    Vrms = sqrt((1/15000)*integral(Vsq,LowAlt,HighAlt)); %Dyson Principles of AO 3rd Ed. equation (2.16)
else
    Vrms = 'Not Computed';
end

%% r0 Calculation
% Fried coherence length calculated using the rms wind speed parameter.
if rmsFlag == true
    A = 1.7e-14; % Cn2 at ground level, published value referenced in HVModel ref 2)
    Cn2 = @(h) 0.00594*((Vrms/27).^2).*(((10^-5).*h).^10).*exp(-h./1000) ...
        +(2.7*10^-16)*exp(-h./1500) + A.*exp(-h./100); % HVModel
    
    figure(2)
    fplot(Cn2,[LowAlt,HighAlt]);
    xlabel('Altitude in meters');
    ylabel('H-V Computed C_n^2');

    r0 = (0.423*k^2*integral(Cn2,LowAlt,HighAlt)).^(-3/5); % Dyson
else
    r0 = 'Not Computed';
end
end
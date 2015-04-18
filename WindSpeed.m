function windSpeed = WindSpeed(month,altitude)
% Outputs the wind speed for the input month (1-12) and list of altitudes
%
%% Initializations
Tucson = load('Tucson.mat'); % Load table data from Optics Express, Vol. 19, Issue 2, pp. 820-837 (2011) http://dx.doi.org/10.1364/OE.19.000820
AConst = Tucson.a;
ACMonth = AConst(month,1:4);

%% Wind Speed Calculation
% Start with non-linear least squares data fit, this should be a Gaussian
A0 = ACMonth(1);
A1 = ACMonth(2);
A2 = ACMonth(3);
A3 = ACMonth(4);

windSpeed = A0 + A1*exp(-((altitude-A2)/A3).^2); % Equation (3) in the reference paper, altitude in meters

% Sanity check
figure;
plot(windSpeed, altitude);
xlabel('Wind Speed (m/s)');
ylabel('Altitude from mean sea level (km)');
title('Wind Profile');
end
clear all
close all
% Working Directory for Sept 05 Survey:
% C:\MyFiles\Columbia\FieldJune2005\Survey\CG_2005SurveyData_Shad\
% Note Coords in arbitrary coord system
addpath('C:\MyFiles\MatlabUtilities')
data = xlsread('SeptSurveyMatlabIn','ExportMatlab'); %loads marker 555 data
%Time Bounds Now At:
tstart = 257.5; tend = 259.75;
t=data(:,1); %Time in decimal days; day 257 = Sept 14th
yl=data(:,3); %y = Northing (main flow direction)
xl=data(:,2); %x = Easting
z=data(:,4); %z = Elevation
n = length(t); %Length of time series
% Convert coordinates to UTM:
% Gun at 
Gn = 6775852.739;
Ge =  497126.859;
% Ref at 
Rn = 6775984.429;
Re =  497126.388;
% >> Line Gun to Ref points 0.2049 degrees W of N.
dela = deg2rad(-.2049);
Rotmat = [ cos(dela) sin(dela); -sin(dela) cos(dela)]
for it = 1:n
    Plocal= [yl(it),xl(it)]';
    Ptrans = Rotmat*Plocal;
    Nutm(it)= Ptrans(1) - 5000 + Gn; 
    Eutm(it)= Ptrans(2) - 5000 + Ge;
end
%Reduce UTM coords to local numbers by
y = Nutm - 6770000.0;
x = Eutm -  490000.0;
%========= End coordinate transform ============
% Do speed calculation

for i=1:n-1

t_avg(i)=(t(i+1)+t(i))./2;    %average times
disp(i)=sqrt((x(i+1)-x(i)).^2+(y(i+1)-y(i)).^2);  %horizontal displacements (new vector)
dispz(i) = z(i+1) - z(i);
end

delta_t=diff(t);   %time intervals between measurements

v=disp./delta_t';  %Velocity
vz = dispz./delta_t'; %Vertical Velocity
% 
figure(1); clf
subplot(2,1,1)
plot(t_avg,v,'.');hold on
axis([tstart,tend,0,22]);
% FILTER using HPs non-parametric filter ===========
%Specific Times: 257.5 to 258.75
%Survey interval 0.007 day = 10 minutes
%Dec Day: 0.1 hr = 0.00417
%         0.2 hr = 0.0083
%         0.5 hr = 0.02083
%         1.0 hr = 0.04166
%         3.0 hr = 0.1251
%         4.0 hr = 0.1667
tmin=tstart; tmax=tend; 
stepsize=0.0083; 
winsize=[0.2500, 0.1251, 0.04166];
color='krg';
%T IS TIME, V IS THE SIGNAL
for i=1:3
  [tmod,vmod]=nonparametric_smooth(t_avg,v,tmin,tmax,stepsize,winsize(i));
  h=plot(tmod,vmod,color(i)); set(h,'linewidth',3); title('Horizontal Velocity')
end
% Plot Vertical Velocities
subplot(2,1,2)
plot(t_avg,vz,'.');hold on
axis([tstart, tend,-10,10]);

%T IS TIME, V IS THE SIGNAL
for i=1:3
  [tmod,vmod]=nonparametric_smooth(t_avg,vz,tmin,tmax,stepsize,winsize(i));
  h=plot(tmod,vmod,color(i)); set(h,'linewidth',3); title('Vertical Velocity')
end

% % ========= Find Power Spectrum ======================================
% % Y = fft(v,512);
% % %The power spectrum, a measurement of the power at various frequencies, is
% % Pyy = Y.* conj(Y) / 512; f = 1000*(0:256)/512;
Y = fft(v);
N = length(Y);
Y(1) = [];
power = abs(Y(1:N/2)).^2;
nyquist = 1/2;
freq = (1:N/2)/(N/2)*nyquist;
period = 1./freq;
figure(2);
plot(freq,power), grid on
xlabel('cycles/day')
title('Periodogram')


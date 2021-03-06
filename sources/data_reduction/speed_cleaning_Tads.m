clear all
close all
% Working Directory for Sept 05 Survey:
% C:\MyFiles\Columbia\FieldJune2005\Survey\CG_2005SurveyData_Shad\
% Note Coords in arbitrary coord system
addpath('C:\MyFiles\MatlabUtilities')
data = xlsread('SeptSurveyMatlabIn','ExportMatlab'); %loads marker 555 data

t=data(:,1);
y=data(:,3); %y = Northing (main flow direction)
x=data(:,2); %x = Easting
z=data(:,4);

n=length(x);  %number data
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
plot(t_avg,v,'.');hold on
axis([257.5,258.75,0,22]);
% FILTER using HPs non-parametric filter ===========
%Specific Times: 257.5 to 258.75
%Survey interval 0.007 day = 10 minutes
%Dec Day: 0.1 hr = 0.00417
%         0.2 hr = 0.0083
%         0.5 hr = 0.02083
%         1.0 hr = 0.04166
%         4.0 hr = 0.1667
tmin=257.5; tmax=258.75; 
stepsize=0.02083; 
winsize=[0.04166, 0.02083 0.0083];
color='krg';
%T IS TIME, V IS THE SIGNAL
for i=1:3
  [tmod,vmod]=nonparametric_smooth(t_avg,v,tmin,tmax,stepsize,winsize(i));
  h=plot(tmod,vmod,color(i)); set(h,'linewidth',3);
end
% Plot Vertical Velocities
figure(2); clf
plot(t_avg,vz,'.');hold on
axis([257.5,258.75,-10,10]);
% FILTER using HPs non-parametric filter ===========
%Specific Times: 257.5 to 258.75
%Survey interval 0.007 day = 10 minutes
%Dec Day: 0.1 hr = 0.00417
%         0.2 hr = 0.0083
%         0.5 hr = 0.02083
%         1.0 hr = 0.04166
%         4.0 hr = 0.1667
tmin=257.5; tmax=258.75; 
stepsize=0.02083; 
winsize=[0.04166, 0.02083 0.0083];
color='krg';
%T IS TIME, V IS THE SIGNAL
for i=1:3
  [tmod,vmod]=nonparametric_smooth(t_avg,vz,tmin,tmax,stepsize,winsize(i));
  h=plot(tmod,vmod,color(i)); set(h,'linewidth',3);
end

% ========= Find Power Spectrum ======================================
% Y = fft(v,512);
% %The power spectrum, a measurement of the power at various frequencies, is
% Pyy = Y.* conj(Y) / 512; f = 1000*(0:256)/512;
Y = fft(v);
N = length(Y);
Y(1) = [];
power = abs(Y(1:N/2)).^2;
nyquist = 1/2;
freq = (1:N/2)/(N/2)*nyquist;
figure(3);
plot(freq,power), grid on
xlabel('cycles')
title('Periodogram')


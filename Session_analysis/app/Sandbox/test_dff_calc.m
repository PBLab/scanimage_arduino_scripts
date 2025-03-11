% Parameters
fs = 60;            % Sampling frequency (Hz)
t = 0:1/fs:10-1/fs;   % Time vector (10 seconds)
f0= 5;
f1 = 10;              % Frequency of first sine wave (Hz)
f2 = 40;              % Frequency of second sine wave (Hz)

% Generate synthetic signal with two sine waves and added noise
signal =sin(2*pi*f0*t)*2 + sin(2*pi*f1*t) + sin(2*pi*f2*t) + 0.5*randn(size(t));

% Define dff_calc parameters
tau_0 = 1;  % Exponential smoothing factor in seconds
tau_1 = 0.5; % F0 smoothing parameter in seconds
tau_2 = 1.0;  % Time window before each measurement to minimize
invert = false;

% Apply dff_calc function
dff_signal = dff_calc(signal, fs, tau_0, tau_1, tau_2, invert);

% Plotting
figure;

% Determine symmetric y-limits for the original signal
max_abs_signal = max(abs(signal));
ylim_left = [-max_abs_signal, max_abs_signal];

% Determine symmetric y-limits for the dF/F signal
max_abs_dff = max(abs(dff_signal));
ylim_right = [-max_abs_dff, max_abs_dff];

% Left subplot: Time-domain signals
subplot(1, 2, 1);
yyaxis left;
plot(t, signal, 'b-');
xlabel('Time (s)');
ylabel('Original Signal');
title('Time-Domain Signals');
grid on;
ylim(ylim_left); % Set symmetric y-limits for the left axis

yyaxis right;
plot(t, dff_signal, 'r-');
ylabel('dF/F Signal');
legend('Original Signal', 'dF/F Signal');
ylim(ylim_right); % Set symmetric y-limits for the right axis

% Compute FFT for original and dF/F signals
n = length(t);
f = fs*(0:(n/2))/n; % Frequency vector

fft_signal = fft(signal);
P2_signal = abs(fft_signal/n);
P1_signal = P2_signal(1:n/2+1);
P1_signal(2:end-1) = 2*P1_signal(2:end-1);

fft_dff_signal = fft(dff_signal);
P2_dff_signal = abs(fft_dff_signal/n);
P1_dff_signal = P2_dff_signal(1:n/2+1);
P1_dff_signal(2:end-1) = 2*P1_dff_signal(2:end-1);

% Right subplot: Frequency-domain (FFT) signals
subplot(1, 2, 2);
plot(f, P1_signal, 'b-');
hold on;
plot(f, P1_dff_signal, 'r-');
hold off;
title('Frequency-Domain Signals');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
legend('Original Signal', 'dF/F Signal');
grid on;
set(gca,'Yscale','log')

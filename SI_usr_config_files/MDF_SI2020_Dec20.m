% Global microscope properties
objectiveResolution = 15;     % Resolution of the objective in microns/degree of scan angle

% Data file location

% Custom Scripts
startUpScript = '';     % Name of script that is executed in workspace 'base' after scanimage initializes
shutDownScript = '';     % Name of script that is executed in workspace 'base' after scanimage exits

fieldCurvatureZs = [];     % Field curvature for mesoscope
fieldCurvatureRxs = [];     % Field curvature for mesoscope
fieldCurvatureRys = [];     % Field curvature for mesoscope
useJsonHeaderFormat = false;     % Use JSON format for TIFF file header

%% scanimage.components.Motors (SI Motors)
% SI Stage/Motor Component.
motorXYZ = {'mom' 'mom' 'mom'};     % Defines the motor for ScanImage axes X Y Z.
motorAxisXYZ = [1 2 3];     % Defines the motor axis used for Scanimage axes X Y Z.
scaleXYZ = [1 1 1];     % Defines scaling factors for axes.
backlashCompensation = [0 0 0];     % Backlash compensation in um (positive or negative)

%% scanimage.components.Photostim (SI Photostim)
photostimScannerName = '';     % Name of scanner (from first MDF section) to use for photostimulation. Must be a linear scanner

% Monitoring DAQ AI channels
BeamAiId = [];     % AI channel to be used for monitoring the Pockels cell output

loggingStartTrigger = '';     % PFI line to which start trigger for logging is wired to photostim board. Leave empty for automatic routing via PXI bus

stimActiveOutputChannel = '';     % Digital terminal on stim board to output stim active signal. (e.g. on vDAQ: 'D2.6' on NI-DAQ hardware: '/port0/line0'
beamActiveOutputChannel = '';     % Digital terminal on stim board to output beam active signal. (e.g. on vDAQ: 'D2.7' on NI-DAQ hardware: '/port0/line1'
slmTriggerOutputChannel = '';     % Digital terminal on stim board to trigger SLM frame flip. (e.g. on vDAQ: 'D2.5' on NI-DAQ hardware: '/port0/line2'

%% dabs.generic.DigitalShutter (Imaging Shutter)
DOControl = '/PXI1Slot4/PFI0';     % control terminal  e.g. '/vDAQ0/DIO0'
invertOutput = false;     % invert output drive signal to shutter
openTime_s = 0.1;     % settling time for shutter in seconds

%% dabs.generic.ResonantScannerAnalog (Res Scanner)
AOZoom = '/PXI1Slot3/AO0';     % zoom control terminal  e.g. '/vDAQ0/AO0'
DOEnable = '';     % digital enable terminal e.g. '/vDAQ0/D0.1'
DISync = '/PXI1Slot2/PFI0';     % digital sync terminal e.g. '/vDAQ0/D0.0'

nominalFrequency = 7910;     % nominal resonant frequency in Hz
angularRange = 20;     % total angular range in optical degrees (e.g. for a resonant scanner with -13..+13 optical degrees, enter 26)
voltsPerOpticalDegrees = 0.19231;     % volts per optical degrees for the control signal
settleTime = 0.5;     % settle time in seconds to allow the resonant scanner to turn on

% Calibration Settings
amplitudeToLinePhaseMap = [0.667 -6.16667e-07;0.741 -7.91667e-07;0.8 -1.05833e-06;0.833 -1.08333e-06;1 -1.39167e-06;1.053 -1.325e-06;1.111 -1.40833e-06;1.176 1.44583e-05;1.25 -1.575e-06;1.333 -1.61667e-06;1.538 -1.80833e-06;1.667 -1.975e-06;1.818 -1.925e-06;2 -2.125e-06;2.222 -2.1e-06;2.5 -2.25e-06;2.857 -2.29167e-06;3.333 -2.33333e-06;3.846 -2.36667e-06;4 -2.44167e-06;5 -2.48333e-06;5.12821 -2.425e-06;5.26316 -2.425e-06;6.25 -2.46667e-06;6.452 -2.55e-06;6.66667 -2.425e-06;6.667 -2.575e-06;10 -2.675e-06;10.526 -2.46667e-06;16.667 -2.68333e-06;20 -2.66667e-06];     % translates an amplitude (degrees) to a line phase (seconds)
amplitudeToFrequencyMap = [0.833 7925.78;1.667 7931.11;2 7930.71;2.5 7929.24;2.857 7929.48;3.333 7929.31;4 7932.77;5 7927.67;6.25 7926.48;6.667 7927.13;10 7926.3;15.385 7926.48;16.667 7927.35;18.182 7926.31;20 7931.12];     % translates an amplitude (degrees) to a resonant frequency (Hz)
amplitudeLUT = zeros(0,2);     % translates a nominal amplitude (degrees) to an output amplitude (degrees)

%% dabs.generic.GalvoPureAnalog (Y Galvo)
AOControl = '/PXI1Slot3/AO1';     % control terminal  e.g. '/vDAQ0/AO0'
AOOffset = '';     % control terminal  e.g. '/vDAQ0/AO0'
AIFeedback = '';     % feedback terminal e.g. '/vDAQ0/AI0'

angularRange = 20;     % total angular range in optical degrees (e.g. for a galvo with -20..+20 optical degrees, enter 40)
voltsPerOpticalDegrees = 0.78;     % volts per optical degrees for the control signal
parkPosition = 0;     % park position in optical degrees
slewRateLimit = Inf;     % Slew rate limit of the analog output in Volts per second

% Calibration settings
feedbackVoltLUT = zeros(0,2);     % [Nx2] lut translating feedback volts into position volts
offsetVoltScaling = 1;     % scalar factor for offset volts

%% dabs.generic.BeamModulatorFastAnalog (Imaging Beam)
AOControl = '/PXI1Slot4/AO0';     % control terminal  e.g. '/vDAQ0/AO0'
AIFeedback = '/PXI1Slot4/AI0';     % feedback terminal e.g. '/vDAQ0/AI0'

outputRange_V = [0 4];     % Control output range in Volts
feedbackUsesRejectedLight = false;     % Indicates if photodiode is in rejected path of beams modulator.
calibrationOpenShutters = {'Imaging Shutter'};     % List of shutters to open during the calibration. (e.g. {'Shutter1' 'Shutter2'}

powerFractionLimit = 1;     % Maximum allowed power fraction (between 0 and 1)

% Calibration data
powerFraction2ModulationVoltLut = [0 0.040404;0.00155096 0.0808081;0.00292959 0.121212;0.00499754 0.161616;0.00760709 0.20202;0.0101305 0.242424;0.0134294 0.282828;0.0175283 0.323232;0.0221812 0.363636;0.026514 0.40404;0.0320532 0.444444;0.0379616 0.484848;0.0440793 0.525253;0.0510955 0.565657;0.0576194 0.606061;0.0652388 0.646465;0.0738676 0.686869;0.0820409 0.727273;0.0909282 0.767677;0.100086 0.808081;0.109884 0.848485;0.120938 0.888889;0.131155 0.929293;0.141691 0.969697;0.15309 1.0101;0.165313 1.05051;0.176797 1.09091;0.189106 1.13131;0.201453 1.17172;0.214562 1.21212;0.22665 1.25253;0.240756 1.29293;0.254038 1.33333;0.267713 1.37374;0.282275 1.41414;0.295298 1.45455;0.310438 1.49495;0.324754 1.53535;0.33939 1.57576;0.354358 1.61616;0.369929 1.65657;0.384601 1.69697;0.3992 1.73737;0.414402 1.77778;0.430588 1.81818;0.445212 1.85859;0.460303 1.89899;0.475185 1.93939;0.491433 1.9798;0.506955 2.0202;0.521246 2.06061;0.536903 2.10101;0.552745 2.14141;0.565916 2.18182;0.581438 2.22222;0.59611 2.26263;0.611251 2.30303;0.62484 2.34343;0.640042 2.38384;0.654998 2.42424;0.667738 2.46465;0.681265 2.50505;0.69627 2.54545;0.708567 2.58586;0.721344 2.62626;0.734466 2.66667;0.748129 2.70707;0.760081 2.74747;0.77164 2.78788;0.785094 2.82828;0.795963 2.86869;0.806832 2.90909;0.818538 2.94949;0.830638 2.9899;0.839291 3.0303;0.849434 3.07071;0.859897 3.11111;0.870556 3.15152;0.879739 3.19192;0.886743 3.23232;0.896972 3.27273;0.904444 3.31313;0.914156 3.35354;0.921024 3.39394;0.92969 3.43434;0.936411 3.47475;0.941704 3.51515;0.949766 3.55556;0.956118 3.59596;0.95986 3.63636;0.968304 3.67677;0.972255 3.71717;0.97676 3.75758;0.982829 3.79798;0.986731 3.83838;0.989562 3.87879;0.993808 3.91919;0.998929 3.9596;1 4];
powerFraction2PowerWattLut = zeros(0,2);
powerFraction2FeedbackVoltLut = [0 -0.00139662;1 1.067];
feedbackOffset_V = 0.332974;

% Advanced Settings. Note: these settings are unused for vDAQ based systems
modifiedLineClockIn = '';     % Terminal to which external beam trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
frameClockIn = '';     % Terminal to which external frame clock is connected. Leave empty for automatic routing via PXI/RTSI bus
referenceClockIn = '';     % Terminal to which external reference clock is connected. Leave empty for automatic routing via PXI/RTSI bus
referenceClockRate = 1e+07;     % if referenceClockIn is used, referenceClockRate defines the rate of the reference clock in Hz. Default: 10e6Hz

calibrationNumPoints = 100;
calibrationNumRepeats = 5;
calibrationAverageSamples = 5;
calibrationSettlingTime_s = 0.001;
calibrationFlybackTime_s = 0.2;

%% scanimage.components.scan2d.ResScan (ImagingScanner)
% DAQ settings
rioDeviceID = 'RIO0';     % FlexRIO Device ID as specified in MAX. If empty, defaults to 'RIO0'
digitalIODeviceName = 'PXI1Slot2';     % String: Device name of the DAQ board or FlexRIO FPGA that is used for digital inputs/outputs (triggers/clocks etc). If it is a DAQ device, it must be installed in the same PXI chassis as the FlexRIO Digitizer

channelsInvert = [true true true true];     % Logical: Specifies if the input signal is inverted (i.e., more negative for increased light signal)

externalSampleClock = false;     % Logical: use external sample clock connected to the CLK IN terminal of the FlexRIO digitizer module
externalSampleClockRate = 8e+07;     % [Hz]: nominal frequency of the external sample clock connected to the CLK IN terminal (e.g. 80e6); actual rate is measured on FPGA

enableRefClkOutput = false;     % Enables/disables the 10MHz reference clock output on PFI14 of the digitalIODevice

% Scanner settings
resonantScanner = 'Res Scanner';     % Name of the resonant scanner
xGalvo = '';     % Name of the x galvo scanner
yGalvo = 'Y Galvo';     % Name of the y galvo scanner
beams = {'Imaging Beam' 'OrangeBeam'};     % beam device names
fastZs = {};     % fastZ device names
shutters = {'Imaging Shutter'};     % shutter device names

extendedRggFov = false;     % If true and x galvo is present, addressable FOV is combination of resonant FOV and x galvo FOV.
keepResonantScannerOn = false;     % Always keep resonant scanner on to avoid drift and settling time issues

% Advanced/Optional
PeriodClockDebounceTime = 1e-07;     % [s] time the period clock has to be stable before a change is registered
TriggerDebounceTime = 5e-07;     % [s] time acquisition, stop and next trigger to be stable before a change is registered
reverseLineRead = 0;     % flips the image in the resonant scan axis

% Aux Trigger Recording, Photon Counting, and I2C are mutually exclusive

% Aux Trigger Recording
auxTriggersEnable = true;
auxTriggersTimeDebounce = 1e-06;     % [s] time an aux trigger needs to be high for registering an edge (seconds)
auxTriggerLinesInvert = [false;false;false;false];     % [logical] 1x4 vector specifying polarity of aux trigger inputs

% Photon Counting
photonCountingEnable = false;
photonCountingDisableAveraging = [];     % disable averaging of samples into pixels; instead accumulate samples
photonCountingScaleByPowerOfTwo = 8;     % for use with photonCountingDisableAveraging == false; scale count by 2^n before averaging to avoid loss of precision by integer division
photonCountingDebounce = 2.5e-08;     % [s] time the TTL input needs to be stable high before a pulse is registered

% I2C
I2CEnable = false;
I2CAddress = 0;     % [byte] I2C address of the FPGA
I2CDebounce = 5e-07;     % [s] time the I2C signal has to be stable high before a change is registered
I2CStoreAsChar = false;     % if false, the I2C packet bytes are stored as a uint8 array. if true, the I2C packet bytes are stored as a string. Note: a Null byte in the packet terminates the string
I2CDisableAckOutput = false;     % the FPGA confirms each packet with an ACK bit by actively pulling down the SDA line. I2C_DISABLE_ACK_OUTPUT = true disables the FPGA output

% Laser Trigger
LaserTriggerPort = '';     % Port on FlexRIO AM digital breakout (DIO0.[0:3]) where laser trigger is connected.
LaserTriggerFilterTicks = 0;
LaserTriggerSampleMaskEnable = false;
LaserTriggerSampleWindow = [0 1];

% Calibration data
scannerToRefTransform = [1 0 0;0 1 0;0 0 1];

%% dabs.generic.BeamModulatorFastAnalog (OrangeBeam)
AOControl = '/PXI1Slot4/AO1';     % control terminal  e.g. '/vDAQ0/AO0'
AIFeedback = '';     % feedback terminal e.g. '/vDAQ0/AI0'

outputRange_V = [0 1.8];     % Control output range in Volts
feedbackUsesRejectedLight = false;     % Indicates if photodiode is in rejected path of beams modulator.
calibrationOpenShutters = {'Imaging Shutter'};     % List of shutters to open during the calibration. (e.g. {'Shutter1' 'Shutter2'}

powerFractionLimit = 1;     % Maximum allowed power fraction (between 0 and 1)

% Calibration data
powerFraction2ModulationVoltLut = zeros(0,2);
powerFraction2PowerWattLut = zeros(0,2);
powerFraction2FeedbackVoltLut = zeros(0,2);
feedbackOffset_V = 0;

% Advanced Settings. Note: these settings are unused for vDAQ based systems
modifiedLineClockIn = '';     % Terminal to which external beam trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
frameClockIn = '';     % Terminal to which external frame clock is connected. Leave empty for automatic routing via PXI/RTSI bus
referenceClockIn = '';     % Terminal to which external reference clock is connected. Leave empty for automatic routing via PXI/RTSI bus
referenceClockRate = 1e+07;     % if referenceClockIn is used, referenceClockRate defines the rate of the reference clock in Hz. Default: 10e6Hz

%% scanimage.SI (ScanImage)

% Global microscope properties
objectiveResolution = 15;     % Resolution of the objective in microns/degree of scan angle

% Data file location

% Custom Scripts
startUpScript = '';     % Name of script that is executed in workspace 'base' after scanimage initializes
shutDownScript = '';     % Name of script that is executed in workspace 'base' after scanimage exits

fieldCurvatureZs = [];     % Field curvature for mesoscope
fieldCurvatureRxs = [];     % Field curvature for mesoscope
fieldCurvatureRys = [];     % Field curvature for mesoscope
fieldCurvatureTip = 0;     % Field tip for mesoscope
fieldCurvatureTilt = 0;     % Field tilt for mesoscope
useJsonHeaderFormat = false;     % Use JSON format for TIFF file header

%% dabs.sutter.MPC200_Async (mom)
comPort = 'COM3';     % Serial port the stage is connected to (e.g. 'COM3')

%% ScanImage

%Global microscope properties
objectiveResolution = 15;           % Resolution of the objective in microns/degree of scan angle

%Scanner systems
scannerNames = {'ResScanner'};      % Cell array of string names for each scan path in the microscope
scannerTypes = {'Resonant'};        % Cell array indicating the type of scanner for each name. Current options: {'Resonant' 'Linear' 'SLM'}

%Simulated mode
simulated = false;                  % Boolean for activating simulated mode. For normal operation, set to 'false'. For operation without NI hardware attached, set to 'true'.

%Optional components
components = {};                    % Cell array of optional components to load. Ex: {'dabs.thorlabs.ECU1' 'dabs.thorlabs.BScope2'}

%Data file location
dataDir = '[MDF]\ConfigData';       % Directory to store persistent configuration and calibration data. '[MDF]' will be replaced by the MDF directory

startUpScript = '';

%% Shutters
%Shutter(s) used to prevent any beam exposure from reaching specimen during idle periods. Multiple
%shutters can be specified and will be assigned IDs in the order configured below.
shutterNames = {'Main Shutter'};    % Cell array specifying the display name for each shutter eg {'Shutter 1' 'Shutter 2'}
shutterDaqDevices = {'PXI1Slot3'};  % Cell array specifying the DAQ device or RIO devices for each shutter eg {'PXI1Slot3' 'PXI1Slot4'}
shutterChannelIDs = {'PFI12'};      % Cell array specifying the corresponding channel on the device for each shutter eg {'PFI12'}

shutterOpenLevel = true;               % Logical or 0/1 scalar indicating TTL level (0=LO;1=HI) corresponding to shutter open state for each shutter line. If scalar, value applies to all shutterLineIDs
shutterOpenTime = 0.1;              % Time, in seconds, to delay following certain shutter open commands (e.g. between stack slices), allowing shutter to fully open before proceeding.

%% Beams
beamDaqDevices = {};                            % Cell array of strings listing beam DAQs in the system. Each scanner set can be assigned one beam DAQ ex: {'PXI1Slot4'}

% Define the parameters below for each beam DAQ specified above, in the format beamDaqs(N).param = ...
beamDaqs(1).modifiedLineClockIn = '';           % one of {PFI0..15, ''} to which external beam trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).frameClockIn = '';                  % one of {PFI0..15, ''} to which external frame clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockIn = '';              % one of {PFI0..15, ''} to which external reference clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockRate = 10e6;          % if referenceClockIn is used, referenceClockRate defines the rate of the reference clock in Hz. Default: 10e6Hz

beamDaqs(1).chanIDs = [];                       % Array of integers specifying AO channel IDs, one for each beam modulation channel. Length of array determines number of 'beams'.
beamDaqs(1).displayNames = {};                  % Optional string cell array of identifiers for each beam
beamDaqs(1).voltageRanges = 1.5;                % Scalar or array of values specifying voltage range to use for each beam. Scalar applies to each beam.

beamDaqs(1).calInputChanIDs = [];               % Array of integers specifying AI channel IDs, one for each beam modulation channel. Values of nan specify no calibration for particular beam.
beamDaqs(1).calOffsets = [];                    % Array of beam calibration offset voltages for each beam calibration channel
beamDaqs(1).calUseRejectedLight = false;        % Scalar or array indicating if rejected light (rather than transmitted light) for each beam's modulation device should be used to calibrate the transmission curve 
beamDaqs(1).calOpenShutterIDs = [];             % Array of shutter IDs that must be opened for calibration (ie shutters before light modulation device).

%% FastZ
%FastZ hardware used for fast axial motion, supporting fast stacks and/or volume imaging

actuators(1).controllerType = '';           % If supplied, one of {'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}.
actuators(1).comPort = [];                  % Integer identifying COM port for controller, if using serial communication
actuators(1).customArgs = {};               % Additional arguments to stage controller
actuators(1).daqDeviceName = '';            % String specifying device name used for FastZ control
actuators(1).frameClockIn = '';             % One of {PFI0..15, ''} to which external frame trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
actuators(1).cmdOutputChanID = [];          % AO channel number (e.g. 0) used for analog position control
actuators(1).sensorInputChanID = [];        % AI channel number (e.g. 0) used for analog position sensing
actuators(1).commandVoltsPerMicron = 0.1;    % Conversion factor for desired command position in um to output voltage
actuators(1).commandVoltsOffset = 0;        % Offset in volts for desired command position in um to output voltage
actuators(1).sensorVoltsPerMicron = [];     % Conversion factor from sensor signal voltage to actuator position in um. Leave empty for automatic calibration
actuators(1).sensorVoltsOffset = [];        % Sensor signal voltage offset. Leave empty for automatic calibration
actuators(1).maxCommandVolts = [];          % Maximum allowable voltage command
actuators(1).maxCommandPosn = [];           % Maximum allowable position command in microns
actuators(1).minCommandVolts = [];          % Minimum allowable voltage command
actuators(1).minCommandPosn = [];           % Minimum allowable position command in microns
actuators(1).optimizationFcn = '';          % Function for waveform optimization
actuators(1).affectedScanners = {};         % If this actuator only changes the focus for an individual scanner, enter the name

%% ResScan (ResScanner)
nominalResScanFreq = 7910;          % [Hz] nominal frequency of the resonant scanner
beamDaqID = [];                     % Numeric: ID of the beam DAQ to use with the resonant scan system
shutterIDs = 1;                     % Array of the shutter IDs that must be opened for resonant scan system to operate

digitalIODeviceName = 'PXI1Slot3';  % String: Device name of the DAQ board or FlexRIO FPGA that is used for digital inputs/outputs (triggers/clocks etc). If it is a DAQ device, it must be installed in the same PXI chassis as the FlexRIO Digitizer

fpgaModuleType = 'NI7961';          % String: Type of FlexRIO FPGA module in use. One of {'NI7961' 'NI7975'}
digitizerModuleType = 'NI5734';     % String: Type of digitizer adapter module in use. One of {'NI5732' 'NI5734'}
rioDeviceID = 'RIO0';               % FlexRIO Device ID as specified in MAX. If empty, defaults to 'RIO0'
channelsInvert = [false false false false];             % Logical: Specifies if the input signal is inverted (i.e., more negative for increased light signal)

externalSampleClock = false;        % Logical: use external sample clock connected to the CLK IN terminal of the FlexRIO digitizer module
externalSampleClockRate = [];       % [Hz]: nominal frequency of the external sample clock connected to the CLK IN terminal (e.g. 80e6); actual rate is measured on FPGA

enableRefClkOutput = false;         % Enables/disables the 10MHz reference clock output on PFI14 of the digitalIODevice

%Galvo mirror settings
galvoDeviceName = 'PXI1Slot3';      % String identifying the NI-DAQ board to be used to control the galvo(s). The name of the DAQ-Device can be seen in NI MAX. e.g. 'Dev1' or 'PXI1Slot3'. This DAQ board needs to be installed in the same PXI chassis as the FPGA board specified in section
galvoAOChanIDX = [];                % The numeric ID of the Analog Output channel to be used to control the X Galvo. Can be empty for standard Resonant Galvo scanners.
galvoAOChanIDY = 1;                 % The numeric ID of the Analog Output channel to be used to control the Y Galvo.

galvoAIChanIDX = [];                % The numeric ID of the Analog Input channel for the X Galvo feedback signal.
galvoAIChanIDY = [];                % The numeric ID of the Analog Input channel for the Y Galvo feedback signal.

xGalvoAngularRange = 15;            % max range in optical degrees (pk-pk) for x galvo if present
yGalvoAngularRange = 15;            % max range in optical degrees (pk-pk) for y galvo

galvoVoltsPerOpticalDegreeX = 1;  % galvo conversion factor from optical degrees to volts (negative values invert scan direction)
galvoVoltsPerOpticalDegreeY = 1;  % galvo conversion factor from optical degrees to volts (negative values invert scan direction)

galvoParkDegreesX = -8;             % Numeric [deg]: Optical degrees from center position for X galvo to park at when scanning is inactive
galvoParkDegreesY = -8;             % Numeric [deg]: Optical degrees from center position for Y galvo to park at when scanning is inactive

%Resonant mirror settings
resonantZoomDeviceName = 'PXI1Slot3';        % String identifying the NI-DAQ board to host the resonant zoom analog output. Leave empty to use same board as specified in 'galvoDeviceName'
resonantZoomAOChanID = 0;           % resonantZoomAOChanID: The numeric ID of the Analog Output channel to be used to control the Resonant Scanner Zoom level.

resonantAngularRange = 15;          % max range in optical degrees (pk-pk) for resonant
rScanVoltsPerOpticalDegree = 0.3333;  % resonant scanner conversion factor from optical degrees to volts

resonantScannerSettleTime = 0.5;    % [seconds] time to wait for the resonant scanner to reach its desired frequency after an update of the zoomFactor

%% Motors
%Motor used for X/Y/Z motion, including stacks. 

motors(1).controllerType = '';           % If supplied, one of {'sutter.mp285', 'sutter.mpc200', 'thorlabs.mcm3000', 'thorlabs.mcm5000', 'scientifica', 'pi.e665', 'pi.e816', 'npoint.lc40x'}.
motors(1).dimensions = '';               % Assignment of stage dimensions to SI dimensions. Can be any combination of X,Y,Z, and R.
motors(1).comPort = [];                  % Integer identifying COM port for controller, if using serial communication
motors(1).customArgs = {};               % Additional arguments to stage controller. Some controller require a valid stageType be specified
motors(1).invertDim = '';                % string with one character for each dimension specifying if the dimension should be inverted. '+' for normal, '-' for inverted
motors(1).positionDeviceUnits = [];      % 1xN array specifying, in meters, raw units in which motor controller reports position. If unspecified, default positionDeviceUnits for stage/controller type presumed.
motors(1).velocitySlow = [];             % Velocity to use for moves smaller than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motors(1).velocityFast = [];             % Velocity to use for moves larger than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motors(1).moveCompleteDelay = [];        % Delay from when stage controller reports move is complete until move is actually considered complete. Allows settling time for motor
motors(1).moveTimeout = [];              % Default: 2s. Fixed time to wait for motor to complete movement before throwing a timeout error
motors(1).moveTimeoutFactor = [];        % (s/um) Time to add to timeout duration based on distance of motor move command

%% Photostim
photostimScannerName = '';          % Name of scanner (from first MDF section) to use for photostimulation. Must be a linear scanner

%Monitoring DAQ AI channels
BeamAiId      = 7;                  % AI channel to be used for monitoring the Pockels cell output

loggingStartTrigger = '';           % one of {'','PFI#'} to which start trigger for logging is wired to photostim board. Leave empty for automatic routing via PXI bus

%% IntegrationRoiOutputs
channelNames = {};                      % User defined name for each output channels e.g. {'My first channel','My second channel','My third channel'}
deviceNames = {};                       % Names of DAQ device for each channel, use 'none' if no physical device is used e.g. {'Dev1','Dev1','none'}
deviceChannels = {};                    % Channel index for each channel: numeric values for analog outputs, strings for digital outputs, use 'none' for software output; e.g {0, 'port0/line0', 'none'} for AO0, port0/line0 and a software output


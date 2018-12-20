function sl_customization(cm)
% SL_CUSTOMIZATION for TI Stellaris LaunchPad PIL connectivity config

cm.registerTargetInfo(@loc_createSerialConfig);
%External mode
%cm.ExtModeTransports.add('stellaris.tlc', 'Stellaris serial', 'ext_stellaris_serial', 'Level1');
cm.ExtModeTransports.add('stellaris.tlc', 'Stellaris serial', 'ext_serial_win32_comm', 'Level1');
cm.ExtModeTransports.add('stellaris.tlc', 'Stellaris CCP', 'stellarisExternalModeOpen', 'Level2');

% local function
function config = loc_createSerialConfig

config = rtw.connectivity.ConfigRegistry;
config.ConfigName = 'TI Stellaris LaunchPad connectivity using UART';
config.ConfigClass = 'stellaris.ConnectivityConfig';

% matching launchpad target file
config.SystemTargetFile = {'stellaris.tlc'};

% match launchpad template makefile
config.TemplateMakefile = {'stellaris_tmf'};

% match launchpad hardware configuration
config.TargetHWDeviceType = {'Texas Instruments->TMS470'};
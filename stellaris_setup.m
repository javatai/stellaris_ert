function stellaris_setup()

cd('stellaris');
curpath = pwd;
tgtpath = curpath(1:end-length('/stellaris'));
addpath(fullfile(tgtpath, 'stellaris'));
addpath(fullfile(tgtpath, 'demos'));
addpath(fullfile(tgtpath, 'blocks'));
addpath(fullfile(tgtpath, 'help'));
savepath;
if ispref('stellaris')
	rmpref('stellaris');
end
addpref('stellaris','TargetRoot',fix_slash(curpath));
addpref('stellaris','COMPort',setup_com_port);
[CCSRoot, CompilerRoot, StellarisWareRoot] = ccs_setup_paths;
addpref('stellaris','CCSRoot',CCSRoot);
addpref('stellaris','CompilerRoot',CompilerRoot);
addpref('stellaris','StellarisWareRoot',StellarisWareRoot);

% Generate blocks
cd('../blocks');
lct_genblocks;
cd(curpath);
% Generate help
cd('../help/source');
genhelp;
cd(curpath);
% External mode support
% % Compilation broken since 16a. Not fixing now, as External mode support is on hiatus anyway.
% if verLessThan('matlab', '8.2')
%     ext_loc = ['"',fullfile(matlabroot,'rtw/ext_mode/')];
% else
%     %R2013b files moved
%     ext_loc = ['"',fullfile(matlabroot,'toolbox/coder/simulinkcoder_core/ext_mode/host/')];
% end
% rtwc_loc = ['"',fullfile(matlabroot,'rtw/c/src/')];
% if isunix
%     mexcmd = [ext_loc,'common/ext_comm.c '...
%         ext_loc,'common/ext_convert.c '...
%         ext_loc,'serial/ext_serial_transport.c '...
%         ext_loc,'serial/ext_serial_pkt.c '...
%         ext_loc,'serial/rtiostream_serial_interface.c '...
%         ext_loc,'common/ext_util.c '...
%         '-Irtw/c/src -Irtw/c/src/rtiostream/utils '...
%         '-Irtw/c/src/ext_mode/common '...
%         '-Irtw/c/src/ext_mode/serial '...
%         '-I',ext_loc,'common '...
%         '-I',ext_loc,'common/include '...
%         '-lmwrtiostreamutils -lmwsl_services '...
%         '-DEXTMODE_SERIAL_TRANSPORT -DSL_EXT_SO '...
%         '-output ',fullfile(curpath,'../blocks'),'/ext_stellaris_serial'];
% else
%         ext_loc(ext_loc=='/')='\';
%         mexcmd = [ext_loc,'common\ext_comm.c" '...
%         ext_loc,'common\ext_convert.c" '...
%         ext_loc,'serial\ext_serial_transport.c" '...
%         ext_loc,'serial\ext_serial_pkt.c" '...
%         ext_loc,'serial\rtiostream_serial_interface.c" '...
%         ext_loc,'common\ext_util.c" '...
%         '-I',rtwc_loc,'" -I',rtwc_loc,'rtiostream\utils" '...
%         '-I',rtwc_loc,'ext_mode\common" '...
%         '-I',rtwc_loc,'ext_mode\serial" '...
%         '-I',ext_loc,'common" '...
%         '-I',ext_loc,'common\include" '...
%         '-lmwrtiostreamutils -lsl_services '...
%         '-DEXTMODE_SERIAL_TRANSPORT -DSL_EXT_DLL '...
%         '-output ',fullfile(curpath,'..\blocks'),'\ext_stellaris_serial'];
% end
% eval(['mex ',mexcmd]);
cd(fullfile(curpath,'..'));

sl_refresh_customizations;
disp('<strong>TI Stellaris LaunchPad</strong> Target setup is complete!');
disp('Explore <a href="matlab:cd([getpref(''stellaris'',''TargetRoot''),''/../demos''])">demos</a> directory and access <a href="matlab:doc -classic">documentation</a>');
end

function [CCSRoot, CompilerRoot, StellarisWareRoot] = ccs_setup_paths()
	% TODO: make it foolproof
    CCSRoot = fix_slash(uigetdir(matlabroot,'CCS root directory: (the one with ccs_base, tools ...)'));
    CompilerRoot = fix_slash(uigetdir(CCSRoot,'CCS Compiler root directory: (tools/compiler/arm_5.X.X)'));
    StellarisWareRoot = fix_slash(uigetdir(CCSRoot,'StellarisWare root directory: (the one with boards, driverlib ...)'));
end

function COMPort = setup_com_port()

[ports, names] = find_com_ports;

% Choose COM port
[selection,ok] = listdlg('PromptString','Choose TI Stellaris LaunchPad COM port:',...
    'SelectionMode','single',...
    'ListSize',[260 160],...
    'ListString',names);
if (ok == 1 && selection > 2) %have actually chosen COM port
    COMPort = char(ports{selection-2}); % -2 for padding with names array
elseif (ok == 1 && selection > 1) %chosen to refresh COM Ports
    COMPort = setup_com_port();
else %chosen to enter manually or canceled
    COMPort = cell2mat(inputdlg('Enter COM port manually: (ex. COM3 or ttyACM0)','COM port',1));
end
end

function [ports, names] = find_com_ports()
%Find COM ports
names_string = {'Enter COM port manually...','Refresh COM ports list...'};
if isunix
    %TODO
	%check /dev/serial
	unixCmd = 'ls -l /dev/serial/by-id/*';
	[unixCmdStatus,unixCmdOutput]=system(unixCmd);
	if (unixCmdStatus > 0)
		ports = {};
		names = {};
	else
		%names = regexp(unixCmdOutput,'(?<=/dev/serial/by-id/)\S+','match');
		%ports = regexp(unixCmdOutput,'(?<=->.*/)tty\w+','match');
		[names, ports] = regexp(unixCmdOutput,'(?<=/dev/serial/by-id/)\S.*?((?<=->.*/)tty\w+)','match','tokens');
	end
else
    wmiCmd = ['wmic /namespace:\\root\cimv2 '...
              'path Win32_SerialPort get DeviceID,Name'];
    %TODO catch error (wmic is not on WinXP Home for instance).
    [~,wmiCmdOutput]=system(wmiCmd);
    % in a single regexp call with tokens
    [names, ports] = regexp(wmiCmdOutput,'(?<=COM\d+\s*)\S.*?\((COM\d+)\)','match','tokens');
    % same in two regexp calls..
    %ports = regexp(wmiCmdOutput,'COM\d+(?!\))','match');
    %names = regexp(wmiCmdOutput,'(?<=COM\d+\s*)\S.*?\(COM\d+\)','match');
    %regCmd=['reg query '...
    %        'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM'];
    %[~,regCmdOutput]=system(regCmd);
    %ports = regexp(regCmdOutput,'COM\d+','match');
end
names = [names_string,names];
end

function path = fix_slash(path0)
path = path0;
if ispc
    path(path=='\')='/';
end
end

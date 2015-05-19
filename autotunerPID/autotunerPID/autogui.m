function [sys,x0,str,ts] = autogui(t,x,u,flag,RefBlock)
%AUTOGUI S-function for making a simple PID GUI.
%
%   When the model autotunerPID.mdl is run, this S-function create a panel
%   which closer resemble the layout of a typical real industrial autotuner
%   (at least in the control options). 
%   The upper part of the GUI is used to interact with the control system,
%   by changing the set-point value and by reading the value of the process
%   value and the control variable.  Moreover when used in MANUAL mode the
%   control variable is under the direct control of the user.  The
%   parameters area shows the parameter of the PID which can be changed 
%   online (except for the derivative weight c which is fixed to 0.
%   The last two areas allow to select the operating mode (AUTO/MANUAL) and
%   the autotuning method, split in the selection of the identification
%   method, the selection of the tuning method and the selection of the
%   regulator structure.
%
%   Everything started looking at PENDAN, an S-function for making pendulum
%   animation
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

% Plots every major integration step, but has no states of its own
switch flag,
   
   % Initialization 
   case 0,
      [sys,x0,str,ts] = mdlInitializeSizes(RefBlock);
      % Update 
   case 2,
      sys = mdlUpdate(t,x,u);
      % Unused flags
   case { 1, 3, 4, 9 },
      sys = [];
      % DeleteBlock
   case 'DeleteBlock',
      LocalDeleteBlock
      % DeleteFigure
   case 'DeleteFigure',
      LocalDeleteFigure
      % SliderSP
   case 'SliderSP',
      LocalSliderSP
      % EditSP
   case 'EditSP',
      LocalEditSP
      % SliderCV
   case 'SliderCV',
      LocalSliderCV
      % EditCV
   case 'EditCV',
      LocalEditCV
      % Close
   case 'Close',
      LocalClose
      % Autotune
   case 'Autotune',
      LocalAutotune
      % Manual
   case 'Man',
      LocalMan
      % Auto
   case 'Auto',
      LocalAuto
      % EditK
   case 'EditK',
      LocalEditK
      % EditTi
   case 'EditTi',
      LocalEditTi
      % EditTd
   case 'EditTd',
      LocalEditTd
      % EditN
   case 'EditN',
      LocalEditN
      % Editb
   case 'Editb',
      LocalEditb
      % IdentMethod
   case 'Identification',
      LocalIdentification
      % TuningMethpd
   case 'Tuning',
      LocalTuning
      % Structure
   case 'Structure',
      LocalStructure
      % EditParam
   case 'EditParam',
      LocalEditParam
      % Unexpected flags
   otherwise
      error(['Unhandled flag = ',num2str(flag)]);
end
% end autogui

%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================
function [sys,x0,str,ts] = mdlInitializeSizes(RefBlock)
% initialize parameters (setpoint)
set_param(get_param([get_param(gcs,'Parent') '/' RefBlock],'Handle'),...
   'Value','0');

% set up S-function
sizes = simsizes;

sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 0;
sizes.NumInputs      = 2;
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);

x0  = [];
str = [];
ts  = [0.1 0];

LocalPIDInit(RefBlock);
% end mdlInitializeSizes


%=============================================================================
% mdlUpdate
% Update the PID GUI animation.
%=============================================================================
function sys = mdlUpdate(t,x,u)
fig = get_param(gcbh,'UserData');
if ishandle(fig),
   if strcmp(get(fig,'Visible'),'on'),
      ud = get(fig,'UserData');
      LocalPIDSets(t,ud,u);
   end
end
sys = [];
% end mdlUpdate


%=============================================================================
% LocalDeleteBlock
% The animation block is being deleted, delete the associated figure.
%=============================================================================
function LocalDeleteBlock
fig = get_param(gcbh,'UserData');
if ishandle(fig),
   delete(fig);
   set_param(gcbh,'UserData',-1)
end
% end LocalDeleteBlock


%=============================================================================
% LocalDeleteFigure
% The animation figure is being deleted, set the S-function UserData to -1.
%=============================================================================
function LocalDeleteFigure
ud = get(gcbf,'UserData');
set_param(ud.Block,'UserData',-1);
% end LocalDeleteFigure


%=============================================================================
% LocalSliderSP
% The callback function for the animation window slider SP control
%=============================================================================
function LocalSliderSP
ud = get(gcbf,'UserData');
set_param(ud.RefBlock,'Value',num2str(get(gcbo,'Value')));
% end LocalSliderSP


%=============================================================================
% LocalSliderCV
% The callback function for the animation window slider CV control
%=============================================================================
function LocalSliderCV
global CVVALUE
ud = get(gcbf,'UserData');
CVVALUE = get(gcbo,'Value');
set(ud.EditCV,'String',num2str(CVVALUE));
% end LocalSliderCV


%=============================================================================
% LocalEditCV
% The callback function for the edit field of parameter CV
%=============================================================================
function LocalEditCV
global CVVALUE
ud = get(gcbf,'UserData');
CVVALUE = str2num(get(ud.EditCV,'String'));
set(ud.SlideCV,'Value',CVVALUE);
% end LocalEditCV


%=============================================================================
% LocalClose
% The callback function for the animation window close button.  Delete
% the animation figure window.
%=============================================================================
function LocalClose
delete(gcbf)
% end LocalClose


%=============================================================================
% LocalAutotune
% The callback function for the autotune button. Start autotuning
%=============================================================================
function LocalAutotune
global AUTOTUNE
global INACTIVE
AUTOTUNE = 1;
INACTIVE = 1;
ud = get(gcbf,'UserData');
set(ud.SlideSP,'Enable','inactive');
set(ud.EditSP,'Enable','off');
set(ud.SlideCV,'Enable','inactive');
set(ud.EditCV,'Enable','off');
set(ud.Man,'Enable','off');
set(ud.Auto,'Enable','off');
set(ud.EditK,'Enable','inactive');
set(ud.EditTi,'Enable','inactive');
set(ud.EditTd,'Enable','inactive');
set(ud.Editb,'Enable','inactive');
set(ud.EditN,'Enable','inactive');
set(ud.Ident,'Enable','off');
set(ud.Tuning,'Enable','off');
set(ud.TuningParam,'Enable','off');
set(ud.Structure,'Enable','off');
% end LocalAutotune


%=============================================================================
% LocalMan
% The callback function for the manual selector button
%=============================================================================
function LocalMan
global AUTOMAN
ud = get(gcbf,'UserData');
set(ud.Auto,'Value',0);
set(ud.Man,'Value',1);
set(ud.EditCV,'Enable','on');
set(ud.SlideCV,'Enable','on');
AUTOMAN = 0;
% end LocalMan


%=============================================================================
% LocalAuto
% The callback function for the automatic selector button
%=============================================================================
function LocalAuto
global AUTOMAN
ud = get(gcbf,'UserData');
set(ud.Man,'Value',0);
set(ud.Auto,'Value',1);
set(ud.EditCV,'Enable','off');
set(ud.SlideCV,'Enable','inactive');
AUTOMAN = 1;
% end LocalAuto


%=============================================================================
% LocalEditK
% The callback function for the edit field of parameter K
%=============================================================================
function LocalEditK
global PIDPARAMETERS
ud = get(gcbf,'UserData');
PIDPARAMETERS = [str2num(get(ud.EditK,'String')) PIDPARAMETERS(2:5)];
% end LocalEditK


%=============================================================================
% LocalEditTi
% The callback function for the edit field of parameter Ti
%=============================================================================
function LocalEditTi
global PIDPARAMETERS
ud = get(gcbf,'UserData');
PIDPARAMETERS = [PIDPARAMETERS(1)...
      str2num(get(ud.EditTi,'String')) PIDPARAMETERS(3:5)];
% end LocalEditTi


%=============================================================================
% LocalEditTd
% The callback function for the edit field of parameter Td
%=============================================================================
function LocalEditTd
global PIDPARAMETERS
ud = get(gcbf,'UserData');
PIDPARAMETERS = [PIDPARAMETERS(1:2)...
      str2num(get(ud.EditTd,'String')) PIDPARAMETERS(4:5)];
% end LocalEditTd


%=============================================================================
% LocalEditN
% The callback function for the edit field of parameter N
%=============================================================================
function LocalEditN
global PIDPARAMETERS
ud = get(gcbf,'UserData');
PIDPARAMETERS = [PIDPARAMETERS(1:3)...
      str2num(get(ud.EditN,'String')) PIDPARAMETERS(5)];
% end LocalEditN


%=============================================================================
% LocalEditb
% The callback function for the edit field of parameter b
%=============================================================================
function LocalEditb
global PIDPARAMETERS
ud = get(gcbf,'UserData');
PIDPARAMETERS = [PIDPARAMETERS(1:4) str2num(get(ud.Editb,'String'))];
% end LocalEditb


%=============================================================================
% LocalEditSP
% The callback function for the edit field of parameter SP
%=============================================================================
function LocalEditSP
ud = get(gcbf,'UserData');
set_param(ud.RefBlock,'Value',get(ud.EditSP,'String'));
% end LocalEditSP


%=============================================================================
% LocalIdentification
% The callback function for the selection of the identification method
%=============================================================================
function LocalIdentification
global TUNING_PARAM
global IDENTIFICATION_METHOD
global TUNING_METHOD
ud = get(gcbf,'UserData');
str = get(ud.Ident,'String');
IDENTIFICATION_METHOD = deblank(upper(str(get(ud.Ident,'Value'),:)));
if strcmp(IDENTIFICATION_METHOD,'STEP')
   TUNING_PARAM = [];
   TUNING_METHOD = 'ZN (OL)';
   set(ud.TunParText,'String','');
   set(ud.TuningParam,'Style','edit');
   set(ud.TuningParam,'Visible','off');
   set(ud.Tuning,'Value',3);
elseif strcmp(IDENTIFICATION_METHOD,'RELAY')
   TUNING_PARAM = [];
   TUNING_METHOD = 'ZN (CL)';
   set(ud.TunParText,'String','');
   set(ud.TuningParam,'Style','edit');
   set(ud.TuningParam,'Visible','off');
   set(ud.Tuning,'Value',4);
end
% end LocalIdentification


%=============================================================================
% LocalTuning
% The callback function for the selection of the tuning method
%=============================================================================
function LocalTuning
global TUNING_PARAM
global TUNING_METHOD
global IDENTIFICATION_METHOD
ud = get(gcbf,'UserData');
str = get(ud.Tuning,'String');
TUNING_METHOD = deblank(upper(str(get(ud.Tuning,'Value'),:)));
if strcmp(TUNING_METHOD,'ZN (OL)')
   set(ud.TunParText,'String','');
   set(ud.TuningParam,'Style','edit');
   set(ud.TuningParam,'Visible','off');
   set(ud.TuningParam,'String','');
   TUNING_PARAM = [];
   IDENTIFICATION_METHOD = 'STEP';
   set(ud.Ident,'Value',1);
elseif strcmp(TUNING_METHOD,'ZN (CL)')
   set(ud.TunParText,'String','');
   set(ud.TuningParam,'Style','edit',...
      'Visible','off',...
      'String','');
   TUNING_PARAM = [];
   IDENTIFICATION_METHOD = 'RELAY';
   set(ud.Ident,'Value',2);
elseif strcmp(TUNING_METHOD,'KT')
   set(ud.TunParText,'String','Ms ');
   set(ud.TuningParam,'Style','popupmenu',...
      'String',['1.4';'2.0'],...
      'Value',1,...
      'Visible','on');
   TUNING_PARAM = 1.4;
   IDENTIFICATION_METHOD = 'STEP';
   set(ud.Ident,'Value',1);
elseif strcmp(TUNING_METHOD,'IMC')
   set(ud.TunParText,'String','lambda ');
   set(ud.TuningParam,'Style','edit',...
      'String','1',...
      'Visible','on');
   TUNING_PARAM = 1;
   IDENTIFICATION_METHOD = 'STEP';
   set(ud.Ident,'Value',1);
end
% end LocalTuning


%=============================================================================
% LocalEditParam
% The callback function for the edit field of the method of the parameter
%=============================================================================
function LocalEditParam
global TUNING_PARAM
global TUNING_METHOD
ud = get(gcbf,'UserData');
if strcmp(TUNING_METHOD,'KT')
   if get(ud.TuningParam,'Value')==1;
      TUNING_PARAM = 1.4;
   elseif get(ud.TuningParam,'Value')==2;
      TUNING_PARAM = 2.0;
   end
elseif strcmp(TUNING_METHOD,'IMC')
   TUNING_PARAM = str2num(get(ud.TuningParam,'String'));
end
% end LocalEditParam


%=============================================================================
% LocalStructure
% The callback function for the selection of the regulator structure
%=============================================================================
function LocalStructure
global TUNING_STRUCTURE
ud = get(gcbf,'UserData');
str = get(ud.Structure,'String');
TUNING_STRUCTURE = deblank(upper(str(get(ud.Structure,'Value'),:)));
% end LocalStructure


%=============================================================================
% LocalPIDSets
% Local function to set the position of the graphics objects in the PID GUI
% animation window.
%=============================================================================
function LocalPIDSets(time,ud,u)
global AUTOMAN
global AUTOTUNE
global PIDPARAMETERS
global INACTIVE

PVValue = u(1);
SPValue = str2num(get_param(ud.RefBlock,'Value'));
CVValue = u(2);

% time field
set(ud.TimeField,...
   'String',num2str(time));
% process value & setpoint
set(ud.PV,...
   'YData',[0 PVValue PVValue 0]);
set(ud.PVField,...
   'String',num2str(PVValue,'%1.4f'));
set(ud.RefMark,...
   'YData',[SPValue+0.25 SPValue SPValue-0.25]);
set(ud.SlideSP,...
   'Value',SPValue);
set(ud.EditSP,...
   'String',num2str(SPValue,'%1.4f'));
% process value & setpoint
set(ud.CV,...
   'YData',[0 CVValue CVValue 0]);
if ~AUTOTUNE
   set(ud.SlideCV,...
      'Value',CVValue);
   set(ud.EditCV,...
      'String',num2str(CVValue,'%1.4f')); 
end
if ~AUTOTUNE & INACTIVE
   % Autotuning process completed (update parameters and set the GUI
   % active)
   % PID parameters
   set(ud.SlideSP,'Enable','on');
   set(ud.EditSP,'Enable','on');
   if ~AUTOMAN
      set(ud.SlideCV,'Enable','on');
      set(ud.EditCV,'Enable','on');
   end
   set(ud.Man,'Enable','on');
   set(ud.Auto,'Enable','on');
   set(ud.EditK,'Enable','on');
   set(ud.EditTi,'Enable','on');
   set(ud.EditTd,'Enable','on');
   set(ud.Editb,'Enable','on');
   set(ud.EditN,'Enable','on');
   set(ud.Ident,'Enable','on');
   set(ud.Tuning,'Enable','on');
   set(ud.TuningParam,'Enable','on');
   set(ud.Structure,'Enable','on');
   set(ud.EditK,...
      'String',num2str(PIDPARAMETERS(1)));
   set(ud.EditTi,...
      'String',num2str(PIDPARAMETERS(2)));
   set(ud.EditTd,...
      'String',num2str(PIDPARAMETERS(3)));
   set(ud.EditN,...
      'String',num2str(PIDPARAMETERS(4)));
   set(ud.Editb,...
      'String',num2str(PIDPARAMETERS(5)));
   INACTIVE = 0;
end

% Force plot to be drawn
pause(0), drawnow
% end LocalPIDSets


%=============================================================================
% LocalPIDInit
% Local function to initialize the PID GUI animation.  If the animation
% window already exists, it is brought to the front.  Otherwise, a new
% figure window is created.
%=============================================================================
function LocalPIDInit(RefBlock)
% The name of the reference is derived from the name of the
% subsystem block that owns the PID animation S-function block.
% This subsystem is the current system and is assumed to be the same
% layer at which the reference block resides.
sys = get_param(gcs,'Parent');

global AUTOTUNE
global AUTOMAN
global PIDPARAMETERS
global IDENTIFICATION_METHOD
global TUNING_METHOD
global TUNING_PARAM
global TUNING_STRUCTURE
global INACTIVE

INACTIVE = 1;

IDENTIFICATION_METHOD = 'STEP';
TUNING_METHOD = 'KT';
TUNING_PARAM = 1.4;
TUNING_STRUCTURE  ='PID';

AUTOTUNE = 0;
AUTOMAN  = 1;

TimeClock = 0;
PVValue = 0;
SPValue = str2num(get_param([sys '/' RefBlock],'Value'));
CVValue = 0;

% The animation figure handle is stored in the PID block's UserData.
% If it exists, initialize all the fields
Fig = get_param(gcbh,'UserData');
if ishandle(Fig),
   FigUD = get(Fig,'UserData');
   
   % time field
   set(FigUD.TimeField,...
      'String',num2str(TimeClock));
   % process value & set point
   set(FigUD.PV,...
      'YData',[0 PVValue PVValue 0]);
   set(FigUD.PVField,...
      'String',num2str(PVValue));
   set(FigUD.RefMark,...
      'YData',[SPValue+0.25 SPValue SPValue-0.25]);
   set(FigUD.SlideSP,...
      'Value',0);
   set(FigUD.EditSP,...
      'String',num2str(PVValue));
   % control variable
   set(FigUD.CV,...
      'YData',[0 CVValue CVValue 0]);
   set(FigUD.EditCV,...
      'String',num2str(CVValue),...
      'Enable','off');
   set(FigUD.SlideCV,...
      'Value',CVValue,...
      'Enable','inactive');
   % auto/man selector
   set(FigUD.Man,...
      'Value',0);
   set(FigUD.Auto,...
      'Value',1);
   % PID parameters
   set(FigUD.EditK,...
      'String',num2str(PIDPARAMETERS(1)),...
      'Enable','on');
   set(FigUD.EditTi,...
      'String',num2str(PIDPARAMETERS(2)),...
      'Enable','on');
   set(FigUD.EditTd,...
      'String',num2str(PIDPARAMETERS(3)),...
      'Enable','on');
   set(FigUD.EditN,...
      'String',num2str(PIDPARAMETERS(4)),...
      'Enable','on');
   set(FigUD.Editb,...
      'String',num2str(PIDPARAMETERS(5)),...
      'Enable','on');
   % autotuning
   set(FigUD.Ident,...
      'Value',1,...
      'Enable','on');
   set(FigUD.Tuning,...
      'Value',2,...
      'Enable','on');
   set(FigUD.Structure,...
      'Value',1,...
      'Enable','on');
   set(FigUD.TunParText,...
      'String','Ms ');
   set(FigUD.TuningParam,...
      'Style','popupmenu',...
      'String',['1.4';'2.0'],...
      'Value',1,...
      'Enable','on',...
      'Visible','on');
   
   % bring it to the front
   figure(Fig);
   return
end

% the animation figure doesn't exist, create a new one and store its
% handle in the animation block's UserData
FigureName = 'PID Control Panel';

% Figure
FigH = 610;                % figure height
FigW = 272;                % figure width
Fig = figure(...
   'Units',              'pixel',...
   'Position',           [740 740-FigH FigW FigH],...
   'Name',               FigureName,...
   'NumberTitle',        'off',...
   'IntegerHandle',      'off',...
   'HandleVisibility',   'callback',...
   'MenuBar',            'none',...
   'Resize',				 'off',...
   'DoubleBuffer',       'on',...
   'DeleteFcn',          'autogui([],[],[],''DeleteFigure'')',...
   'CloseRequestFcn',    'autogui([],[],[],''Close'');');

% Setpoint slider
SlideControlSP = uicontrol(...
   'Parent',             Fig,...
   'Style',              'slider',...
   'Units',              'pixel', ...
   'Position',           [25 FigH-325 22 300],...
   'Min',                -9,...
   'Max',                9,...
   'Value',              0,...
   'BackgroundColor',    [1 1 0],...
   'Callback',           'autogui([],[],[],''SliderSP'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [25 FigH-20 22 12], ...
   'HorizontalAlignment','center',...
   'String',             'SP',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [1 1 0],...
   'Fontweight',         'bold');

% Process value
AxesPV = axes(...
   'Parent',             Fig,...
   'Units',              'pixel',...
   'Position',           [75 FigH-325 22 300],...
   'CLim',               [1 64], ...
   'Xlim',               [-1 1],...
   'Ylim',               [-10 10],...
   'Visible',            'on',...
   'XTick',              [],...
   'XTickLabel',         [],...
   'FontSize',           8,...
   'Box',                'on');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [75 FigH-20 22 12], ...
   'HorizontalAlignment','center',...
   'String',             'PV',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [1 0 1],...
   'Fontweight',         'bold');
PV = patch(...
   'Parent',             AxesPV,...
   'XData',              [-1 -1 1 1],...
   'YData',              [0 PVValue PVValue 0],...
   'FaceColor',          [1 0 1]);
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [106 FigH-175 50 14], ...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [1 0 1],...
   'HorizontalAlignment','center',...
   'Fontweight',         'bold',...
   'String',             'PV');
PVField = uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [106 FigH-191 50 14], ...
   'Backgroundcolor',    [1 1 1],...
   'Foregroundcolor',    [0 0 0],...
   'HorizontalAlignment','center',...
   'String',             num2str(PVValue));
RefMark = patch(...
   'Parent',             AxesPV,...
   'XData',              [-1 -0 -1],...
   'YData',              [SPValue+0.25 SPValue SPValue-0.25],...
   'FaceColor',          [1 1 0]);
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [106 FigH-100 50 14], ...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [1 1 0],...
   'HorizontalAlignment','center',...
   'Fontweight',         'bold',...
   'String',             'SP');
EditSP = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [106 FigH-118 50 18], ...
   'HorizontalAlignment','center',...
   'String',             num2str(SPValue),...
   'Foregroundcolor',    [0 0 0],...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditSP'');');

% Control variable
AxesCV = axes(...
   'Parent',             Fig,...
   'Units',              'pixel',...
   'Position',           [175 FigH-325 22 300],...
   'CLim',               [1 64], ...
   'Xlim',               [-1 1],...
   'Ylim',               [-10 10],...
   'Visible',            'on',...
   'XTick',              [],...
   'XTickLabel',         [],...
   'FontSize',           8,...
   'Box',                'on');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [175 FigH-20 22 12], ...
   'HorizontalAlignment','center',...
   'String',             'CV',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [0 1 1],...
   'Fontweight',         'bold');
CV = patch(...
   'Parent',             AxesCV,...
   'XData',              [-1 -1 1 1],...
   'YData',              [0 CVValue CVValue 0],...
   'FaceColor',          [0 1 1]);

% Control variable - Manual
SlideControlCV = uicontrol(...
   'Parent',             Fig,...
   'Style',              'slider',...
   'Units',              'pixel', ...
   'Position',           [225 FigH-325 22 300],...
   'Min',                -9,...
   'Max',                9,...
   'Value',              0,...
   'BackgroundColor',    [0 1 1],...
   'Callback',           'autogui([],[],[],''SliderCV'');',...
   'Enable',             'inactive');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [200 FigH-20 72 12], ...
   'HorizontalAlignment','center',...
   'String',             'CV - MAN',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [0 1 1],...
   'Fontweight',         'bold');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [106 FigH-250 50 14], ...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Foregroundcolor',    [0 1 1],...
   'HorizontalAlignment','center',...
   'Fontweight',         'bold',...
   'String',             'CV');
EditCV = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [106 FigH-268 50 18], ...
   'HorizontalAlignment','center',...
   'String',             num2str(CVValue),...
   'Foregroundcolor',    [0 0 0],...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditCV'');',...
   'Enable',             'inactive');

% time field
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [100 FigH-348 36 12], ...
   'HorizontalAlignment','right',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'Fontweight',         'bold',...
   'String',             'Time: ');
TimeField = uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel', ...
   'Position',           [136 FigH-348 36 12],...
   'HorizontalAlignment','left',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'String',             num2str(TimeClock));

% PID parameters
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [12 FigH-371 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'String',             'Parameters');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'frame',...
   'Units',              'pixel',...
   'Position',           [12 FigH-417 248 46]);
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [16 FigH-393 20 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'K ');
EditK = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [36 FigH-393 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditK'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [96 FigH-393 20 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'Ti ');
EditTi = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [116 FigH-393 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditTi'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [176 FigH-393 20 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'Td ');
EditTd = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [196 FigH-393 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditTd'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [16 FigH-413 20 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'N ');
EditN = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [36 FigH-413 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditN'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [96 FigH-413 20 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'b ');
Editb = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [116 FigH-413 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''Editb'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [176 FigH-413 20 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'c ');
Editc = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [196 FigH-413 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '0',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''Editc'');',...
   'Enable',             'off');

% auto/man selector
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [12 FigH-441 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'String',             'Operating Mode');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'frame',...
   'Units',              'pixel',...
   'Position',           [12 FigH-467 248 24]);
Man = uicontrol(...
   'Parent',             Fig,...
   'Style',              'radiobutton',...
   'Position',           [16 FigH-465 70 20],...
   'String',             'Manual', ...
   'Fontweight',         'bold',...
   'Value',              0,...
   'Callback',           'autogui([],[],[],''Man'');');
Auto = uicontrol(...
   'Parent',             Fig,...
   'Style',              'radiobutton',...
   'Position',           [136 FigH-465 50 20],...
   'String',             'Auto', ...
   'Fontweight',         'bold',...
   'Value',              1,...
   'Callback',           'autogui([],[],[],''Auto'');');

% autotuning
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [12 FigH-491 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'String',             'Autotuner');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'frame',...
   'Units',              'pixel',...
   'Position',           [12 FigH-604 248 112]);
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [16 FigH-516 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'String',             'Identification method');
IdentMethod = uicontrol(...
   'Parent',             Fig,...
   'Style',              'popupmenu',...
   'Position',           [156 FigH-516 100 18],...
   'String',             ['step ';'relay'],...
   'Backgroundcolor',    [1 1 1],...
   'Fontweight',         'bold',...
   'Value',              1,...
   'Callback',           'autogui([],[],[],''Identification'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [16 FigH-536 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'String',             'Tuning method');
TuningMethod = uicontrol(...
   'Parent',             Fig,...
   'Style',              'popupmenu',...
   'Position',           [156 FigH-536 100 18],...
   'String',             ['IMC    ';'KT     ';'ZN (OL)';'ZN (CL)'], ...
   'Backgroundcolor',    [1 1 1],...
   'Fontweight',         'bold',...
   'Value',              2,...
   'Callback',           'autogui([],[],[],''Tuning'');');
TuningParText = uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [16 FigH-556 180 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'Ms ');
TuningParam = uicontrol(...
   'Parent',             Fig,...
   'Style',              'popupmenu',...
   'Units',              'pixel',...
   'Position',           [196 FigH-556 60 18], ...
   'HorizontalAlignment','center',...
   'String',             ['1.4';'2.0'],...
   'Value',              1,...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'autogui([],[],[],''EditParam'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [16 FigH-576 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'String',             'Structure');
RegStruct = uicontrol(...
   'Parent',             Fig,...
   'Style',              'popupmenu',...
   'Position',           [156 FigH-576 100 18],...
   'String',             ['PID ';'PI  ';'auto'], ...
   'Backgroundcolor',    [1 1 1],...
   'Fontweight',         'bold',...
   'Value',              1,...
   'Callback',           'autogui([],[],[],''Structure'');'); 
uicontrol(...
   'Parent',             Fig,...
   'Style',              'pushbutton',...
   'Position',           [100 FigH-601 72 20],...
   'String',             'Autotune', ...
   'Fontweight',         'bold',...
   'Callback',           'autogui([],[],[],''Autotune'');');


% all the HG objects are created, store them into the Figure's UserData
% time field
FigUD.TimeField    = TimeField;
% process value & setpoint
FigUD.PV           = PV;
FigUD.SlideSP      = SlideControlSP;
FigUD.RefMark      = RefMark;
FigUD.EditSP       = EditSP;
FigUD.PVField      = PVField;
% control variable
FigUD.CV           = CV;
FigUD.SlideCV      = SlideControlCV;
FigUD.EditCV       = EditCV;
% radiobox button
FigUD.Man          = Man;
FigUD.Auto         = Auto;
% edit field (PID parameters)
FigUD.EditK        = EditK;
FigUD.EditTi       = EditTi;
FigUD.EditTd       = EditTd;
FigUD.EditN        = EditN;
FigUD.Editb        = Editb;
% autotuning
FigUD.Ident        = IdentMethod;
FigUD.Tuning       = TuningMethod;
FigUD.TunParText   = TuningParText;
FigUD.TuningParam  = TuningParam;
FigUD.Structure    = RegStruct;
% Simulink Block Interaction
FigUD.Block        = get_param(gcbh,'Handle');
FigUD.RefBlock     = get_param([sys '/' RefBlock],'Handle');

set(Fig,'UserData',FigUD);

drawnow

% store the figure handle in the animation block's UserData
set_param(gcbh,'UserData',Fig);
% end LocalPIDInit
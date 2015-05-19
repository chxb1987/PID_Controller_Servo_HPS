function [K,Ti,Td,N,b] = pid_tuning(model,method,param,regStruct,As)
%PID_TUNING Tune the parameters of a ISA-PID regulator with some
%   well-defined autotuning methods.
%
%   [K,Ti,Td,N,b] = PID_TUNING(MODEL,MEETHOD,PARAM,REGSTRUCT) returns the
%   parameters of a ISA-PID regulator.
%   MODEL is a structure describing the plant, with the following fields:
%      - MODEL.m, MODEL.L, MODEL.T for a model based method (namely the
%        parameters of a FOPDT model M(s) = m*exp(-sL)/(1+s*T))
%      - MODEL.A, MODEL.T for a characteristic based method (amplitude and
%        period of the oscillation generated by a relay in the loop)
%   METHOD is a flag indicating the desired tuning method while PARAM gives
%   additional parameters (if required), according to the following table
%
%    Tuning method          |   METHOD   | PARAM
%   ------------------------------------------------------------------------
%    First Ziegler-Nichols  | 'ZN (OL)'  | none  
%    method (open loop)     |            |
%                           |            |
%    Kappa-Tau method       |    'KT'    | Ms : required magnitude margin
%                           |            |
%    Internal Model Control |   'IMC'    | lambda : time constant of the
%    method                 |            |          filter F(s) 
%                           |            |   
%    Second Ziegler-Nichols | 'ZN (CL)'  | none
%    method (closed loop)   |            |
%   -----------------------------------------------------------------------
%
%   REGSTRUCT is a flag selecting the regulator structure ('PI' or 'PID')
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

if nargin<4
   error('Usage : [K,Ti,Td,N,b] = pid_tuning(model,method,param,regStruct)')
end
if nargin<5
   As = 1;
end

% synthesis of the PID parameters
switch method
   case {'KT','kt'}
      % Kappa-Tau
      % FOPDT model parameters
      m = model.m; L = model.L; T = model.T;
      % tuning method parameter
      Ms = param;             % required magnitude margin
      
      if Ms==1.4
         % conservative tuning
         if strcmp(regStruct,'PI')
            A0 = 0.29;  A1 = -2.7;  A2 = 3.7;
            B0 = 8.9;   B1 = -6.6;  B2 = 3.0;
            C0 = 0;     C1 = 0;     C2 = 0;
            D0 = 0.81;  D1 = 0.73;  D2 = 1.9;
         elseif strcmp(regStruct,'PID')
            A0 = 3.8;   A1 = -8.4;  A2 = 7.3;
            B0 = 5.2;   B1 = -2.5;  B2 = -1.4;
            C0 = 0.89;  C1 = -0.37; C2 = -4.1;
            D0 = 0.4;   D1 = 0.18;  D2 = 2.8;
         end
      elseif Ms==2
         % more aggressive tuning
         if strcmp(regStruct,'PI')
            A0 = 0.78;  A1 = -4.1;  A2 = 5.7;
            B0 = 8.9;   B1 = -6.6;  B2 = 3.0;
            C0 = 0;     C1 = 0;     C2 = 0;
            D0 = 0.48;  D1 = 0.78;  D2 = -0.45;
         elseif strcmp(regStruct,'PID')
            A0 = 8.4;   A1 = -9.6;  A2 = 9.8;
            B0 = 3.2;   B1 = -1.5;  B2 = -0.93;
            C0 = 0.86;  C1 = -1.9;  C2 = -0.44;
            D0 = 0.22;  D1 = 0.65;  D2 = 0.051;
         end
      end
      
      a   = m*L/T;            % normalized gain
      tau = L/(L+T);          % normalized delay
      
      K  = A0/a*exp(A1*tau+A2*tau^2);
      Ti = L*B0*exp(B1*tau+B2*tau^2);
      Td = L*C0*exp(C1*tau+C2*tau^2);
      b  = D0*exp(D1*tau+D2*tau^2);
      N  = 5;
      
   case {'IMC','imc'}
      % Internal Model Control
      % FOPDT model parameters
      m = model.m; L = model.L; T = model.T;
      % tuning method parameter
      lambda = param;         % lambda
      
      Ti = T + L^2/(2*(L+lambda));
      K  = Ti / (m*(L+lambda));
      N  = T*(L+lambda) / (lambda*Ti) - 1;
      Td = lambda*L*N / (2*(L+lambda));
      if Td==0
         N=5;
      end
      % b is tuned according to KT rules for PID
      b  = 0.4*exp(0.18*(L/(L+T))+2.8*(L/(L+T))^2);
      
   case {'ZN (OL)','zn (ol)'}
      % Ziegler & Nichols (open loop)
      % FOPDT model parameters
      m = model.m; L = model.L; T = model.T;
      if L~=0
         if strcmp(regStruct,'PI')
            K = (0.9*T) / (m*L);
            Ti = 3*L;
            Td = 0;
         elseif strcmp(regStruct,'PID')
            K = (1.2*T) / (m*L);
            Ti = 2*L;
            Td = 0.5*L;
         end
      b  = 1;
      N  = 5;
      end
      
   case {'ZN (CL)','zn (cl)'}
      % Ziegler & Nichols (closed loop)
      % point of the frequency response
      A = model.A; T = model.T;
      
      Ku = 4*As/(pi*A);

      if strcmp(regStruct,'PI')
         K  = 0.4*Ku;
         Ti = T/1.2;
         Td = 0;
      elseif strcmp(regStruct,'PID')
         K  = 0.6*Ku;
         Ti = T/2;
         Td = T/8;
      end
      
      b  = 1;
      N  = 5;
      
   otherwise
      error(['Unknown method: ' method]);
end
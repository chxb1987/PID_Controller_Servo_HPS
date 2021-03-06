J = 3.2284E-6;
b = 3.5077E-6;
K = 0.0274;
R = 4;
L = 2.75E-6;
s = tf('s');
P_motor = K/(s*((J*s+b)*(L*s+R)+K^2));

%This block is for proportional controller with gain ranging from 1 to 21.
Kp = 1;
%Initialising C as a 'pid' datatype so as to avoid the error occuring 
%during conversion from pid to double in step 15 (inside loop below)
C = pid(3,3,3); 

for i = 1:3
    C(:,:,i) = pid(Kp);
    Kp = Kp + 10;
end
sys_cl = feedback(C*P_motor,1);

%Step responses
t = 0:0.001:0.2;
step(sys_cl(:,:,1), sys_cl(:,:,2), sys_cl(:,:,3), t)
ylabel('Position, \theta (radians)')
title('Response to a Step Reference with Different Values of K_p')
legend('K_p = 1',  'K_p = 11',  'K_p = 21')

%Looking at system's response to step disturbance
%Assuming a reference of zero and looking at how the system responds to the
%distrubance by itself.
dist_cl = feedback(P_motor,C);
step(dist_cl(:,:,1), dist_cl(:,:,2), dist_cl(:,:,3), t)
ylabel('Position, \theta (radians)')
title('Response to a Step Disturbance with Different Values of K_p')
legend('K_p = 1', 'K_p = 11','K_p = 21')

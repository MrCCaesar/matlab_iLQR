function [dx] = dynamics(x, u)
%DYNAMICS Summary of this function goes here
% The dimension of the state/control space
% global X_DIM %X_DIM = 6 (x,y,phi,dx,dy,r)
% global U_DIM %U_DIM = 2 (velocity,steering)

global PENDULUM;

% % ----------------------------------------
% % --------------Pendulum model-------------
% % ----------------------------------------
if PENDULUM
    g = 9.81;
    l = 1;
    m = 1;

    dx = [x(2), -g/l*sin(x(1)) + 1/(m*l^2)*u];
end


%%% Car model
if ~PENDULUM
    % ----------------------------------------
    % --------------Model Params--------------
    % ----------------------------------------
    m = 2.35;           % mass (kg)
    L = 0.257;          % wheelbase (m)
    C_alpha = 300;      % laternal stiffness
    C_x = 330;          % longitude stiffness
    Iz = 0.02065948883; % roatation inertia
    g = 9.81;     

    b = 0.14328;        % CoG to rear axle
    a = L-b;            % CoG to front axle

    G_front = m*g*b/L;   % calculated load or specify front rear load directly
    G_rear = m*g*a/L;
    mu = 5.2/G_rear;   
    mu_spin = 4.3/G_rear;  

    % ----------------------------------------
    % ------States/Inputs Interpretation------
    % ----------------------------------------
    pos_x = x(1);
    pos_y = x(2);
    pos_phi = x(3);

    Ux = x(4);
    Uy = x(5);
    r = x(6);

    Ux_cmd = u(1);
    delta = u(2);

    % ----------------------------------------
    % --------------Tire Dyanmics-------------
    % ----------------------------------------
    % lateral slip angle alpha
    if Ux == 0 && Uy == 0   % vehicle is still no slip
        alpha_F = 0;
        alpha_R = 0;
    elseif Ux == 0      % perfect side slip
        alpha_F = pi/2*sign(Uy)-delta;
        alpha_R = pi/2*sign(Uy);
    elseif Ux < 0    % rare ken block situations
        alpha_F = (sign(Uy)*pi)-atan((Uy+a*r)/abs(Ux))-delta;
        alpha_R = (sign(Uy)*pi)-atan((Uy-b*r)/abs(Ux));
    else                % normal situation
        alpha_F = atan((Uy+a*r)/abs(Ux))-delta;
        alpha_R = atan((Uy-b*r)/abs(Ux));
    end

    % safety that keep alpha in valid range
    alpha_F = wrapToPi(alpha_F);
    alpha_R = wrapToPi(alpha_R);

    [Fxf,Fyf] = tire_dyn(Ux, Ux, mu, mu_spin, G_front, C_x, C_alpha, alpha_F);
    [Fxr,Fyr] = tire_dyn(Ux, Ux_cmd, mu, mu_spin, G_rear, C_x, C_alpha, alpha_R);

    % ----------------------------------------
    % ------------Vehicle Dyanmics------------
    % ----------------------------------------
    % ddx
    r_dot = (a*Fyf*cos(delta)-b*Fyr)/Iz;
    Ux_dot = (Fxr-Fyf*sin(delta))/m+r*Uy;
    Uy_dot = (Fyf*cos(delta)+Fyr)/m-r*Ux;

    % translate dx to terrain frame
    U = sqrt(Ux^2+Uy^2);
    if Ux == 0 && Uy == 0
        beta = 0;
    elseif Ux == 0
        beta = pi/2*sign(Uy);
    elseif Ux < 0 && Uy == 0
        beta = pi;
    elseif Ux < 0
        beta = sign(Uy)*pi-atan(Uy/abs(Ux));
    else
        beta = atan(Uy/abs(Ux));
    end
    beta = wrapToPi(beta);

    Ux_terrain = U*cos(beta+pos_phi);
    Uy_terrain = U*sin(beta+pos_phi);
    dx = [Ux_terrain,Uy_terrain,r,Ux_dot,Uy_dot,r_dot];
end % end car model
    
end % end function
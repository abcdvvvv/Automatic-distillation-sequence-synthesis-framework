function cost = CAPEX4column(T_operation,P_operation,diameter,stages,L,column_material_type,plate_material_type)
global CEPCI
CEPCI = 814.6;
T_operation = T_operation*1.8 + 32; % °C --> °F
T_design = T_operation + 50; % °F
P_operation = (P_operation - 1)*14.5038; % bar --> psia --> psig
diameter = diameter*3.28084; % m --> ft
L = L*3.28084; % m --> ft

if P_operation < 10
    P_design = 10; % En PISG
elseif P_operation >= 10
    % Design the pressure according to the formula
    P_design = exp(0.60608+0.91615*log(P_operation)+0.0015655*(log(P_operation))^2);
end

% Determine the maximum allowable stress, S, in psi or lb/in^2
if (-20 < T_design) && (T_design < 650)
    S = 15000; % lb/in^2
elseif (650 < T_design) && (T_design < 700) % °F
    S = 15000;
elseif (700 < T_design) && (T_design < 750)
    S = 15000;
elseif (750 < T_design) && (T_design < 800)
    S = 14750;
elseif (800 < T_design) && (T_design < 850)
    S = 14200;
elseif (850 < T_design) && (T_design < 900)
    S = 13100;
end

switch column_material_type
    case 0
        Material_Density = 690; % lb/ft^3 carbon steel
        Factor_Material = 1; % Material of construction factors
    case 1
        Material_Density = 493.181; % lb/ft^3 SS 304
        Factor_Material = 1.7;
    case 2
        Material_Density = 499.424; % lb/ft^3 SS 316
        Factor_Material = 2.1;
end

E = 1;
t_p = P_design*diameter*12/(2*S*E - 1.2*P_design);
t_w = 0.22*(diameter*12 + 18)*((L*12)^2)/(S*(diameter*12)^2);
t_v = (t_p + t_p + t_w)/2;
t_s = (t_v + 1/8); % inches include conversion factors

if diameter <= 4
    grosor_min = 1/4; %En inches
    if t_s <= grosor_min,t_s = grosor_min; end

elseif (diameter > 4) && (diameter <= 6)
    grosor_min = 5/16; %En inches
    if t_s <= grosor_min,t_s = grosor_min; end

elseif (diameter > 6) && (diameter <= 8)
    grosor_min = 3/8; %En inches
    if t_s <= grosor_min,t_s = grosor_min; end

elseif (diameter > 8) && (diameter <= 10)
    grosor_min = 7/16; %En inches
    if t_s <= grosor_min,t_s = grosor_min; end

elseif (diameter > 10) && (diameter <= 15)
    grosor_min = 1/2; %En inches
    if t_s <= grosor_min,t_s = grosor_min; end
end

W = pi*(diameter + t_s/12)*(L + 0.8*diameter)*t_s/12*Material_Density;
Cv = exp(10.5449-0.4672*log(W)+0.05482*(log(W))^2);
C_PL = 341*(diameter^0.63316)*(L^0.80161);
cost_vessel = Factor_Material*Cv + C_PL; % f.o.b purchase cost
C_BT = 468*exp(0.1739*diameter);

if stages >= 20
    F_NT = 1;
elseif stages < 20
    F_NT = 2.25/(1.0414^stages);
end

F_TT = 1;

switch plate_material_type
    case 0
        Factor_Material_Column = 1;
    case 1
        Factor_Material_Column = 1.189 + 0.0577*diameter;
    case 2
        Factor_Material_Column = 1.401 + 0.0724*diameter;
end

cost_plates = stages*F_NT*F_TT*Factor_Material_Column*C_BT;
cost_total_column = cost_vessel + cost_plates;
cost = cost_total_column*(CEPCI/567);
end
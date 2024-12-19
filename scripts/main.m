%{
========================================================================
Automatic distillation sequence synthesis framework
- based on the preorder traversal algorithm 
Version 1.2.0 (updated 2024/12/19)
This software is open source under the GNU General Public License v3.0.
Copyright (C) 2024  karei
========================================================================
%}
% User options (code interface)
clc
addpath("src\")
global AF gen_rule GUIindicator utility_set
GUIindicator = 0;
basefile = 'case3.bkp';
path = fullfile(pwd,'Simulation file','baseFile',filesep);
feedstream = 'R1-1'; % The stream name entering the separation section
regression = 0; % 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
heat_integration = 0;
sensitivity_ana = 0;
work_dir = fullfile('D:','distillation',filesep); % Setting up the working directory
AF = 1/3; % Annualization factor
% seq = get_force_selection(max_solution); % Certain sequences can be forcibly selected

%{
material: A structure that contains the name of components and specified products.
gen_rule: A structure that specifies the recovery and pressures between component pairs.
exheatflow: Heat exchangers other than distillation columns in case of heat integration.
max_solution: Maximum number of solutions required.
%}
exheatflow = [];
switch basefile
    case 'case3.bkp' % case3, C5
        material = struct( ...
            'name',{'NC3','IC4','NC4','IC5','NC5','CC5','IC61','IC62','IC63','NC6','CC61', ...
            'IC7','C6H6','CC62','NC7'}, ...
            'product',{0,0,0,1,1,1,1,0,0,0,0,0,0,0,0});
        gen_rule{1} = struct( ...
            'name1',{"default","IC4"}, ...
            'name2',{"default","IC5"}, ...
            'P',{1.5*1e5,5.3*1e5}, ... % unit: Pa
            'recovl',{0.999,[]}, ...
            'recovh',{0.001,[]});
        max_solution = 5; % How many optimal solutions to generate
        utility_set = 1;
        colpressure = 1;
        addPS = 1;
        unit = 'SI';
end

run src\main_program.m
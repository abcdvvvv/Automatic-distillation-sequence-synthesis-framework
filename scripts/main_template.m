%{
========================================================================
Automatic distillation sequence synthesis framework
- based on the preorder traversal algorithm 
Version 1.2.1 (updated 02/13/2025)
This software is open source under the GNU General Public License v3.0.
Copyright (C) 2025  karei
========================================================================
Note: This is a template file, and we recommend that you copy the file 
before modifying it for your own case.
%}
clc
addpath("src\")
global AF gen_rule GUIindicator utility_set
GUIindicator = 0;

% User options (code interface)
basefile = 'case3.bkp';

feedstream = 'R1-1'; % The stream name entering the separation section

% material: A structure that contains the name of components and specified products.
material = struct( ...
    'name',{'NC3','IC4','NC4','IC5','NC5','CC5','IC61','IC62','IC63','NC6','CC61', ...
    'IC7','C6H6','CC62','NC7'}, ...
    'product',{0,0,0,1,1,1,1,0,0,0,0,0,0,0,0});

% gen_rule: A structure that specifies the recovery and pressures between component pairs.
gen_rule{1} = struct( ...
    'name1',{"default","IC4"}, ...
    'name2',{"default","IC5"}, ...
    'P',{1.5*1e5,5.3*1e5}, ... % unit: Pa
    'recovl',{0.999,[]}, ...
    'recovh',{0.001,[]});

% exheatflow: Heat exchangers other than distillation columns in case of heat integration.
exheatflow = [];

% How many optimal solutions to generate
max_solution = 5;

% Corresponds to the price defined in the `src/get_utility_price.m`
utility_set = 1;

% Whether to adjust the column pressure. 1 is recommend.
colpressure = 1;

% Automatic addition of physical property analysis
addPS = 1;
unit = 'SI';

% 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
regression = 0;

heat_integration = 0;

sensitivity_ana = 0;

% Setting up the working directory
work_dir = fullfile('D:','distillation',filesep); 

AF = 1/3; % Annualization factor

% seq = get_force_selection(max_solution); % Certain sequences can be forcibly selected

run src\main_program.m
function [material,gen_rule,exheatflow,max_solution] = name2struct(basefile,GUIindicator)
%{
Input:
    basefile: Name of the Aspen Plus simulation .bkp file.
    GUIindicator: GUI interfaces that are not done yet.
Output:
    material: A structure that contains the name of components and specified products.
    gen_rule: A structure that specifies the recovery and pressures between component pairs.
    exheatflow: Heat exchangers other than distillation columns in case of heat integration.
    max_solution: Maximum number of solutions required.
%}
global utility_set
switch basefile
    case 'case3.bkp'
        material = struct( ...
            'name', {'NC3','IC4','NC4','IC5','NC5','CC5','IC61','IC62' 'IC63' 'NC6' 'CC61' 'IC7' ...
                'C6H6' 'CC62' 'NC7'}, ...
            'product',{0 0 0 1 1 2 2 0 0 0 0 0 0 0 0}); % case3,C5
        gen_rule{1} = struct( ...
            'name1',    {"default" "IC4"}, ...
            'name2',    {"default" "IC5"}, ...
            'P',        {1.5        5.3}, ... 
            'recovl',   {0.999      []}, ...
            'recovh',   {0.001      []});
        exheatflow = struct( ... % Heat integration for adding external heat flow
            'Ti',{30,300}, ... % input temperature
            'To',{35,200}, ... % output temperature
            'Q', {2000,-1000});% duty
        max_solution = 3; % How many optimal solutions to generate
        utility_set=1;
end
end
%{
=========================================================================
Automatic distillation sequence synthesis framework
- based on the preorder traversal algorithm 
Version 1.1 Updated 2024/6/18
Note:
1.Regression cannot be used together with heat integration
This software is open source under the GNU General Public License v3.0.
Copyright (C) 2024  abcdvvvv
=========================================================================
%}
clc
clear all
addpath('function\')

%% User options
global AF gen_rule
GUIindicator = 0;
basefile = 'case3.bkp';
path = [pwd,'\Simulation file\baseFile\'];
feedstream = 'R1-1'; % The stream name entering the separation section
regression = 0; % 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
heat_integration = 0; % Heat integration
work_dir = fullfile(pwd,'Simulation file',filesep); % Setting up the working directory
AF = 1/3; % Annualization factor
[material,gen_rule,exheatflow,max_solution] = name2struct(basefile,GUIindicator);
colpressure = 0; % whether to optimize column pressure

%% Create folder and copy file
global mydir aspen
startTime = datetime("now","Format","yyyy-MM-dd_HH-mm-ss");
mydir = [work_dir,char(startTime),'\'];
if ~exist(mydir,'dir'),mkdir(mydir); end
if ~exist(work_dir,"dir"),mkdir(work_dir); end
filename = 'base_superstructure.bkp';
copyfile([path,basefile],[mydir,filename],'f');
output_file = [mydir,'output.xlsx'];
evoke(mydir,filename);
run();

% Definie product subsets
material_num = length(material);
for i = 1:material_num
    material(i).num = i;
end


stream = aspen.Tree.FindNode('\Data\Streams\');
i = 1;
while i <= material_num
    % Thresholds for trace components
    if stream.FindNode([feedstream,'\Output\MOLEFRAC\MIXED\',material(i).name]).value >= 0.001
        f(i) = stream.FindNode([feedstream,'\Output\MOLEFLOW\MIXED\',material(i).name]).value;
        i = i+1;
    else
        material(i) = [];
        material_num = length(material);
    end
end

% Calculate the number of components for the problem
count = 1;
material(1).sep = 1;
for i = 2:material_num
    if material(i).product == 0
        if material(i-1).product ~= 0
            count = count+1;
            material(i).sep = count;
        else
            material(i).sep = count;
        end
    elseif material(i).product == 1
        count = count+1;
        material(i).sep = count;
    elseif material(i).product == 2
        if material(i-1).product ~= 2
            count = count+1;
            material(i).sep = count;
        else
            material(i).sep = count;
        end
    end
end
fprintf('%d',[material.sep])
fprintf('\n%d-component distillation sequence synthesis\n',material(end).sep)

%% Generate the superstructure
fprintf('[Generate the superstructure]\n')
global dupl columnio column_num
dupl = {'S', {}, 1, length(material)};
columnio = {};
superstructure(material,feedstream,gen_rule);
try
    a = run();
catch
    evoke(mydir,filename);
    a = run();
end
% Adjust the ERROR model
if a, fixerror(); end
pause(1)
allcol = readcolumn();

%% Adjust the design specifications
DSadjust(allcol,gen_rule,colpressure);
% Optimize design parameters
modify_param();
allcol = readcolumn(allcol);
stream = aspen.Tree.FindNode('\Data\Streams\');
for i = 1:column_num
    % heat of vaporization
    DHVL(i) = stream.FindNode([columnio{i,4},'\Output\STRM_UPP\DHVLMX\MIXED\TOTAL']).value;
end
% Output data
allcol = odata(allcol,material,output_file,DHVL);

%% MILP modeling and optimization
fprintf('[Optimization]\n')
sharp_sep = regression; % regression when sharp_sep
if sharp_sep == 0 % read flow rate from aspen
    f = zeros(4);
    for i = 1:column_num
        f(i,1) = i;
        f(i,2) = stream.FindNode([columnio{i,2},'\Output\TOT_FLOW']).value;
        f(i,3) = stream.FindNode([columnio{i,3},'\Output\TOT_FLOW']).value;
        f(i,4) = stream.FindNode([columnio{i,4},'\Output\TOT_FLOW']).value;
    end
end
forbidden_match = {};
solution = cell(max_solution,1);
objValue = nan(max_solution,1);
optim_col = cell(max_solution,1);
writematrix(["Seq." "Selected column" "Cut (M$/yr)" "Cap (M$/yr)" "TAC (M$/yr)" "HICut (M$/yr)" ...
    "HICap (M$/yr)" "HITAC (M$/yr)"],output_file,'Sheet','Results','Range','A2')
tic
for i = 1:max_solution
    if i > 1
        forbidden_match{i-1} = optim_col{i-1};
    end
    force_match=[];
    [solution{i}, objValue(i)] = ...
        optimization(allcol,f,dupl,DHVL,forbidden_match,regression,sharp_sep,0,[],force_match, ...
        material(end).sep);
    if i==1
        CutAll=readmatrix(output_file,'Range',[char(74),'2:',char(74),num2str(column_num+1)]);
        CapAll=readmatrix(output_file,'Range',[char(73),'2:',char(73),num2str(column_num+1)]);
    end
    if ~isempty(solution{i})
        optim_col{i} = find(abs(solution{i}.y-1) <= 1e-5)';
        Cut(i,1) = sum(CutAll(optim_col{i}));
        Cap(i,1) = sum(CapAll(optim_col{i}));
    end
    % Sensitivity Analysis with built-in plot
    % if max_solution > 1 && ~regression
    %     SensitivityAna(allcol,optim_col(i,:),output_file);
    %     if i==max_solution
    %         legend('1st','2nd','3rd')
    %     end
    % end
end
nonHItime=toc/max_solution;
fprintf('Average time for non-heat integration calculations=%.4f s\n',nonHItime)
writematrix([Cut,Cap,objValue],output_file,'Sheet','Results','Range','C3')
for i=1:length(optim_col)
    writematrix(num2str(optim_col{i}),output_file,'Sheet','Results','Range',['B',num2str(2+i)])
end

%% Heat integration
forbidden_match = {};
solution_hi = cell(max_solution,1);
objValue_hi = nan(max_solution,1);
optim_col_hi = cell(max_solution,1);
tic
for i = 1:max_solution*heat_integration
    if i > 1
        forbidden_match{i-1} = optim_col_hi{i-1};
    end
    disp('[Heat integration calculation]')
    force_match=[];
    [solution_hi{i}, objValue_hi(i)] = optimization(allcol,f,dupl,DHVL,forbidden_match, ...
        regression,sharp_sep,1,exheatflow,force_match,material(end).sep);
    if ~isempty(solution_hi{i})
        optim_col_hi{i} = find(abs(solution_hi{i}.y-1) <= 1e-5)';
    end
    HICap(i,1)=sum(solution_hi{i}.mu);
    HiCop(i,1)=objValue_hi(i)-HICap(i,1)*AF;
end
if heat_integration
    HItime=toc/max_solution;
    fprintf('Average time for heat integration calculations=%.4f s\n',HItime)
    for i=1:length(optim_col)
        for j=1:length(optim_col)
            if isequal(optim_col_hi{j},optim_col{i})
                writematrix([HiCop(j),sum(solution_hi{j}.mu),objValue_hi(j)],output_file, ...
                    'Sheet','Results','Range',['F',num2str(2+i)])
            end
        end
    end
end
% show optimal solutions
for i = 1:max_solution
    fprintf('optim_col%d =',i)
    fprintf('\t%d',optim_col{i})
    fprintf('\nTAC%d = %.0f\n\n',i,objValue(i))
end
if heat_integration && ~isempty(solution_hi{1}.y)
    for i = 1:max_solution
        fprintf('optim_col_hi%d =',i)
        fprintf('\t%d',optim_col_hi{i})
        fprintf('\nTAC%d = %.0f\n\n',i,objValue_hi(i))
    end
end
aspen.Save
disp('Saving current results...')
save([mydir,'case1.mat'],'-regexp','^(?!(aspen)$)\w+$')
disp('All done.')
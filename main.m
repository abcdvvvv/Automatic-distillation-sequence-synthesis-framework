%==========================================================================
% Automatic distillation sequence synthesis framework                     %
% - based on the preorder traversal algorithm                             %
% 20230821 version                                                        %
% Note:                                                                   %
% 1.Regression cannot be used together with heat integration              %
% This software is open source under the GNU General Public License v3.0. %
% Copyright (C) 2023  abcdvvvv                                            %
%==========================================================================
clc
clear all
addpath('function\')

%% User options
basefile = 'case3.bkp';
feedstream = 'R1-1'; % The stream name entering the separation section
max_solution = 3; % How many optimal solutions to generate
regression = 0; % 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
heat_integration = 0; % Heat integration
exheatflow = struct( ... % Heat integration for adding external heat flow
    'Ti',{30,300}, ... % input temperature
    'To',{35,200}, ... % output temperature
    'Q', {2000,-1000});% duty
col_optim = 0; % Whether or not to perform column optimization
work_dir = fullfile('D:','distillation',filesep); % Setting up the working directory

%% Create folder and copy file
global AF mydir aspen gen_rule
[material,gen_rule] = name2struct(basefile);
AF = 1/3; % the Annualization factor
startTime = datetime("now","Format","yyyy-MM-dd_HH-mm-ss");
mydir = [work_dir,char(startTime),'\'];
if ~exist(mydir,'dir'),mkdir(mydir); end
if ~exist(work_dir,"dir"),mkdir(work_dir); end
disp(mydir)
filename = 'base_superstructure.bkp';
copyfile([pwd,'\Simulation file\baseFile\',basefile],[mydir,filename],'f');
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
fprintf('【Generate the superstructure】\n')
global dupl columnio column_num
dupl = {'S', {}, 1, length(material)};
columnio = {};
superstructure(material,feedstream,gen_rule);
try
    a = run();
catch
    aspen.Quit
    evoke(mydir,filename);
    a = run();
end
% Adjust the ERROR model
if a, fixerror(); end
pause(1)
allcol = readcolumn();
% Read physical properties from streams
DHVL=nan(column_num,1);TCMX=nan(column_num,1);PBUB=nan(column_num,1);PDEW=nan(column_num,1);
stream = aspen.Tree.FindNode('\Data\Streams\');
for i = 1:column_num
    DHVL(i) = stream.FindNode([columnio{i,4},'\Output\STRM_UPP\DHVLMX\MIXED\TOTAL']).value;
    % TCMX(i) = stream.FindNode([columnio{i,4},'\Output\STRM_UPP\TCMX\MIXED\TOTAL']).value;
    % PBUB(i) = stream.FindNode([columnio{i,3},'\Output\STRM_UPP\PBUB\MIXED\TOTAL']).Element.Item(0).value;
    % PDEW(i) = stream.FindNode([columnio{i,3},'\Output\STRM_UPP\PDEW\MIXED\TOTAL']).Element.Item(0).value;
end
% Adjust the design specifications
DSadjust(allcol,gen_rule,TCMX,PBUB,PDEW);
% Optimize design parameters
modify_param();
allcol = readcolumn();
% Output data
odata(allcol,material,DHVL,output_file);

%% MILP modeling and optimization
fprintf('【Optimization】\n')
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
objectiveValue = nan(max_solution,1);
for i = 1:max_solution
    if i > 1
        position0 = find(optim_col(i-1,:) == 0,1);
        if isempty(position0)
            forbidden_match{i-1} = optim_col(i-1,:); %#ok<*SAGROW>
        else
            forbidden_match{i-1} = optim_col(i-1,1:position0-1);
        end
    end
    [solution{i}, objectiveValue(i)] = optimization(allcol,f,dupl,DHVL,forbidden_match,regression,sharp_sep,0);
    if heat_integration == 1 && i == 1
        disp('[Heat integration calculation]')
        [solution_hi, ~] = optimization(allcol,f,dupl,DHVL,forbidden_match,regression,sharp_sep,1,exheatflow);
    end
    writematrix(['Solution',num2str(i)],output_file,'Range',[char(73+2*i-1),'1']);
    writematrix('Radfrac',output_file,'Range',[char(73+2*i),'1']);
    % solution --> optim_col
    c = 1; optim_col_hi = [];
    for j = 1:column_num
        if abs(solution{i}.y(j)-1) <= 1e-5
            optim_col(i,c) = j;
            writematrix(solution{i}.y(j),output_file,'Range',[char(73+2*i-1),num2str(j+1)]);
            c = c+1;
        end
        if heat_integration == 1 && i == 1
            if ~isempty(solution_hi(1).y) && abs(solution_hi(i).y(j)-1) <= 1e-5
                optim_col_hi = [optim_col_hi,j];
            end
        end
    end
    writematrix('TAC(USD/a)',output_file,'Range',[char(73+2*i-1),num2str(column_num+2)]);
    writematrix(objectiveValue(i),output_file,'Range',[char(73+2*i-1),num2str(column_num+3)]);
    % Sensitivity Analysis with built-in plot
    if max_solution > 1 && ~regression
        SensitivityAna(allcol,optim_col(i,:),output_file);
        if i==max_solution
            legend('1st','2nd','3rd')
        end
    end
end
% show optimal solutions
for i = 1:max_solution
    fprintf('optim_col%d =',i)
    disp(optim_col(i,:))
    fprintf('TAC%d = %.0f\n',i,objectiveValue(i))
end
if heat_integration == 1 && ~isempty(solution_hi(1).y)
    fprintf('optim_col_hi =')
    disp(optim_col_hi)
end
aspen.Save
disp('Saving current results...')
save([mydir,'case1.mat']);
disp('All done.')
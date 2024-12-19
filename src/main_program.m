% Create folder and copy file
global mydir aspen
startTime = datetime("now","Format","yyyy-MM-dd_HH-mm-ss");
mydir = fullfile(work_dir,char(startTime),filesep);
if ~exist(mydir,'dir'), mkdir(mydir); end
if ~exist(work_dir,"dir"), mkdir(work_dir); end
filename = 'base_superstructure.bkp';
copyfile([path,basefile],[mydir,filename],'f');
output_file = [mydir, 'output.xlsx'];
evoke2(mydir,filename);
aspen.Reinit;
run2();

% Definie product subsets
material_num = length(material);
for i = 1:material_num
    material(i).num = i;
end
exnum = [];
if length(gen_rule) > 1
    disp("Use of extraction/extractive distillation")
    % Assuming there is only one extractant
    temp = strcmp(gen_rule{2}(1).extractant,{material.name});
    exnum = find(temp == 1,1);
end
stream = aspen.Tree.FindNode('\Data\Streams\');
i = 1;
while i <= material_num
    % Thresholds for trace components
    if stream.FindNode([feedstream,'\Output\MOLEFRAC\MIXED\',material(i).name]).value >= 0.001
        f(i) = stream.FindNode([feedstream,'\Output\MOLEFLOW\MIXED\',material(i).name]).value;
        i = i + 1;
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
            count = count + 1;
            material(i).sep = count;
        else
            material(i).sep = count;
        end
    elseif material(i).product == 1
        count = count + 1;
        material(i).sep = count;
    elseif material(i).product == 2
        if material(i-1).product ~= 2
            count = count + 1;
            material(i).sep = count;
        else
            material(i).sep = count;
        end
    end
end
fprintf('%d',[material.sep])
fprintf('\n%d-component distillation sequence synthesis\n',material(end).sep)

if GUIindicator,app.displayDiaryInApp; end
if addPS, set_property_analysis(filename,unit); end

%% Generate the superstructure
disp("[Generate the superstructure]")
global dupl columnio column_num
%{
dupl:
    col2: outlet stream, col3: splitnum, col4: number of the left of right part of "/"
    col5: Number of the tower connected in front of the dupl, Each dupl represents the separation 
    task of the previous tower. col6 is the name of the mixer attached to that dupl.
columnio:
    col1: tower number, col2: inlet stream, col3: top stream, col4: bottom stream,
    col5: separation task, col6 indicates how many streams are connected to the previous mixer.
%}
dupl = {'S', {}, 1, length(material)};
columnio = {};
set_superstructure(material,feedstream,gen_rule,exnum);
if length(gen_rule) > 1
    disp("Please adjust the outlet stream flash spec of SEP. Paused.")
    aspen.Visible = 1;
    pause()
    disp("continue ... ")
end
%%
try
    a = run2();
catch
    evoke2(mydir,filename);
    a = run2();
end
% Adjust the ERROR model
if a, fix_error(); end
pause(1)
allcol = get_column_results();
if GUIindicator,displayDiaryInApp(app); end

%% Adjust the design specifications
adjust_pressure_recovery(allcol,gen_rule,colpressure);
% Optimize design parameters
adjust_RR_NT();
allcol = get_column_results(allcol);
stream = aspen.Tree.FindNode('\Data\Streams\');
for i = 1:column_num
    % heat of vaporization
    DHVL(i) = stream.FindNode([columnio{i,4},'\Output\STRM_UPP\DHVLMX\MIXED\TOTAL']).value;
end
% Output data
allcol = save_column_data(allcol,material,output_file,DHVL);
if GUIindicator,app.displayDiaryInApp; end

%% MILP modeling and optimization
disp("[Optimization]")
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
writematrix(["Seq." "Selected column" "Cut(M$/yr)" "Cap(M$/yr)" "TAC(M$/yr)" "Selected column" ...
    "HICut(M$/yr)" "HICap(M$/yr)" "HITAC(M$/yr)"],output_file,'Sheet','Results','Range','A2')
tic
for i = 1:max_solution
    if i > 1
        forbidden_match{i-1} = optim_col{i-1};
    end
    if exist("seq","var")
        force_match = seq{i};
        fprintf('[Use force match:')
        fprintf(' %d',force_match)
        fprintf(']\n')
    else
        force_match = [];
    end
    [solution{i}, objValue(i)] = ...
        set_and_optimize(allcol,f,dupl,DHVL,forbidden_match,regression,sharp_sep,0,[],force_match, ...
        material(end).sep);
    if i == 1
        CutAll = readmatrix(output_file,'Range',[char(74),'2:',char(74),num2str(column_num+1)]);
        CapAll = readmatrix(output_file,'Range',[char(73),'2:',char(73),num2str(column_num+1)]);
    end
    if ~isempty(solution{i})
        optim_col{i} = find(abs(solution{i}.y-1) <= 1e-5)';
        Cut(i,1) = sum(CutAll(optim_col{i}));
        Cap(i,1) = sum(CapAll(optim_col{i}));
    end
    % Sensitivity Analysis with built-in plot
    if sensitivity_ana && max_solution > 1 && ~regression
        [x,TAC] = calc_sensitivity_analysis(allcol,optim_col(i,:),output_file);
        if i == max_solution
            legend('1st','2nd','3rd')
        end
        if GUIindicator
            plot(app.SensitivityPlot,x,TAC)
        end
    end
end
nonHItime = toc/max_solution;
writematrix([Cut,Cap,objValue],output_file,'Sheet','Results','Range','C3')
for i = 1:length(optim_col)
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
    disp("[Heat integration calculation]")
    if exist("seq","var")
        force_match = seq{i};
        fprintf('[Use force match:')
        fprintf(' %d',force_match)
        fprintf(']\n')
    else
        force_match = [];
    end
    [solution_hi{i}, objValue_hi(i)] = set_and_optimize(allcol,f,dupl,DHVL,forbidden_match, ...
        regression,sharp_sep,1,exheatflow,force_match,material(end).sep);
    if ~isempty(solution_hi{i})
        optim_col_hi{i} = find(abs(solution_hi{i}.y-1) <= 1e-5)';
    end
    HICap(i,1) = sum(solution_hi{i}.mu);
    HiCop(i,1) = objValue_hi(i) - HICap(i,1)*AF;
end

fprintf('Average time for non-heat integration calculations=%.4f s\n',nonHItime)
if heat_integration
    HItime = toc/max_solution;
    fprintf('Average time for heat integration calculations=%.4f s\n',HItime)
    if exist("seq","var") % Output directly if there is a forced selection
        writematrix([HiCop,HICap,objValue_hi],output_file,'Sheet','Results','Range','F3')
    else % otherwise sort the results by non-heat integration
        for i = 1:length(optim_col_hi)
            writematrix(num2str(optim_col_hi{i}),output_file,'Sheet','Results','Range',['F',num2str(2+i)])
        end
        writematrix([HiCop,HICap,objValue_hi],output_file,'Sheet','Results','Range','G3')
        % for i = 1:length(optim_col)
        %     for j = 1:length(optim_col)
        %         if isequal(optim_col_hi{j},optim_col{i})
        %             writematrix([HiCop(j),sum(solution_hi{j}.mu),objValue_hi(j)],output_file, ...
        %                 'Sheet','Results','Range',['F',num2str(2+i)])
        %         end
        %     end
        % end
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
disp("Saving current results ... ")
save([mydir,'case1.mat'],'-regexp','^(?!(aspen)$|app$|event$)\w+$')
pause(0.5)
aspen.Quit
release(aspen)
disp("All done.")
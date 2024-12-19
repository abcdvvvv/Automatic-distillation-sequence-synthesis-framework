function [solution, objectiveValue] = set_and_optimize(allcol,f,dupl,DHVL,forbidden_match,regression, ...
    sharp_sep,heat_intergated,exheatflow,force_match,maxcol)
global mydir column_num columnio AF
if sharp_sep == 1
    f_tot = sum(f);
else
    f_tot = f(1,2);
end
Tmin = 10; % maxcol is the number of columns to be used for each sequence
mpnum = sum([columnio{[columnio{:,6}] > 1,6}]); % Find how many streams are connected to the mixer and how many variables need to be added
duplength = length(dupl(:,1)); % Number of dupl
ex_num = sum([columnio{:,7}] ~= 0); % Find the total number of extractant streams
t45idx = [allcol.TTOP]' > 45; % Apply Tc constraints only to columns with initial tops greater than 45��C

%% Create optimization variables
F = optimvar("F",column_num,1,"LowerBound",0);
y = optimvar("y",column_num,1,"Type","integer","LowerBound",0,"UpperBound",1);
if mpnum > 0
    C = optimvar("C",mpnum,1,"LowerBound",0);
else
    C = [];
end
if heat_intergated
    exheat_num = length(exheatflow); % Number of external heat streams
    total_num = column_num+exheat_num;
    Tc = optimvar("Tc",column_num,1,"LowerBound",0);
    TcMid = optimvar("TcMid",column_num,1,"LowerBound",0);
    Tr = optimvar("Tr",column_num,1,"LowerBound",0);
    z = optimvar("z",total_num,total_num,"Type","integer","LowerBound",0,"UpperBound",1);
    QEX = optimvar("QEX",total_num,total_num,"LowerBound",0);
    QW = optimvar("QW",total_num,1,"UpperBound",0);
    QS = optimvar("QS",total_num,1,"LowerBound",0);
    mu = optimvar("mu",column_num,1,"LowerBound",0); % capital cost
end

if ex_num > 0 % extractive distillation available
    ex = optimvar("ex",column_num,1,"LowerBound",0);
    initialPoint.ex = zeros(size(ex));
else
    maxcol = maxcol-1; % 4comp3col without extractive
end

sum_dupl = optimexpr(duplength);
streamf = zeros(1,column_num);
mp_var = 1; % supplementary variable counts
for k = 1:duplength % This loop first counts all streamf
    for l = 1:length(dupl{k,2})
        temp = strfind(dupl{k,2}{l},'-'); % find if the dupl is connected to a stream with "-"
        dupl_l_num = str2double(dupl{k,2}{l});
        if isempty(temp) % If dupl is connected to a stream with "-"
            sum_dupl(k) = sum_dupl(k)+F(dupl_l_num); %sum_duplָ����ÿ��dupl������������,��i�е�dupl
        else
            sum_dupl(k) = sum_dupl(k)+C(mp_var);
            mixernum = str2double(dupl{k,2}{l}(1:temp-1));
            var2mix(mp_var) = mixernum; %����ӳ��,var2mix���Ż�����123˳���ţ�ȡֵ����mixer����
            mp_var = mp_var+1;
        end
        if sharp_sep == 1
            switch dupl{k,1}(1) % calculate all streamf
                case 'S'
                    streamf(dupl_l_num) = f_tot;
                case 'D'
                    for m = dupl{k,3}:-1:dupl{k,3}-dupl{k,4}+1
                        if isempty(temp)
                            streamf(dupl_l_num) = streamf(dupl_l_num)+f(m);
                        else
                            streamf(mixernum) = streamf(mixernum)+f(m);
                        end
                    end
                case 'B'
                    for m = dupl{k,3}:dupl{k,3}+dupl{k,4}-1
                        if isempty(temp)
                            streamf(dupl_l_num) = streamf(dupl_l_num)+f(m);
                        else
                            streamf(mixernum) = streamf(mixernum)+f(m);
                        end
                    end
                otherwise
                    error('Illegal names exist for "dupl".')
            end
        end
    end
end

% Fixing streamf recalculation after adding mixer
if sharp_sep == 1
    for k = 1:column_num
        streamf(k) = streamf(k)/columnio{k,6};
    end
end

if regression == 0
    CAPEX = [allcol.Cap]*y; % $
    F_min = zeros(column_num,1);
else
    [CAPEX,F_min] = calc_capex_by_regress(allcol,F,y,streamf,DHVL);
end

if ~heat_intergated
    OPEX = calc_opex_for_optim(F,allcol);
else
    OPEX = calc_opex_for_optim(F,allcol,QW,QS,exheat_num);
end

%% Set initial starting point for the solver
initialPoint.F = zeros(size(F));
initialPoint.y = zeros(size(y));
if mpnum > 0
    initialPoint.C = zeros(size(C));
end
if heat_intergated
    initialPoint.Tc = [allcol.TTOP]';
    initialPoint.TcMid = [allcol.TTOP]';
    initialPoint.Tr = [allcol.TBOT]';
    initialPoint.z = zeros(size(z));
    initialPoint.QEX = zeros(size(QEX));
    initialPoint.QW = zeros(size(QW));
    initialPoint.QS = zeros(size(QS));
    initialPoint.mu = zeros(size(mu));
end
% Create problem
problem = optimproblem;
% Define problem objective
if ~heat_intergated
    problem.Objective = CAPEX*AF+OPEX;
else
    problem.Objective = sum(mu)*AF+OPEX;
end
% Define problem constraints
problem.Constraints.constraint1 = constraintFcn(F,y,C,f,sharp_sep,force_match);
problem.Constraints.constraint2 = constraintFcn2(F,y,F_min,forbidden_match,force_match);
if heat_intergated
    problem.Constraints.constraint3 = constraintFcn3(F,Tc,Tr,QEX,QW,QS,exheatflow);
    problem.Constraints.constraint4 = constraintFcn4(y,Tc,TcMid,Tr,z,QEX,mu,Tmin,exheatflow,maxcol,t45idx);
end
if ex_num > 0
    problem.Constraints.constraint5 = constraintFcn5(ex,y);
end
options = optimoptions("intlinprog","Display","final");
% Display problem information of the 1st optimal solution
if isempty(forbidden_match) && ~heat_intergated
    show(problem)
end
% Solve problem
[solution, objectiveValue] = solve(problem,initialPoint,"Solver","intlinprog","Options",options);

%% Constraint
function constraints = constraintFcn(F,y,C,f,sharp_sep,force_match)
    % This function should return a vector of optimization constraints.
    constraints(1) = sum_dupl(1) == f_tot;
    constraints(2,1) = optimeq();
    for i = 2:duplength
        temp2 = strfind(dupl{i,2}{1},'-'); % just take the first one because it's the composition that counts here, and the composition after the dupl is the same
        dupl_1_num = str2double(dupl{i,2}{1});
        col = dupl{i,5}; % col is the number of the tower being mass-accounted for
        if isempty(temp2)
            if sharp_sep == 1
                constraints(i) = sum_dupl(i) == streamf(dupl_1_num)/streamf(col)*F(col); %#ok<*AGROW>
            elseif columnio{col,7} == 0
                constraints(i) = sum_dupl(i) == f(dupl_1_num,2)/f(col,2)*F(col);
            else
                constraints(i) = sum_dupl(i) == f(dupl_1_num,2)/(f(col,2)+columnio{col,7})*(F(col)+ex(col));
                % only consider the first extractant
            end
        else
            mixernum = str2double(dupl{i,2}{1}(1:temp2-1));
            if sharp_sep == 1
                constraints(i) = sum_dupl(i) == streamf(mixernum)/streamf(col)*F(col);
            else
                switch dupl{i,1}(1)
                    case 'D'
                        if columnio{col,7} == 0
                            constraints(i) = sum_dupl(i) == f(col,3)/f(col,2)*F(col);
                        else
                            constraints(i) = sum_dupl(i) == f(col,3)/(f(col,2)+columnio{col,7})*(F(col)+ex(col));
                            %��f(mixernum,2)��ԭ����д��,��������ʹ�ü�����������ȡ���ĳ���,�ȷ���ȡ���ټ���ȡ����һ·��������
                        end
                    case 'B'
                        if columnio{col,7} == 0
                            constraints(i) = sum_dupl(i) == f(col,4)/f(col,2)*F(col);
                        else
                            constraints(i) = sum_dupl(i) == f(col,4)/(f(col,2)+columnio{col,7})*(F(col)+ex(col));
                        end
                end
            end
        end
    end

    sum_mix = optimexpr(sum([columnio{:,6}] > 1)); %�����������
    if mp_var-1 ~= mpnum %����mixer����������
        warning('mp_var-1������mpnum!')
    end
    t = 1;
    for i = 1:column_num
        if columnio{i,6} > 1 %����1˵���л����
            for j = 1:length(var2mix)
                if var2mix(j) == columnio{i,1}
                    sum_mix(t) = sum_mix(t)+C(j);
                end
            end
            constraints(duplength+t) = F(i) == sum_mix(t);
            t = t+1;
        end
    end

    if ~isempty(force_match) % force select
        constraints = [constraints; y(force_match) == 1];
        constraints = [constraints; sum(y) == length(force_match)];
    end
end

function constraints = constraintFcn2(F,y,F_min,forbidden_match,force_match)
    exf = max([columnio{:,7}]); % extractant flow
    % Basic flow constraints
    constraints = F-(f_tot+exf)*y <= 0; % ����ȡ�������������
    % Integer cut constraint
    if isempty(force_match) && ~isempty(forbidden_match) % ǿ��ѡ������ȼ����ڽ�ֹƥ��
        for i = 1:length(forbidden_match)
            constraints(end+1) = sum(y(forbidden_match{i})) <= length(forbidden_match{i})-1;
        end
    end
    % Minimum flow limit for regression
    if regression == 1
        for i = 1:column_num
            if F_min(i) ~= 0
                constraints(end+1) = -F(i)+F_min(i)*y(i) <= 0;
            end
        end
    end
    % constraints(end+1) =sum(y)<=5; % �������ֲ�֪��Ϊʲô��ѡ�����
end

%% Heat integration constraints
function constraints = constraintFcn3(F,Tc,Tr,QEX,QW,QS,exheatflow)
    K = readmatrix([mydir, 'output.xlsx'],'Range',['G2:H',num2str(column_num+1)]);
    % ���������²�Լ��
    constraints = optimeq();
    deltaT = ([allcol.TBOT]-[allcol.TTOP])';
    constraints = [constraints; Tr == Tc+deltaT];
    % ������QEX��Լ��
    sum_QEX1 = sum(QEX,2)-diag(QEX);
    sum_QEX2 = sum(QEX,1)'-diag(QEX);
    constraints = [constraints; -sum_QEX1(1:column_num)+QW(1:column_num) == K(:,1) .* F / 3600 * 1e9];
    constraints = [constraints; sum_QEX2(1:column_num)+QS(1:column_num) == K(:,2) .* F / 3600 * 1e9];
    for i = column_num+1:column_num+exheat_num % �ⲿ�����ɵĻ�����QEX��Լ��
        if exheatflow(i-column_num).Q < 0 % a cooler
            constraints(end+1) = -sum_QEX1(i)+QW(i) == exheatflow(i-column_num).Q;
            constraints(end+1) = sum_QEX2(i)+QS(i) == 0;
        elseif exheatflow(i-column_num).Q > 0 % a heater
            constraints(end+1) = -sum_QEX1(i)+QW(i) == 0;
            constraints(end+1) = sum_QEX2(i)+QS(i) == exheatflow(i-column_num).Q;
        end
    end
    constraints = [constraints; diag(QEX) == 0];
end

function constraints = constraintFcn4(y,Tc,TcMid,Tr,z,QEX,mu,Tmin,exheatflow,maxcol,t45idx)
    cap = readmatrix([mydir, 'output.xlsx'],'Range',['I2:I',num2str(column_num+1)]);

    constraints(1) = sum(y) <= maxcol; % 5������4����,�ӿ�����ٶ�
    constraints = [constraints; reshape(QEX-99999*z <= 0,[],1)];
    constraints = [constraints; Tr <= 290+999*(1-y)]; % �����������290.01��C,DMC�ٽ�274��C
    constraints = [constraints; 45 <= Tc(t45idx)+999*(1-y(t45idx))]; % ��ȴˮ35��C,+999*(1-y)���¼ӵ�
    constraints = [constraints; ([allcol.TTOP]'-50)-Tc <= 0];
    % ���ﲻӦ���Ǳ�45��C��CAPEX�͸�,���Ǹ��ڸ�����׼�����¶�ʱ����CAPEX
    constraints = [constraints; cap.*(1+1*TcMid./[allcol.TTOP]')-2e9*(1-y) <= mu];
    constraints = [constraints; Tc-[allcol.TTOP]' <= TcMid];
    constraints = [constraints; [allcol.TTOP]'-Tc <= TcMid];
    for i = 1:column_num
        constraints = [constraints; [z(i,1:column_num)]' <= y];
        constraints = [constraints; z(1:column_num,i) <= y];
        constraints = [constraints; Tr+Tmin-999*(1-z(i,1:column_num)')-Tc(i) <= 0]; % �����²�Լ��
        % ��ʽ�ĵȼ۴���ο�:
        % for j=1:column_num
        %     if i~=j
        %         constraints(end+1)= Tr(j)+Tmin-999*(1-z(i,j))-Tc(i)<=0;
        %         constraints(end+1)= z(i,j)<=y(i);
        %         constraints(end+1)= z(i,j)<=y(j);
        %     end
        % end
    end
    % Adding heat transfer temperature difference constraints for external heat flows
    if exheat_num > 0
        for i = column_num+1:column_num+exheat_num
            if exheatflow(i-column_num).Q < 0 % cooler
                constraints = [constraints; Tr(1:column_num)+Tmin-999*(1-z(i,1:column_num)')-exheatflow(i-column_num).To <= 0];
            end
        end
        for j = column_num+1:column_num+exheat_num
            if exheatflow(j-column_num).Q > 0 % heater
                constraints = [constraints; exheatflow(j-column_num).To+Tmin-999*(1-z(1:column_num,j))-Tc(1:column_num) <= 0];
            end
        end
        for i = column_num+1:column_num+exheat_num
            for j = column_num+1:column_num+exheat_num
                if i ~= j % heat exchange between i-column_num and j-column_num
                    constraints(end+1) = exheatflow(j-column_num).To+Tmin-999*(1-z(i,j))-exheatflow(i-column_num).To <= 0;
                end
            end
        end
    end
end

%% ��ȡ��Լ��
function constraints = constraintFcn5(ex,y)
    constraints = ex == [columnio{:,7}]'.*y;
end

end
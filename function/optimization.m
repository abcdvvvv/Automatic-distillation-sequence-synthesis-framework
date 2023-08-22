function [solution, objectiveValue] = optimization(allcol,f,dupl,DHVL,forbidden_match,regression,sharp_sep,heat_intergated,exheatflow)
global mydir column_num columnio AF
if sharp_sep==1
    f_tot = sum(f);
else
    f_tot = f(1,2);
end
Tmin=10; % LMTD 10K
mpnum=sum([columnio{[columnio{:,6}]>1,6}]);
duplength=length(dupl(:,1));

%% Create optimization variables
F = optimvar("F", column_num, 1, "LowerBound", 0);
y = optimvar("y", column_num, 1, "Type", "integer", "LowerBound", 0, "UpperBound", 1);
C = optimvar("C", mpnum, 1, "LowerBound", 0);
if heat_intergated==1
exheat_num=length(exheatflow);
total_num=column_num+exheat_num;
Tc = optimvar("Tc", column_num, 1, "LowerBound", 0);
Tr = optimvar("Tr", column_num, 1, "LowerBound", 0);
z  = optimvar("z",  total_num, total_num, "Type", "integer", "LowerBound", 0, "UpperBound", 1);
QEX= optimvar("QEX",total_num, total_num, "LowerBound", 0);
QW = optimvar("QW", total_num, 1, "LowerBound", 0);
QS = optimvar("QS", total_num, 1, "LowerBound", 0);
mu = optimvar("mu", column_num, 1, "LowerBound", 0);
end
sum_dupl = optimexpr(duplength);
streamf = zeros(1, column_num);
mp_var=1;
for k = 1:duplength 
    for l = 1:length(dupl{k,2})
        temp=strfind(dupl{k,2}{l},'-');
        dupl_l_num=str2double(dupl{k,2}{l});
        if isempty(temp)
            sum_dupl(k) = sum_dupl(k) + F(dupl_l_num);
        else
            sum_dupl(k)=sum_dupl(k)+C(mp_var);
            mixernum=str2double(dupl{k,2}{l}(1:temp-1));
            var2mix(mp_var)=mixernum; 
            mp_var=mp_var+1;
        end
        if sharp_sep==1
            switch dupl{k,1}(1)
                case 'S'
                    streamf(dupl_l_num) = f_tot;
                case 'D'
                    for m = dupl{k,3}:-1:dupl{k,3} - dupl{k,4} + 1
                        if isempty(temp)
                            streamf(dupl_l_num) = streamf(dupl_l_num) + f(m);
                        else
                            streamf(mixernum) = streamf(mixernum) + f(m);
                        end
                    end
                case 'B'
                    for m = dupl{k,3}:dupl{k,3} + dupl{k,4} - 1
                        if isempty(temp)
                            streamf(dupl_l_num) = streamf(dupl_l_num) + f(m);
                        else
                            streamf(mixernum) = streamf(mixernum) + f(m);
                        end
                    end
            end
        end
    end
end

if sharp_sep==1
    for k=1:column_num
        streamf(k)=streamf(k)/columnio{k,6};
    end
end

if regression==0
    CAPEX = CAPEX4optim(allcol,y);
    F_min=zeros(column_num);
else
    [CAPEX,F_min]=CAPEX0regress(allcol,F,y,streamf,DHVL);
end

if heat_intergated==0
    OPEX = fOPEX4optim(F,allcol);
else
    OPEX = optimexpr(total_num);
    [cost_CW,~,~,cost_S,~,~,~,~,~] = utilities();
    for k=1:total_num
        OPEX(k) = (QW(k)*cost_CW+QS(k)*cost_S) * 3600 * 8000 / 10^6;
    end
end

%% Set initial starting point for the solver
initialPoint.F = zeros(size(F));
initialPoint.y = zeros(size(y));
initialPoint.C = zeros(size(C));
if heat_intergated==1
initialPoint.Tc = zeros(size(Tc));
initialPoint.Tr = zeros(size(Tr));
initialPoint.z  = zeros(size(z));
initialPoint.QEX= zeros(size(QEX));
initialPoint.QW = zeros(size(QW));
initialPoint.QS = zeros(size(QS));
initialPoint.mu = zeros(size(mu));
end
% Create problem
problem = optimproblem;
% Define problem objective
if heat_intergated==0
    problem.Objective = CAPEX*AF + OPEX;
else
    problem.Objective = sum(mu)*AF + sum(OPEX);
end
% Define problem constraints
problem.Constraints.constraint1 = constraintFcn(F,C,f,sharp_sep);
problem.Constraints.constraint2 = constraintFcn2(F,y,F_min,forbidden_match);
if heat_intergated==1
    problem.Constraints.constraint3 = constraintFcn3(F,Tc,Tr,QEX,QW,QS,exheatflow);
    problem.Constraints.constraint4 = constraintFcn4(y,Tc,Tr,z,QEX,mu,Tmin,exheatflow);
end
options = optimoptions("intlinprog", "Display", "final");
% Display problem information of the 1st optimal solution
if isempty(forbidden_match)
    show(problem)
end
% Solve problem
[solution, objectiveValue] = solve(problem, initialPoint, "Solver", "intlinprog", "Options", options);

%% Constraint
function constraints = constraintFcn(F,C,f,sharp_sep)
    constraints(1) = sum_dupl(1) == f_tot;
    for i = 2:duplength
        temp2=strfind(dupl{i,2}{1},'-');
        dupl_1_num=str2double(dupl{i,2}{1});
        col=dupl{i,5};
        if isempty(temp2)
            if sharp_sep==1
                constraints(i) = sum_dupl(i) == streamf(dupl_1_num) / streamf(col) * F(col); %#ok<*AGROW>
            else
                constraints(i) = sum_dupl(i) == f(dupl_1_num,1) / f(col,1) * F(col);
            end
        else
            mixernum=str2double(dupl{i,2}{1}(1:temp2-1));
            if sharp_sep==1
                constraints(i) = sum_dupl(i) == streamf(mixernum) / streamf(col) * F(col);
            else
                switch dupl{i,1}(1)
                    case 'D'
                        constraints(i) = sum_dupl(i) == f(col,3) / f(col,2) * F(col);
                    case 'B'
                        constraints(i) = sum_dupl(i) == f(col,4) / f(col,2) * F(col);
                end
            end
        end
    end

    sum_mix=optimexpr(sum([columnio{:,6}]>1));
    t=1;
    for i=1:column_num
        if columnio{i,6}>1
            for j=1:length(var2mix)
                if var2mix(j)==columnio{i,1}
                    sum_mix(t)=sum_mix(t)+C(j);
                end
            end
            constraints(duplength+t) = F(i)==sum_mix(t);
            t=t+1;
        end
    end
end

function constraints = constraintFcn2(F,y,F_min,forbidden_match)
    exf=0;
    for i = 1:column_num
        constraints(i) = F(i) - (f_tot+exf) * y(i) <= 0;
    end
    if exist('forbidden_match', 'var') && ~isempty(forbidden_match)
        sum_y = optimexpr();
        for i=1:length(forbidden_match)
            for j = 1:length(forbidden_match{i}(:))
                sum_y = sum_y + y(forbidden_match{i}(j));
            end
            constraints(column_num+i) = sum_y <= length(forbidden_match{i}(:))-1;
        end
    end
    if regression==1
        for i=1:column_num
            if F_min(i)~=0
                constraints(length(constraints)+1) = -F(i) + F_min(i) * y(i) <= 0; % min flow constraint
            end
        end
    end
end

%% Heat integration
function constraints = constraintFcn3(F,Tc,Tr,QEX,QW,QS,exheatflow)
    K1 = readmatrix([mydir, 'output.xlsx'],'Range',['G2:G',num2str(column_num+1)]);
    K2 = readmatrix([mydir, 'output.xlsx'],'Range',['H2:H',num2str(column_num+1)]);

    for i=1:column_num
        deltaT=allcol(i).TBOT-allcol(i).TTOP;
        constraints(i)= Tr(i)==Tc(i)+deltaT;
    end
    sum_QEX1=optimexpr(column_num+exheat_num);
    sum_QEX2=optimexpr(column_num+exheat_num);
    a=length(constraints);
    for i=1:column_num+exheat_num
        for j=1:column_num+exheat_num
            if i~=j
                sum_QEX1(i)=sum_QEX1(i)+QEX(i,j);
                sum_QEX2(j)=sum_QEX2(j)+QEX(i,j);
            end
        end
        if i<=column_num
            constraints(a+i)= sum_QEX1(i)+QW(i)==K1(i) * F(i) / 3600 * 10^6;
        elseif exheatflow(i-column_num).Q<0
            constraints(a+i)= sum_QEX1(i)+QW(i)==-exheatflow(i-column_num).Q;
        elseif exheatflow(i-column_num).Q>0
            constraints(a+i)= sum_QEX1(i)+QW(i)==0;
        end
    end
    a=length(constraints);
    for i=1:column_num+exheat_num
        if i<=column_num
            constraints(a+i)= sum_QEX2(i)+QS(i)==K2(i) * F(i) / 3600 * 10^6;
        elseif exheatflow(i-column_num).Q>0
            constraints(a+i)= sum_QEX2(i)+QS(i)==exheatflow(i-column_num).Q;
        elseif exheatflow(i-column_num).Q<0
            constraints(a+i)= sum_QEX2(i)+QS(i)==0;
        end  
    end
end

function constraints = constraintFcn4(y,Tc,Tr,z,QEX,mu,Tmin,exheatflow)
    cap = readmatrix([mydir, 'output.xlsx'],'Range',['I2:I',num2str(column_num+1)]);
    for i=1:column_num
        constraints(3*i-2)= Tr(i)<=400-Tmin; %TS=400
        constraints(3*i-1)= (35+Tmin)-Tc(i)<=0; %TCW=35
        constraints(3*i)= (allcol(i).TTOP-50)-Tc(i)<=0;
    end
    for i=1:column_num
        for j=1:column_num
            if i~=j
                a=length(constraints);
                constraints(a+1)= QEX(i,j)-99999*z(i,j)<=0;
                constraints(a+2)= Tr(j)+Tmin-999*(1-z(i,j))-Tc(i)<=0;
                constraints(a+3)= z(i,j)<=y(i);
                constraints(a+4)= z(i,j)<=y(j);
            end
        end
    end
    a=length(constraints);
    for i=1:column_num
        constraints(a+i)= cap(i)*(1+1*(Tc(i)-allcol(i).TTOP)/allcol(i).TTOP)-2e9*(1-y(i))<=mu(i);
    end
    if exheat_num~=0
        for i=1:column_num+exheat_num
            for j=1:column_num+exheat_num
                if i~=j
                    if i>column_num && j<=column_num
                        if exheatflow(i-column_num).Q<0
                            constraints(length(constraints)+1)= QEX(i,j)-99999*z(i,j)<=0;
                            constraints(length(constraints)+1)= Tr(j)+Tmin-999*(1-z(i,j))-exheatflow(i-column_num).To<=0;
                        end
                    elseif i<=column_num && j>column_num
                        if exheatflow(j-column_num).Q>0
                            constraints(length(constraints)+1)= QEX(i,j)-99999*z(i,j)<=0;
                            constraints(length(constraints)+1)= exheatflow(j-column_num).To+Tmin-999*(1-z(i,j))-Tc(i)<=0;
                        end
                    elseif i>column_num && j>column_num
                        if exheatflow(i-column_num).Q<0 && exheatflow(j-column_num).Q>0
                            constraints(length(constraints)+1)= QEX(i,j)-99999*z(i,j)<=0;
                            constraints(length(constraints)+1)= exheatflow(j-column_num).To+Tmin-999*(1-z(i,j))-exheatflow(i-column_num).To<=0;
                        end
                    end
                end
            end
        end
    end
end
end

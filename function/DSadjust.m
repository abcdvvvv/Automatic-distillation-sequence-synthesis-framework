function DSadjust(allcol,gen_rule,colpressure,TCMX,PBUB,PDEW)
global aspen column_num AF columnio
block = aspen.Tree.FindNode('\Data\Blocks');
disp('【Adjust DSTWU DS】')

%% Adjust column pressure
if colpressure
skip=zeros(column_num,1);
cost1=zeros(column_num,1);
cost2=zeros(column_num,1);
for i=1:column_num
    if allcol(i).PTOP == gen_rule{1}(1).P && columnio{i,7}==0
        P(i)=gen_rule{1}(1).P;
        if PBUB(i)>P(i)
            cost1(i)=sum(fOPEX(allcol,i))+sum(fCAPEX(allcol,i))*AF;
            if PBUB(i)<14.8
                % fprintf('  set pressure to %.2f bar\n',PBUB(i));
                P(i)=PBUB(i);
            else
                fprintf('  use parital condenser\n');
                block.FindNode(['T',num2str(i),'\Input\OPT_RDV']).value = 'VAPOR';
                if PDEW(i)<25.2
                    % fprintf('  set pressure to %.2f bar\n',PDEW(i));
                    P(i)=PDEW(i);
                else
                    fprintf(['Pressure exceeds 2.52MPa, please consider using refrigerant. ' ...
                        'Pressure is set to 2.86MPa.\n']);
                    P(i)=28.6;
                end
            end
            if P(i)<1
                fprintf('  reset pressure to 1 bar\n');
                P(i)=1;
            end
        end
    else
        P(i)=allcol(i).PTOP;
        skip(i)=1;
    end
end
[T_cond,T_reb]=temp(P,1:column_num);
allcol = readcolumn();
cost2(skip==0)=fOPEX(allcol,find(skip==0))+fCAPEX(allcol,find(skip==0))*AF;
fprintf('T%d ',find(cost2>cost1));
fprintf('have a higher TAC after changing pressure, back to the original pressure=%.1f bar',gen_rule{1}(1).P);
P(cost2>cost1)=gen_rule{1}(1).P;
skip(cost2>cost1)=1;

for i=1:column_num
    if skip(i)==0 && columnio{i,7}==0
        if T_reb(i)>350 || T_reb(i)>TCMX(i)
            fprintf(['Bottom temperature exceeds the decomposition temperature 350°C or ' ...
                'critical temperature %.0f°C.\n'],TCMX(i));
            while T_reb(i)>350 || T_reb(i)>TCMX(i)
                P(i)=P(i)-0.1;
                [T_cond(i),T_reb(i)]=temp(P(i),i);
            end
            if P(i)<1
                if T_cond(i)>=40
                    fprintf('Using vacuum operation, P=%.2f bar\n',P(i));
                else 
                    fprintf(['Vacuum column with top temperature less than 40°C, extraction or ' ...
                        'absorption is recommended instead of distillation,\n']);
                    fprintf('Reset pressure to default value %.2f .\n',gen_rule{1}(1).P);
                    P(i)=gen_rule{1}(1).P;
                    temp(P(i),i);
                end
            end
        end
        fprintf('T%d final pressure=%.2f\n',i,P(i));
    end
end
end

%% Adjust design specifications
t=1;
debug=0;
while 1
    for i=1:column_num
        if block.FindNode(['T',num2str(i),'\Output\ACT_STAGES']).value>99 && ...
           block.FindNode(['T',num2str(i),'\Output\MIN_STAGES']).value>=80
            block.FindNode(['T',num2str(i),'\Input\RECOVL']).value=1-0.005*t;
            block.FindNode(['T',num2str(i),'\Input\RECOVH']).value=0.005*t;
            fprintf('(%d)change T%d''s recovery rate %.3f\n',t,i,1-0.005*t);
        else
            debug=debug+1;
        end
    end
    if debug==column_num
        break;
    else
        a=run();
        if a
            error('error encountered in %dth adjustment, check plz.',t);
        end
        debug=0;
        t=t+1;
        if t>10
            error('failed to adjust within 10 turns.');
        end
    end
end
end

%% subfunctions
function [t1,t2]=temp(p,r)
global aspen columnio
block = aspen.Tree.FindNode('\Data\Blocks');
for i=1:length(p)
    fprintf('T%dP=%.2f\n',r(i),p(i));
    if columnio{i,7}~=0, continue, end
    try
        block.FindNode(['T',num2str(r(i)),'\Input\PBOT']).value = p(i)+0.2;
        block.FindNode(['T',num2str(r(i)),'\Input\PTOP']).value = p(i);
    catch
        block.FindNode(['T',num2str(r(i)),'\Input\PTOP']).value = p(i);
        block.FindNode(['T',num2str(r(i)),'\Input\PBOT']).value = p(i)+0.2;
    end
end
aspen.Reinit;
pause(1);
a=run();
for i=1:length(p)
    if columnio{i,7}~=0, continue, end
    t1(i)=block.FindNode(['T',num2str(r(i)),'\Output\DISTIL_TEMP']).value;
    t2(i)=block.FindNode(['T',num2str(r(i)),'\Output\BOTTOM_TEMP']).value;
end
end
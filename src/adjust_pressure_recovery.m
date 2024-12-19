function adjust_pressure_recovery(allcol,gen_rule,colpressure)
global aspen column_num columnio
block = aspen.Tree.FindNode('\Data\Blocks');
stream = aspen.Tree.FindNode('\Data\Streams\');
TCMX = nan(column_num,1);
PBUB = nan(column_num,1);
PDEW = nan(column_num,1);
disp("[Adjust DSTWU DS]")

%% Adjust column pressure
if colpressure
    skip = zeros(column_num,1);
    % cost1 = zeros(column_num,1);
    % cost2 = zeros(column_num,1);
    for i = 1:column_num
        % critical temperature
        TCMX(i) = stream.FindNode([columnio{i,4},'\Output\STRM_UPP\TCMX\MIXED\TOTAL']).value+273.15;
        % Saturated liquid pressure for a stream at 45°C
        PBUB(i) = stream.FindNode([columnio{i,3},'\Output\STRM_UPP\PBUB\MIXED\TOTAL']).Element.Item(0).value;
        % Saturated vapor pressure for a stream at 45°C
        PDEW(i) = stream.FindNode([columnio{i,3},'\Output\STRM_UPP\PDEW\MIXED\TOTAL']).Element.Item(0).value;
        
        if columnio{i,7} == 0 % allcol(i).PTOP == gen_rule{1}(1).P
            % Modify if the pressure is equal to the default pressure and is not an extractive distillation column.
            P(i) = gen_rule{1}(1).P;
            if PBUB(i) > P(i) % If the 45°C bubble point pressure is greater than the current pressure
                % cost1(i) = sum(fOPEX(allcol,i))+sum(fCAPEX(allcol,i))*AF;
                % fprintf('T%d TAC=%.3e before optimize p',i,cost1);
                if PBUB(i) < 14.8*1e5
                    P(i) = PBUB(i);
                else
                    fprintf('  use parital condenser\n')
                    block.FindNode(['T',num2str(i),'\Input\OPT_RDV']).value = 'VAPOR';
                    if PDEW(i) < 25.2*1e5
                        P(i) = PDEW(i);
                    else
                        fprintf(['Pressure exceeds 2.52MPa, please consider using refrigerant. ' ...
                            'Pressure is set to 2.86MPa.\n'])
                        P(i) = 28.6*1e5;
                    end
                end
                if P(i) < 1*1e5
                    fprintf('  reset pressure to 1 bar\n')
                    P(i) = 1*1e5;
                end
            end
        else
            P(i) = allcol(i).PTOP;
            skip(i) = 1;
        end
    end
    [T_cond,T_reb] = temp(P,1:column_num);
    % allcol = get_column_results(allcol);
    % cost2(cost1>0) = fOPEX(allcol,find(cost1>0))+(fCAPEX(allcol,find(cost1>0))*AF)';
    % fprintf('C%d ',find(cost2 > cost1))
    % fprintf('have a higher TAC after changing pressure, back to the original pressure=%.1f bar\n',gen_rule{1}(1).P)
    % P(cost2 > cost1) = gen_rule{1}(1).P;
    % [T_cond,T_reb] = temp(P,1:column_num);
    % skip(cost2 > cost1) = 1;

    for i = 1:column_num
        if skip(i) == 0 && columnio{i,7} == 0
            if T_reb(i) > 290+273.15 || T_reb(i) > TCMX(i)
                fprintf(['Bottom temperature exceeds the 8 Mpa steam (290°C)\n' ...
                    'or critical temperature (%.0f°C).\n'],TCMX(i))
                aspen.Reinit;
                pause(0.5)
                while T_reb(i) > 290+273.15 || T_reb(i) > TCMX(i)
                    P(i) = P(i)-0.1*1e5;
                    [T_cond(i),T_reb(i)] = temp(P(i),i);
                end
                if P(i) < 1*1e5
                    if T_cond(i) >= 40+273.15
                        fprintf('Using vacuum operation, P = %.2f bar\n',P(i)/1e5)
                    else
                        fprintf(['Vacuum column with top temperature less than 40°C, ' ...
                            'extraction or absorption is recommended instead of distillation,\n'])
                        fprintf('Reset pressure to default value %.2f .\n',gen_rule{1}(1).P/1e5)
                        P(i) = gen_rule{1}(1).P;
                        temp(P(i),i);
                    end
                end
            end
            fprintf("C%d final pressure = %.2f bar\n",i,P(i)/1e5)
        end
    end
end

%% Adjust design specifications
t = 1;
debug = 0;
while 1
    for i = 1:column_num
        % block.FindNode(['T',num2str(i),'\Output\MIN_REFLUX']).value
        % block.FindNode(['T',num2str(i),'\Output\ACT_REFLUX']).value
        if columnio{i,7} ~= 0
            debug = debug+1;
            continue
        end
        if block.FindNode(['T',num2str(i),'\Output\ACT_STAGES']).value > 99 && ...
                block.FindNode(['T',num2str(i),'\Output\MIN_STAGES']).value >= 80
            block.FindNode(['T',num2str(i),'\Input\RECOVL']).value = 1-0.005*t;
            block.FindNode(['T',num2str(i),'\Input\RECOVH']).value = 0.005*t;
            fprintf('(%d)change T%d''s recovery rate to %.3f\n',t,i,1-0.005*t)
        else
            debug = debug+1;
        end
    end
    if debug == column_num
        break
    else
        a = run2();
        if a
            fprintf('Error encountered in %dth adjustment, please check... Press enter to continue',t)
        end
        debug = 0;
        t = t+1;
        if t > 10
            error('Failed to adjust within 10 turns.')
        end
    end
end
end

%% Enter the column pressure and calculate the temperature at the top and bottom.
function [t1,t2] = temp(p,r)
global aspen columnio
block = aspen.Tree.FindNode('\Data\Blocks');
for i = 1:length(p)
    if isscalar(p)
        fprintf('T%dP=%.2f\n',r(i),p(i))
    end
    if columnio{r(i),7} ~= 0, continue, end
    try
        block.FindNode(['T',num2str(r(i)),'\Input\PBOT']).value = p(i)+0.2*1e5;
        block.FindNode(['T',num2str(r(i)),'\Input\PTOP']).value = p(i);
    catch
        block.FindNode(['T',num2str(r(i)),'\Input\PTOP']).value = p(i);
        block.FindNode(['T',num2str(r(i)),'\Input\PBOT']).value = p(i)+0.2*1e5;
    end
end
a = run2();
if a
    disp('Please check for errors.')
    pause()
end
for i = 1:length(p)
    if columnio{r(i),7} ~= 0, continue, end
    t1(i) = block.FindNode(['T',num2str(r(i)),'\Output\DISTIL_TEMP']).value;
    t2(i) = block.FindNode(['T',num2str(r(i)),'\Output\BOTTOM_TEMP']).value;
end
end
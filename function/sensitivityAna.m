function [x,TAC] = sensitivityAna(allcol,optim_col,output_file)
% Sensitivity Analysis
global AF
[cost_CW,cost_CHW,cost_BW,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS] = utilities();

capex = 0;
cost_cooling = 0;
cost_heating = 0;
i = 1;
while i <= length(optim_col) && optim_col(i) ~= 0
    t = optim_col(i);
    % Cooling Cost
    T_cond = allcol(t).TTOP;
    cond_duty = allcol(t).cond_duty;
    if T_cond >= 40
        cost_cooling = cost_cooling + cost_CW*cond_duty*3600*8000/1e6;
    elseif T_cond > 15 && T_cond < 40
        cost_cooling = cost_cooling + cost_CHW*cond_duty*3600*8000/1e6;
    elseif T_cond > -5 && T_cond <= 15
        cost_cooling = cost_cooling + cost_BW*cond_duty*3600*8000/1e6;
    elseif T_cond <= -5
        cost_cooling = cost_cooling + cost_BW*cond_duty*3600*8000/1e6;
        fprintf('Lack of refrigerant prices\n')
    end
    % Heating Cost
    T_reb = allcol(t).TBOT;
    reb_duty = allcol(t).reb_duty;
    multi = 1:0.1:2;
    if T_reb < 115
        cost_heating = cost_heating + cost_S*multi*reb_duty*3600*8000/1e6;
    elseif T_reb >= 115 && T_reb < 155
        cost_heating = cost_heating + cost_LPS*multi*reb_duty*3600*8000/1e6;
    elseif T_reb >= 155 && T_reb < 179
        cost_heating = cost_heating + cost_MPS*multi*reb_duty*3600*8000/1e6;
    elseif T_reb >= 179 && T_reb < 249
        cost_heating = cost_heating + cost_HPS*multi*reb_duty*3600*8000/1e6;
    elseif T_reb >= 249
        cost_heating = cost_heating + cost_SHPS*multi*reb_duty*3600*8000/1e6;
    end
    % CAPEX
    capex = capex + readmatrix(output_file,'Range',['I',num2str(t+1),':I',num2str(t+1)]);
    i = i + 1;
end
TAC = abs(cost_cooling) + cost_heating + AF*capex;

x = cost_S:0.1*cost_S:2*cost_S;
plot(x,TAC)
hold on
end
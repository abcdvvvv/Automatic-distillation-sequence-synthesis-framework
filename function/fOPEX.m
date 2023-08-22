function OPEX = fOPEX(allcol,optim_col)
[cost_CW,cost_CHW,cost_BW,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS] = utilities();

for i = 1:length(optim_col)
    t=optim_col(i);

    % Cooling Cost
    T_cond=allcol(t).TTOP;
    cond_duty=allcol(t).cond_duty;
    if T_cond>40
        price = cost_CW;
    elseif T_cond>15
        price = cost_CHW; % chilled water 5~12
    else
        price = cost_BW; % chilled brine water -15~-10
    end
    cost_cooling = price * cond_duty * 3600 * 8000 / 1e6;

    % Heating Cost
    T_reb=allcol(t).TBOT;
    reb_duty=allcol(t).reb_duty;
    if T_reb<115.21
        price = cost_S;
    elseif T_reb<153.83
        price = cost_LPS;
    elseif T_reb<179.06
        price = cost_MPS;
    elseif T_reb<248.26
        price = cost_HPS;
    else
        price = cost_SHPS;
    end
    cost_heating = price * reb_duty * 3600 * 8000 / 1e6;

    % Operating Expense
    OPEX(i) = abs(cost_cooling) + cost_heating;
end
end
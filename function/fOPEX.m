function OPEX = fOPEX(allcol,optim_col)
[cost_CW,cost_CHW,cost_BW,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS] = utilities();

for i = 1:length(optim_col)
    t=optim_col(i);
    % Cooling Cost
    T_cond=allcol(t).TTOP;
    cond_duty=allcol(t).cond_duty;
    if T_cond>43
        cost_cooling = cost_CW * cond_duty * 3600 * 8000 / 1e6;
    elseif T_cond>15
        cost_cooling = cost_CHW* cond_duty * 3600 * 8000 / 1e6;% chilled water 5~12
    else
        cost_cooling = cost_BW * cond_duty * 3600 * 8000 / 1e6;% chilled brine water -15~-10
    end

    % Heating Cost
    T_reb=allcol(t).TBOT;
    reb_duty=allcol(t).reb_duty;
    if T_reb<115.21
        cost_heating = cost_S   * reb_duty * 3600 * 8000 / 1e6;
    elseif T_reb<153.83
        cost_heating = cost_LPS * reb_duty * 3600 * 8000 / 1e6;
    elseif T_reb<179.06
        cost_heating = cost_MPS * reb_duty * 3600 * 8000 / 1e6;
    elseif T_reb<248.26
        cost_heating = cost_HPS * reb_duty * 3600 * 8000 / 1e6;
    elseif T_reb<290.01
        cost_heating = cost_SHPS* reb_duty * 3600 * 8000 / 1e6;
    else
        cost_heating = cost_S*2 * reb_duty * 3600 * 8000 / 1e6;
    end
    % Operating Expense
    OPEX(i) = abs(cost_cooling) + cost_heating;
end
end
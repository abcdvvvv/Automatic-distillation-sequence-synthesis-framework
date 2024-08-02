function OPEX = fOPEX4optim(F,allcol,QW,QS,exheat_num)
global mydir column_num
[cost_CW,cost_CHW,cost_BW,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS,~] = utilities();
if nargin<=2
    K = readmatrix([mydir,'output.xlsx'],'Range',['G2:H',num2str(column_num+1)]);
end

total_cooling = 0;
total_heating = 0;
for i = 1:column_num
    % Cooling Cost
    T_cond=allcol(i).TTOP;
    if T_cond>40
        unit_cooling=cost_CW;
    elseif T_cond>15
        unit_cooling=cost_CHW;
    elseif T_cond>-5
        unit_cooling=cost_BW;
    elseif T_cond<=-5
        unit_cooling=cost_BW;
        fprintf('Warning: Lack of refrigerant prices\n')
    end
    if nargin<=2
        total_cooling = total_cooling + unit_cooling * abs(K(i,1)) * F(i) * 8000;
    else
        total_cooling = total_cooling + unit_cooling * -QW(i) * 3600 * 8000 / 1e6;
    end

    % Heating Cost
    T_reb=allcol(i).TBOT;
    if T_reb<115.21
        unit_heating=cost_S;
    elseif T_reb<153.83
        unit_heating=cost_LPS;
    elseif T_reb<179.06
        unit_heating=cost_MPS;
    elseif T_reb<248.26
        unit_heating=cost_HPS;
    else
        unit_heating=cost_SHPS;
    end
    if nargin<=2
        total_heating = total_heating + unit_heating * K(i,2) * F(i) * 8000;
    else
        total_heating = total_heating + unit_heating * QS(i) * 3600 * 8000 / 1e6;
    end
end

if nargin>2 && exheat_num>0
    for i=1:exheat_num
        exCost(i) = (-QW(column_num+i)*cost_CW+QS(column_num+i)*cost_S) * 3600 * 8000 / 10^6;
    end
else
    exCost=0;
end

OPEX = total_cooling + total_heating + sum(exCost);
end
function OPEX = fOPEX4optim(F,optim_col)
global mydir column_num
[cost_CW,cost_CHW,cost_BW,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS] = utilities();
K1 = readmatrix([mydir,'output.xlsx'],'Range',['G2:G',num2str(column_num+1)]);
K2 = readmatrix([mydir,'output.xlsx'],'Range',['H2:H',num2str(column_num+1)]);

total_cooling = 0;
total_heating = 0;
for i = 1:column_num
    % Cooling Cost
    T_cond = optim_col.TTOP;
    if T_cond > 40
        price = cost_CW;
    elseif T_cond > 15 && T_cond <= 40
        price = cost_CHW;
    elseif T_cond > -5 && T_cond <= 15
        price = cost_BW;
    elseif T_cond <= -5
        price = cost_BW;
    end
    total_cooling = total_cooling+price*abs(K1(i))*F(i)*8000;
    % Heating Cost
    T_reb = optim_col.TBOT;
    if T_reb < 115
        price = cost_S;
    elseif T_reb >= 115 && T_reb < 155
        price = cost_LPS;
    elseif T_reb >= 155 && T_reb < 179
        price = cost_MPS;
    elseif T_reb >= 179 && T_reb < 249
        price = cost_HPS;
    elseif T_reb >= 249
        price = cost_SHPS;
    end
    total_heating = total_heating+price*K2(i)*F(i)*8000;
end
% Operating Expense
OPEX = total_cooling+total_heating;

end
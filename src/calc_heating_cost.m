function cost = calc_heating_cost(Qh,T)
[~, ~, ~,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS] = get_utility_price();
Qh = Qh/1e9; % GJ -> J
if T < 115
    cost = cost_S*Qh*3600*8000;
elseif T < 155
    cost = cost_LPS*Qh*3600*8000;
elseif T < 179
    cost = cost_MPS*Qh*3600*8000;
elseif T < 249
    cost = cost_HPS*Qh*3600*8000;
else
    cost = cost_SHPS*Qh*3600*8000;
end
end
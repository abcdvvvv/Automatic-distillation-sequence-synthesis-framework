function cost = calc_cooling_cost(Qc,T)
[cost_CW,cost_CHW,cost_BW, ~, ~, ~, ~, ~] = get_utility_price();
Qc = abs(Qc)/1e9; % GJ -> J
if T > 40
    cost = cost_CW*Qc*3600*8000;
elseif T > 15
    cost = cost_CHW*Qc*3600*8000; % chilled water 5~12
elseif T > -5
    cost = cost_BW*Qc*3600*8000; % chilled brine water -15~-10
else
    error('T=%.2f,Please define the price of the refrigerant',T)
end
end
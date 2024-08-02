function cost = QcT2cost2(Qc,T)
[cost_CW,cost_CHW,cost_BW, ~, ~, ~, ~, ~] = utilities();
Qc = abs(Qc);
if T > 40
    cost = cost_CW*Qc*3600*8000/1e6;
elseif T > 15
    cost = cost_CHW*Qc*3600*8000/1e6; % chilled water 5~12
elseif T > -5
    cost = cost_BW*Qc*3600*8000/1e6; % chilled brine water -15~-10
else
    error('T=%.2f,Please define the price of the refrigerant',T)
end
end
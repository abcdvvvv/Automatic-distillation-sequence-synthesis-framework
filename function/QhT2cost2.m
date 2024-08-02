function cost = QhT2cost2(Qh,T)
[~, ~, ~,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS] = utilities();
if T < 115
    cost = cost_S*Qh*3600*8000/1e6;
elseif T < 155
    cost = cost_LPS*Qh*3600*8000/1e6;
elseif T < 179
    cost = cost_MPS*Qh*3600*8000/1e6;
elseif T < 249
    cost = cost_HPS*Qh*3600*8000/1e6;
else
    cost = cost_SHPS*Qh*3600*8000/1e6;
end
end
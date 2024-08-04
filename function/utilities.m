function [cost_CW,cost_CHW,cost_BW,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS,cost_e] = utilities()
% Return the price of various utilities ($/GJ).
% You can set a different set of utility prices for each case
global utility_set GUIindicator app
if ~GUIindicator
    switch utility_set
        case 1
            cost_e = 0.1353; % $/kWh
            cost_CW = 5.846; % $/GJ
            cost_CHW= 45.18; % $/GJ
            cost_BW = 58.46; % $/GJ
            cost_S  = 17.41; % $/GJ
            cost_LPS = 1.10 * cost_S; % 6-bar steam,   158.83 °C
            cost_MPS = 1.16 * cost_S; % 1.1 MPa steam, 184.06 °C
            cost_HPS = 1.38 * cost_S; % 4.2 MPa steam, 253.26 °C
            cost_SHPS= 1.54 * cost_S; % 8.0 MPa steam, 295.01 °C
    end
else
    cost_e = app.PriceTable.Data{1,2};
    cost_CW = app.PriceTable.Data{2,2};
    cost_CHW= app.PriceTable.Data{3,2};
    cost_BW = app.PriceTable.Data{4,2};
    cost_S  = app.PriceTable.Data{5,2};
    cost_LPS = app.PriceTable.Data{6,2};
    cost_MPS = app.PriceTable.Data{7,2};
    cost_HPS = app.PriceTable.Data{8,2};
    cost_SHPS= app.PriceTable.Data{9,2};
end
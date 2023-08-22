function CAPEX = fCAPEX(allcol,optim_col)
Lang_F = 4.74;
ET=0.55;
Sf=1.30;
column_material_type = 0;
plate_material_type = 0;

for i = 1:length(optim_col)
    t=optim_col(i);
    T_operation = allcol(t).TBOT;
    P_operation = allcol(t).PBOT;
    NT = double(allcol(t).stage-2);
    if isempty(allcol(t).D)
        % fprintf('T%d diameter undefined, calculate as 0.8m.\n',t)
        diameter=0.8;
    else
        diameter=allcol(t).D;
    end
    if isempty(allcol(t).type) || allcol(t).type=="trayed"
        NP = round(NT / ET) + 4;
        if diameter<1
            H = NP * 0.35;
        elseif diameter>=1 && diameter<2
            H = NP * 0.45;
        elseif diameter>=2
            H = NP * 0.50;
        end
    elseif allcol(t).type=="packed"
        H = (NT * Sf + 4) * allcol(t).HETP;
    end
    cost_column = CAPEX4column(T_operation,P_operation,diameter,NT,H,column_material_type,plate_material_type);
    % Total
    CAPEX(i) = cost_column * Lang_F;
end
end
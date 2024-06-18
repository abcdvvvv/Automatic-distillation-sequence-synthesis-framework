function allcol = odata(allcol,material,output_file,DHVL)
global aspen column_num columnio
stream = aspen.Tree.FindNode('\Data\Streams\');
disp('(3) output data...')
C = 0.08;
R = 8.3144626;
Lang_F = 4.74;
column_material_type = 1;
plate_material_type = 1;
E_T = 0.55; % column efficiency for a trayed column
S_f = 1.30; % safety factor for a packed column

Column_k = [allcol.num]';
Stages = [allcol.stage]';
RR = [allcol.RR]';
Qcond_k = [allcol.cond_duty]';
Qreb_k = [allcol.reb_duty]';
feed_mole_flow = [];
Diameter = [];
for i = 1:column_num
    feed_mole_flow = [feed_mole_flow; stream.FindNode(['S',num2str(i),'\Output\MOLEFLMX\MIXED']).value];
    T_mean = (allcol(i).TTOP+allcol(i).TBOT)/2+273.15;
    n = allcol(i).reb_duty/DHVL(i); % kmol
    Vs = n*1000*R*T_mean/((allcol(i).PTOP+allcol(i).PBOT)*1e5/2); % ideal gas EOS
    rho_L = stream.FindNode([columnio{i,4},'\Output\RHOMX_MASS\MIXED']).value;
    MW = stream.FindNode([columnio{i,4},'\Output\MW']).value; % molecular weight
    rho_V = MW/22.4;
    u_max = C*sqrt((rho_L-rho_V)/rho_V);
    u = floor(u_max*10)/10;
    Diameter(i,1) = sqrt(4*Vs/(pi*u));
    allcol(i).D = Diameter(i,1);
    % Calculate the capital cost of distillation columns
    NT = double(allcol(i).stage-2);
    NP = round(NT/E_T)+4;
    if allcol(i).D < 1
        H = NP*0.35;
    elseif allcol(i).D < 2
        H = NP*0.45;
    else
        H = NP*0.50;
    end
    allcol(i).Cap = Lang_F*CAPEX4column(allcol(i).TBOT,allcol(i).PBOT,allcol(i).D,NT,H,column_material_type,plate_material_type);
    % Calculate utility costs
    allcol(i).Cut = QcT2cost2(allcol(i).cond_duty,allcol(i).TTOP)+QhT2cost2(allcol(i).reb_duty,allcol(i).TBOT);
end
cost_table = table(Column_k,Stages,RR,Qcond_k,Qreb_k,Diameter);
cost_table.K_cond = cost_table.Qcond_k./(feed_mole_flow./3600)./1e6;% K heat duty coefficients,GJ/kmol
cost_table.K_reb = cost_table.Qreb_k./(feed_mole_flow./3600)./1e6;
cost_table.Cap = [allcol.Cap]';
cost_table.Cut = [allcol.Cut]';
writetable(cost_table,output_file);
disp('Done.')
end

%%
function cost = QhT2cost2(Qh,T)
[~,~,~,cost_S,cost_LPS,cost_MPS,cost_HPS,cost_SHPS,~] = utilities();
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

function cost = QcT2cost2(Qc,T)
[cost_CW,cost_CHW,cost_BW,~,~,~,~,~,~] = utilities();
Qc = abs(Qc);
if T > 40
    cost = cost_CW*Qc*3600*8000/1e6;
elseif T > 15
    cost = cost_CHW*Qc*3600*8000/1e6;
else
    cost = cost_BW*Qc*3600*8000/1e6;
end
end
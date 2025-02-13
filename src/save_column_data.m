function allcol = save_column_data(allcol,material,output_file,DHVL)
global aspen column_num columnio
stream = aspen.Tree.FindNode('\Data\Streams\');
disp("(3) output data...")
C = 0.08; % load factor, m/s
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
    % for j=1:length(columnio{i,5})
    %     if length(columnio{i,5})==4 && j==3
    %         septask(i,j)=char(64+material(str2double(strcat(columnio{i,5}(j),columnio{i,5}(j+1)))+str2double(columnio{i,5}(1))-1).sep);
    %         break;
    %     elseif j==3
    %         septask(i,j)=char(64+material(str2double(columnio{i,5}(j))+str2double(columnio{i,5}(1))-1).sep);
    %     else
    %         septask(i,j)=char(64+material(str2double(columnio{i,5}(j))).sep);
    %     end
    % end % This generated "septask" is used to manually read and add in excel
    % kmol/s
    feed_mole_flow = [feed_mole_flow; stream.FindNode(['S',num2str(i),'\Output\MOLEFLMX\MIXED']).value]; %#ok<*AGROW>
    T_mean = (allcol(i).TTOP + allcol(i).TBOT)/2+273.15; % K
    n = allcol(i).reb_duty/DHVL(i); % J/s / J/kmol = kmol/s
    % n=n/columnio{i,6};
    Vs = n*1000*R*T_mean/((allcol(i).PTOP + allcol(i).PBOT)/2); % ideal gas EOS
    rho_L = stream.FindNode([columnio{i,4},'\Output\RHOMX_MASS\MIXED']).value*1000; % g/m^3
    MW = stream.FindNode([columnio{i,4},'\Output\MW']).value; % molecular weight
    rho_V = MW/(22.4*1e-3); % g/mol / m^3/mol = g/m^3
    u_max = C*sqrt((rho_L - rho_V)/rho_V);
    u = floor(u_max*10)/10;
    Diameter(i,1) = sqrt(4*Vs/(pi*u)); % m
    allcol(i).D = Diameter(i,1);
    % Calculate the capital cost of distillation columns
    NT = double(allcol(i).stage-2);
    NP = round(NT/E_T) + 4;
    if allcol(i).D < 1
        H = NP*0.35;
    elseif allcol(i).D < 2
        H = NP*0.45;
    else
        H = NP*0.50;
    end
    % Calculate capital and utility costs
    allcol(i).Cap = Lang_F*calc_capex_column(allcol(i).TBOT,allcol(i).PBOT,allcol(i).D,NT,H,column_material_type,plate_material_type);
    allcol(i).Cut = calc_cooling_cost(allcol(i).cond_duty,allcol(i).TTOP) + calc_heating_cost(allcol(i).reb_duty,allcol(i).TBOT);
end

cost_table = table(Column_k,Stages,RR,Qcond_k,Qreb_k,Diameter);
cost_table.K_cond = cost_table.Qcond_k./feed_mole_flow./1e9; % K heat duty coefficients, GJ/mol
cost_table.K_reb = cost_table.Qreb_k./feed_mole_flow./1e9;
cost_table.Cap = [allcol.Cap]';
cost_table.Cut = [allcol.Cut]';
writetable(cost_table,output_file);
disp("Done.")
end
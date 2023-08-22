function odata(optim_col,~,DHVL,output_file)
global aspen column_num columnio
stream = aspen.Tree.FindNode('\Data\Streams\');
disp('(3)output data...')
C=0.08;
R=8.3144626;

column_name = [optim_col.num]';
stages = [optim_col.stage]';
RR = [optim_col.RR]';
cond_duty = [optim_col.cond_duty]';
reb_duty = [optim_col.reb_duty]';
feed_mole_flow = [];
D=[];
for i = 1:column_num
    feed_mole_flow = [feed_mole_flow; stream.FindNode(['S',num2str(i),'\Output\MOLEFLMX\MIXED']).value];
    T_mean=(optim_col(i).TTOP+optim_col(i).TBOT)/2;
    n=optim_col(i).reb_duty/DHVL(i); % kmol
    Vs=n*1000*R*(T_mean+273.15)/((optim_col(i).PTOP+optim_col(i).PBOT)*10^5/2);
    rho_L=stream.FindNode([columnio{i,4},'\Output\RHOMX_MASS\MIXED']).value;
    MW=stream.FindNode([columnio{i,4},'\Output\MW']).value;
    rho_V=MW/22.4;
    u_max=C*sqrt((rho_L-rho_V)/rho_V);
    u=floor(u_max*10)/10;
    D=[D;sqrt(4*Vs/(pi*u))]; % m
end
cost_table = table(column_name, stages, RR, cond_duty, reb_duty, D);
cost_table.K_cond = cost_table.cond_duty ./ (feed_mole_flow ./ 3600) ./ 1e6;% K heat duty coefficients,GJ/kmol
cost_table.K_reb = cost_table.reb_duty ./ (feed_mole_flow ./ 3600) ./ 1e6;
writetable(cost_table,output_file);
end
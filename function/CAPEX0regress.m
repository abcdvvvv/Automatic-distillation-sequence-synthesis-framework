function [CAPEX,F_min]=CAPEX0regress(optim_col,F,y,streamf,DHVL)
global mydir aspen column_num columnio
fprintf('Regression ...\n')
stream = aspen.Tree.FindNode('\Data\Streams\');
output_file=[mydir,'output.xlsx'];
K2 = readmatrix(output_file,'Range',['H2:H',num2str(column_num+1)]);
writematrix('Capital cost',output_file,'Range','I1');

C=0.08;
R=8.3144626;
Lang_F = 4.74;
column_material_type = 1;
plate_material_type = 1;
E_T=0.55;
if streamf(1)<300
    D_lower_bound=0.51;
else
    D_lower_bound=0.36;
end
CAPEX = 0;

for i=1:column_num
    T_operation = optim_col(i).TBOT; % °C 
    P_operation = optim_col(i).PBOT; % bar
    T_mean=(optim_col(i).TTOP+optim_col(i).TBOT)/2;
    
    rho_L=stream.FindNode([columnio{i,4},'\Output\RHOMX_MASS\MIXED']).value;
    MW=stream.FindNode([columnio{i,4},'\Output\MW']).value;
    rho_V=MW/22.4;
    u_max=C*sqrt((rho_L-rho_V)/rho_V);
    u=floor(u_max*10)/10;
    stages = double(optim_col(i).stage-2);
    actual_stages = round(stages / E_T);

    Vs=D_lower_bound^2*pi*u/4;
    n=Vs*((optim_col(i).PTOP+optim_col(i).PBOT)*10^5/2)/(1000*R*(T_mean+273.15));
    F_min(i)=n*DHVL(i)*3600/(K2(i)*10^6);

    success=0;
    while F_min(i)<0.5*streamf(i) && ~success
        F_temp=linspace(F_min(i),streamf(i),20);
        n=K2(i)*10^6*(F_temp/3600)/DHVL(i); % kmol/s
        Vs=n*1000*R*(T_mean+273.15)/((optim_col(i).PTOP+optim_col(i).PBOT)*10^5/2); % ideal gas
        D = sqrt(4*Vs/(pi*u)); % diameter, m
        for j=1:length(D)
            interval=0.0543*D(j)+0.3283;
            L = actual_stages * interval;
            cost = CAPEX4column(T_operation,P_operation,D(j),stages,L,column_material_type,plate_material_type);
            CAPEX_temp(j) = cost * Lang_F; % $
        end
        m=LinearModel.fit(F_temp,CAPEX_temp);
        %--------------------------------------
        % if i==1
        %     figure
        % end
        % subplot(4,5,i)
        % m.plot
        % title(['T',num2str(i),' R-square=',num2str(m.Rsquared.Ordinary,'%.3f')])
        % ylabel('CAPEX (USD)')
        % xlabel('feed flow rate (kmol/h)')
        % legend('Data','Fit','Confidence boundary')
        % disp(m)
        %--------------------------------------
        if m.Rsquared.Ordinary<0.95
            F_min(i)=F_min(i)+5;
        else
            b=m.Coefficients.Estimate(1);
            k=m.Coefficients.Estimate(2);
            CAPEX = CAPEX + b*y(i)+k*F(i);
            success=1;
            %--------------------------------------
            % plot(F,k*F+b)
            % subplot(3,3,i)
            % plot(F,CAPEX)
            % box off
            %--------------------------------------
        end
    end

    if success==0
        fprintf('give up T%d\n',i)
        F_min(i)=0;
        D=readmatrix(output_file,'Range',['F',num2str(i+1),':F',num2str(i+1)]);
        if D<1
            L = actual_stages * 0.35;
        elseif D>=1 && D<2
            L = actual_stages * 0.45;
        elseif D>=2
            L = actual_stages * 0.50;
        end
        cost = CAPEX4column(T_operation,P_operation,D,stages,L,column_material_type,plate_material_type);
        CAPEX = CAPEX + cost * Lang_F * y(i); % $
        writematrix(cost*Lang_F,output_file,'Range',['I',num2str(i+1)]);
    end
end
end
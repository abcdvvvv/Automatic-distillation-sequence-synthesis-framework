function CAPEX = CAPEX4optim(allcol,y)
global mydir column_num
Lang_F = 4.74;
column_material_type = 1;
plate_material_type = 1;
E_T=0.55;
output_file=[mydir,'output.xlsx'];

CAPEX = 0;
writematrix('Capital cost',output_file,'Range','I1');
D=readmatrix(output_file,'Range',['F2:F',num2str(column_num+1)]);
for i = 1:column_num
    T_operation = allcol(i).TBOT; % °C 
    P_operation = allcol(i).PBOT; % bar
    stages = double(allcol(i).stage-2);
    actual_stages = round(stages / E_T);
    if D(i)<1
        L = actual_stages * 0.35; % plate spacing
    elseif D(i)>=1 && D(i)<2
        L = actual_stages * 0.45;
    elseif D(i)>=2
        L = actual_stages * 0.50;
    end
    cost = CAPEX4column(T_operation,P_operation,D(i),stages,L,column_material_type,plate_material_type);
    CAPEX = CAPEX + cost * Lang_F * y(i); % $
    writematrix(cost*Lang_F,output_file,'Range',['I',num2str(i+1)]);
end

end
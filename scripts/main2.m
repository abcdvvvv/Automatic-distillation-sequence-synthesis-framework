%{
==========================================================================
Automatic distillation sequence synthesis framework                     
- based on the preorder traversal algorithm                             
Version 1.1.1 Updated 2024/8/2                                                      
Note:                                                                   
1.Regression cannot be used together with heat integration              
This software is open source under the GNU General Public License v3.0. 
Copyright (C) 2024  abcdvvvv                                            
==========================================================================
%}

%% Create a new file to deploy the optimal separation sequence
global AF mydir aspen columnio column_num
if ~exist("optim_col","var")
    load([mydir,'case1.mat']);
end
column_numop = material(end).sep-1;
for d = 1:1 % d=deploy
    filename3 = ['base_optim',num2str(d),'.bkp'];
    copyfile([pwd,'\Simulation file\baseFile\',basefile],[mydir,filename3],'f');
    fprintf('Deploy optimized PFD %d\n',d)
    evoke(mydir,filename3);
    % add_utility();
    columnio = {}; % col1 tower number, col2 inlet stream, col3 top stream, col4 bottom stream
    set_optimal_sequence(material,optim_col(d,:),allcol,feedstream);
    
    % Add design specifications and column internals
    set_design_spec(column_numop,allcol,optim_col(d,:));
    opex = fOPEX(allcol,optim_col(d,:));
    capex = fCAPEX(allcol,optim_col(d,:));
    if exist(output_file,"file")
        for j = 1:length(optim_col(1,:))
            t = optim_col(d,j);
            writematrix(capex(j),output_file,'Range',[char(73+2*d),num2str(t+1)]);
        end
    end
    total = sum(opex)+AF*sum(capex);
    fprintf('sum=%d\n',total);
    writematrix(total,output_file,'Range',[char(73+2*d),num2str(column_num+3)]);

    aspen.Save;
    disp('deployment finished.')
    % CO2 emissions
    % aspen.Tree.FindNode("\Data\Results Summary\Utility-Sum\Output\UTILCO2E").value;%公用工程CO2e
    % aspen.Tree.FindNode("\Data\Results Summary\Utility-Sum\Output\TOTCO2E").value;%全厂CO2e
end

%% Single column optimization
de=input('Perform column optimization?(y/n)','s');
if de == 'y'
    % col_optimize(filename3,allcol,optim_col);
    qmin2factor(allcol,optim_col(d,:));
    disp('Column optimization finished.')
else
    disp('Skip column optimization.')
end
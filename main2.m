%% Create a new file to deploy the optimal separation sequence
global AF mydir aspen columnio column_num
if ~exist("optim_col","var")
    load([mydir,'case1.mat']);
end
column_numop = material(end).sep-1;
for d = 1:1 % d=deploy
    pause(3)
    filename3 = ['base_optim',num2str(d),'.bkp'];
    copyfile([pwd,'\Simulation_file\baseFile\',basefile],[mydir,filename3],'f');
    fprintf('Deploy optimized PFD %d\n',d);
    evoke(mydir,filename3);
    block = aspen.Tree.FindNode('\Data\Blocks\');
    stream = aspen.Tree.FindNode('\Data\Streams\');
    addutility();
    columnio = {};
    col_deploy(material,optim_col(d,:),allcol,feedstream);
    % Add design specifications
    addDS(column_numop,allcol,optim_col(d,:));
    disp('【Add column internals】');
    for j = 1:column_numop
        t = optim_col(d,j);
        name = ['T',num2str(t)];
        block.FindNode([name,'\Subobjects\Column Internals']).Elements.Add('INT-1');
        block.FindNode([name,'\Subobjects\Column Internals\INT-1\Subobjects\Sections']).Elements.Add('CS-1');
        block.FindNode([name,'\Subobjects\Column Internals\INT-1\Input\CA_STAGE1\INT-1\CS-1']).value = 2;
        block.FindNode([name,'\Subobjects\Column Internals\INT-1\Input\CA_STAGE2\INT-1\CS-1']).value = allcol(t).stage-1;
    end
    a = run();
    if a
        disp('Radfrac has errors, please adjust manually... Please keep the run completed')
        pause()
        % fixerror();
    end
    allcol = readcolumn(allcol,optim_col(d,:));
    for j = 1:column_numop
        t = optim_col(d,j);
        INT = block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Input']);
        if allcol(t).D <= 0
            allcol(t).type = "packed";
            INT.FindNode('CA_INTERNAL\INT-1\CS-1').value = 'PACKING';
            INT.FindNode('CA_PACKTYPE\INT-1\CS-1').value = 'MELLAPAK';
            INT.FindNode('CA_PACK_SIZE\INT-1\CS-1').value = '250Y';
            INT.FindNode('OPT_CA_HETP\INT-1\CS-1').value = 'HETP';
            allcol(t).HETP = round(allcol(t).D*1.2,2);
            INT.FindNode('CA_HETP\INT-1\CS-1').value = allcol(t).HETP;
        else
            allcol(t).type = "trayed";
            INT.FindNode('CA_INTERNAL\INT-1\CS-1').value = 'TRAY';
        end
    end
    aspen.Reinit;
    run();
    for j = 1:column_numop
        t = optim_col(d,j);
        INT = block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Output']);
        if allcol(t).type == "trayed"
            allcol(t).D = INT.FindNode('CA_DIAM6\INT-1\CS-1').value;
        elseif allcol(t).type == "packed"
            allcol(t).D = block.FindNode('CA_DIAM2\INT-1\CS-1').value;
        else
            error('undefined tray type T%d',t);
        end
    end
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
end

%% Single column optimization
if col_optim == 0
    qmin2factor(allcol,optim_col(d,:));
    disp('Column optimization finished.')
else
    disp('Skip column optimization.')
end
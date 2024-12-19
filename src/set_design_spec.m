function set_design_spec(column_numop, allcol, optim_col)
global aspen columnio
block = aspen.Tree.FindNode('\Data\Blocks');
disp('[Add Radfrac Design Specifications]')

for i = 1:column_numop
    t = optim_col(i); % t is the real col number to be deployed
    % design specification
    block.FindNode(['T',num2str(t),'\Subobjects\Design Specs']).Elements.Add('1');
    dsnode = block.FindNode(['T',num2str(t),'\Subobjects\Design Specs\1\Input']);
    dsnode.FindNode('SPEC_TYPE\1').value = 'MOLE-RECOV';
    dsnode.FindNode('VALUE\1').value = allcol(t).recovl;
    dsnode.FindNode('SPEC_COMPS\1').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_COMPS\1\#0').value = allcol(t).lightkey;
    dsnode.FindNode('SPEC_STREAMS\1\').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_STREAMS\1\#0').value = columnio{i,3};

    block.FindNode(['T',num2str(t),'\Subobjects\Design Specs']).Elements.Add('2');
    dsnode = block.FindNode(['T',num2str(t),'\Subobjects\Design Specs\2\Input']);
    dsnode.FindNode('SPEC_TYPE\2').value = 'MOLE-RECOV';
    dsnode.FindNode('VALUE\2').value = allcol(t).recovh;
    dsnode.FindNode('SPEC_COMPS\2').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_COMPS\2\#0').value = allcol(t).heavykey;
    dsnode.FindNode('SPEC_STREAMS\2').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_STREAMS\2\#0').value = columnio{i,3};
    % vary
    block.FindNode(['T',num2str(t),'\Subobjects\Vary']).Elements.Add('1');
    vanode = block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input']);
    vanode.FindNode('VARTYPE\1').value = 'RR';
    vanode.FindNode('LB\1').value = round(allcol(t).RR*0.8,2);
    vanode.FindNode('UB\1').value = round(allcol(t).RR*5,2);

    block.FindNode(['T',num2str(t),'\Subobjects\Vary']).Elements.Add('2');
    vanode = block.FindNode(['T',num2str(t),'\Subobjects\Vary\2\Input']);
    vanode.FindNode('VARTYPE\2').value = 'D:F';
    vanode.FindNode('LB\2').value = round(allcol(t).D_F*0.9,4);
    if allcol(t).D_F*1.2 < 1
        vanode.FindNode('UB\2').value = round(allcol(t).D_F*1.1,4);
    else
        vanode.FindNode('UB\2').value = 1;
    end
end

disp('[Add column internals]')
for j = 1:column_numop
    t = optim_col(j);
    name = ['T',num2str(t)];
    block.FindNode([name,'\Subobjects\Column Internals']).Elements.Add('INT-1');
    block.FindNode([name,'\Subobjects\Column Internals\INT-1\Subobjects\Sections']).Elements.Add('CS-1');
    block.FindNode([name,'\Subobjects\Column Internals\INT-1\Input\CA_STAGE1\INT-1\CS-1']).value = 2;
    block.FindNode([name,'\Subobjects\Column Internals\INT-1\Input\CA_STAGE2\INT-1\CS-1']).value = allcol(t).stage - 1;
end

a = run();
if a
    disp('Radfrac has errors, please adjust manually... Please keep the run completed')
    pause()
    % fix_error();
end

allcol = get_column_results(allcol,optim_col);
for j = 1:column_numop
    t = optim_col(j);
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
    t = optim_col(j);
    INT = block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Output']);
    if allcol(t).type == "trayed"
        allcol(t).D = INT.FindNode('CA_DIAM6\INT-1\CS-1').value;
    elseif allcol(t).type == "packed"
        allcol(t).D = block.FindNode('CA_DIAM2\INT-1\CS-1').value;
    else
        error('undefined tray type T%d',t)
    end
end
end
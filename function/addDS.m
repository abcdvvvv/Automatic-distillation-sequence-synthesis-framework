function addDS(column_numop,allcol,optim_col)
global aspen columnio
block = aspen.Tree.FindNode('\Data\Blocks');
disp('【添加Radfrac设计规定】');

for i=1:column_numop
    t=optim_col(i); %t是要部署的塔的真实序号
    % design specification
    block.FindNode(['T',num2str(t),'\Subobjects\Design Specs']).Elements.Add('1');
    dsnode=block.FindNode(['T',num2str(t),'\Subobjects\Design Specs\1\Input']);
    dsnode.FindNode('SPEC_TYPE\1').value='MOLE-RECOV';
    dsnode.FindNode('VALUE\1').value=allcol(t).recovl;
    dsnode.FindNode('SPEC_COMPS\1').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_COMPS\1\#0').value=allcol(t).lightkey;
    dsnode.FindNode('SPEC_STREAMS\1\').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_STREAMS\1\#0').value=columnio{i,3};

    block.FindNode(['T',num2str(t),'\Subobjects\Design Specs']).Elements.Add('2');
    dsnode=block.FindNode(['T',num2str(t),'\Subobjects\Design Specs\2\Input']);
    dsnode.FindNode('SPEC_TYPE\2').value='MOLE-RECOV';
    dsnode.FindNode('VALUE\2').value=allcol(t).recovh;
    dsnode.FindNode('SPEC_COMPS\2').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_COMPS\2\#0').value=allcol(t).heavykey;
    dsnode.FindNode('SPEC_STREAMS\2').Elements.InsertRow(0,0);
    dsnode.FindNode('SPEC_STREAMS\2\#0').value=columnio{i,3};
    % vary
    block.FindNode(['T',num2str(t),'\Subobjects\Vary']).Elements.Add('1');
    vanode=block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input']);
    vanode.FindNode('VARTYPE\1').value='RR';
    vanode.FindNode('LB\1').value=round(allcol(t).RR*0.8,2);
    vanode.FindNode('UB\1').value=round(allcol(t).RR*5,2);

    block.FindNode(['T',num2str(t),'\Subobjects\Vary']).Elements.Add('2');
    vanode=block.FindNode(['T',num2str(t),'\Subobjects\Vary\2\Input']);
    vanode.FindNode('VARTYPE\2').value='D:F';
    vanode.FindNode('LB\2').value=round(allcol(t).D_F*0.9,4);
    if allcol(t).D_F*1.2<1
        vanode.FindNode('UB\2').value=round(allcol(t).D_F*1.1,4);
    else
        vanode.FindNode('UB\2').value=1;
    end
end

end
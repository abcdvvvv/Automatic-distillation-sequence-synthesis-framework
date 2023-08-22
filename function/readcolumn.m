function allcol = readcolumn(allcol,optim_col)
global aspen column_num
block = aspen.Tree.FindNode('\Data\Blocks');
if ~exist("allcol","var")
    allcol = struct('num',{},'PTOP',{},'PBOT',{},'TTOP',{},'TBOT',{},'lightkey',{},'recovl',{},'heavykey',{},'recovh',{}, ...
    'RR',{},'D_F',{},'minstage',{},'stage',{},'fstage',{},'cond_duty',{},'reb_duty',{},'D',{},'type',{},'HETP',{},'cond_type',{});
    for i = 1:column_num    
        allcol(i).num = i;
        allcol(i).PTOP = block.FindNode(['T',num2str(i),'\Input\PTOP']).value;
        allcol(i).TTOP = block.FindNode(['T',num2str(i),'\Output\DISTIL_TEMP']).value;
        allcol(i).cond_duty = block.FindNode(['T', num2str(i), '\Output\COND_DUTY']).value;
        allcol(i).PBOT = block.FindNode(['T',num2str(i),'\Input\PBOT']).value;
        allcol(i).TBOT = block.FindNode(['T',num2str(i),'\Output\BOTTOM_TEMP']).value;
        allcol(i).reb_duty = block.FindNode(['T', num2str(i), '\Output\REB_DUTY']).value;

        allcol(i).lightkey = block.FindNode(['T',num2str(i),'\Input\LIGHTKEY']).value;
        allcol(i).recovl = block.FindNode(['T',num2str(i),'\Input\RECOVL']).value;
        allcol(i).heavykey = block.FindNode(['T',num2str(i),'\Input\HEAVYKEY']).value;
        allcol(i).recovh = block.FindNode(['T',num2str(i),'\Input\RECOVH']).value;

        allcol(i).RR = block.FindNode(['T',num2str(i),'\Output\ACT_REFLUX']).value;
        allcol(i).D_F = block.FindNode(['T',num2str(i),'\Output\DIST_VS_FEED']).value;
        allcol(i).minstage = block.FindNode(['T',num2str(i),'\Output\MIN_STAGES']).value;
        allcol(i).stage = block.FindNode(['T',num2str(i),'\Output\ACT_STAGES']).value;
        allcol(i).fstage = block.FindNode(['T',num2str(i),'\Output\FEED_LOCATN']).value;
        if strcmp(block.FindNode(['T',num2str(i),'\Input\OPT_RDV']).value,'LIQUID')
            allcol(i).cond_type=0;
        elseif strcmp(block.FindNode(['T',num2str(i),'\Input\OPT_RDV']).value,'VAPOR')
            allcol(i).cond_type=1;
        end
    end
elseif isa(allcol,"struct")
    for i=1:length(optim_col)
        t=optim_col(i);
        allcol(t).PTOP=block.FindNode(['T',num2str(t),'\Output\PRES1']).value;
        allcol(t).TTOP=block.FindNode(['T',num2str(t),'\Output\TOP_TEMP']).value;
        allcol(t).cond_duty=block.FindNode(['T',num2str(t),'\Output\COND_DUTY']).value;
        allcol(t).PBOT=block.FindNode(['T',num2str(t),'\Output\REB_POUT']).value;
        allcol(t).TBOT= block.FindNode(['T',num2str(t),'\Output\REB_TOUT']).value;
        allcol(t).reb_duty=block.FindNode(['T',num2str(t),'\Output\REB_DUTY']).value;
        
        try allcol(t).D=block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Output\CA_DIAM6\INT-1\CS-1']).value; catch end
        allcol(t).stage=block.FindNode(['T',num2str(t),'\Input\NSTAGE']).value;
        allcol(t).RR=block.FindNode(['T',num2str(t),'\Output\MOLE_RR']).value;
        allcol(t).D_F=block.FindNode(['T',num2str(t),'\Output\MOLE_DFR']).value;
    end
end
end
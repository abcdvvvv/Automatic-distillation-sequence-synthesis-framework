function fixerror()
global aspen mydir
disp('【Adjust the ERROR model】');
block = aspen.Tree.FindNode('\Data\Blocks\');
DS = aspen.Tree.FindNode('\Data\Flowsheeting Options\Design-Spec\');
runid = aspen.Tree.FindNode('\Data\Results Summary\Run-Status\Output\RUNID').value;
fid = fopen([mydir,runid,'.his'],'r');
Data = textscan(fid,'%s','delimiter','\n','whitespace',' ');
fclose('all');
contents = Data{1};

%%
debug = 1;
a = 1;
while a
    errblock = finderror(contents);
    errblock_name = [];
    [r, ~] = size(errblock);
    for i = 1:r
        if ~isnan(errblock(i, 1)) && errblock(i, 1) ~= 0
            for j = 1:length(errblock(i, :))
                errblock_name = [errblock_name, errblock(i, j)];
                if j == length(errblock(i, :)) || (j ~= length(errblock(i, :)) && errblock(i, j+1) == 'T')
                    fprintf('(%d)ERROR%dmodel%s\n', debug, i, errblock_name);
                    switch i
                        case 1 % handle ERROR1
                            if debug==1
                                block.FindNode([errblock_name, '\Input\RECOVL']).value = 0.9999;
                                block.FindNode([errblock_name, '\Input\RECOVH']).value = 0.0001;
                            else
                                block.FindNode([errblock_name,'\Input\RECOVL']).value=1-0.005*(debug-1);
                                block.FindNode([errblock_name,'\Input\RECOVH']).value=0.005*(debug-1);
                            end
                        case 2 % handle ERROR2
                            block.FindNode([errblock_name, '\Input\HENRY_COMPS']).value = 'HC-2';
                        case 3 % handle ERROR3
                            % if DS.FindNode('T1D\Output\FINAL_VAL\1').value-DS.FindNode('T1D\Output\INIT_VAL
                            % \1').value<1e-5
                            try DS.Elements.Remove(errblock_name);
                            catch end
                        case 4
                            block.FindNode([errblock_name,'\Input\RECOVL']).value=1-0.005*debug;
                            block.FindNode([errblock_name,'\Input\RECOVH']).value=0.005*debug;
                    end
                    errblock_name = [];
                end
            end
        end
    end
    aspen.Reinit;
    a = run();
    debug = debug + 1;
    if debug > 5
        disp(['Still reporting errors after 5 rounds of adjustments, please check manually. Fix it and ' ...
            'continue with run completion status.'])
        pause();
        a=0;
    end
end

end
function modify_param()
global aspen column_num
disp('【Optimize design parameters】')
disp('(1)stage vs RR')
block = aspen.Tree.FindNode('\Data\Blocks\');

for i = 1:column_num
    min_reflux(i) = block.FindNode(['T', num2str(i), '\Output\MIN_REFLUX']).value;
    min_stages(i) = block.FindNode(['T', num2str(i), '\Output\MIN_STAGES']).value;
    block.FindNode(['T', num2str(i), '\Input\PLOT']).value = 'YES';
    block.FindNode(['T', num2str(i), '\Input\OPT_SZNO']).value = 'SIZE';
    block.FindNode(['T', num2str(i), '\Input\INCR']).value = 1;
    block.FindNode(['T', num2str(i), '\Input\LOWER']).value = round(min_stages(i)) + 1;
    block.FindNode(['T', num2str(i), '\Input\UPPER']).value = 97;
end
aspen.Reinit;
run();
pause(1)
RR = [];
stage = [];
for i = 1:column_num
    for j = round(min_stages(i)) + 1:97
        stage(i, j-round(min_stages(i))) = j;
        RR(i, j-round(min_stages(i))) = block.FindNode(['T', num2str(i), '\Output\RR_OUT\', num2str(j)]).value;
    end
end
RR_stage = RR .* stage;
RR_stage(RR_stage == 0) = inf;
disp('(2)apply optimized parameters')
[~, p] = min(RR_stage,[],2);
for i = 1:column_num
    % plot(stage(i,:),RR(i,:))
    block.FindNode(['T',num2str(i),'\Input\OPT_NTRR']).value = 'NSTAGE';
    block.FindNode(['T',num2str(i),'\Input\NSTAGE']).value = stage(i, p(i));
    block.FindNode(['T', num2str(i), '\Input\PLOT']).value = 'NO';
end
run();
end
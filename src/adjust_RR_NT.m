function adjust_RR_NT()
global aspen column_num columnio
disp('[Optimize design parameters]')
disp('(1) stage vs RR')
block = aspen.Tree.FindNode('\Data\Blocks\');

for i = 1:column_num
    if columnio{i,7}~=0, continue, end
    min_reflux(i) = block.FindNode(['T', num2str(i), '\Output\MIN_REFLUX']).value;
    min_stages(i) = block.FindNode(['T', num2str(i), '\Output\MIN_STAGES']).value;
    block.FindNode(['T', num2str(i), '\Input\PLOT']).value = 'YES';
    block.FindNode(['T', num2str(i), '\Input\OPT_SZNO']).value = 'SIZE';
    block.FindNode(['T', num2str(i), '\Input\INCR']).value = 1;
    block.FindNode(['T', num2str(i), '\Input\LOWER']).value = round(min_stages(i)) + 1;
    block.FindNode(['T', num2str(i), '\Input\UPPER']).value = 100;
end
aspen.Reinit;
run2();
pause(1)

RR = [];
stage = [];
for i = 1:column_num
    if columnio{i,7}~=0, continue, end
    for j = round(min_stages(i)) + 1:97
        stage(i, j-round(min_stages(i))) = j;
        RR(i, j-round(min_stages(i))) = block.FindNode(['T', num2str(i), '\Output\RR_OUT\', num2str(j)]).value;
    end
end
RR_stage = RR .* stage;
RR_stage(RR_stage == 0) = inf;

disp('(2) apply optimized parameters')
[~, p] = min(RR_stage,[],2);
for i = 1:column_num
    if columnio{i,7}~=0, continue, end
    % plot(stage(i,:),RR(i,:))
    block.FindNode(['T',num2str(i),'\Input\OPT_NTRR']).value = 'NSTAGE';
    block.FindNode(['T',num2str(i),'\Input\NSTAGE']).value = stage(i, p(i));
    block.FindNode(['T', num2str(i), '\Input\PLOT']).value = 'NO';
end
run2();
end
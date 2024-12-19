function set_superstructure(material,feedstream,gen_rule,exnum)
%{
Generating distillation sequence superstructures using a recursive-preorder traversal algorithm
Input:
    material,feedstream,gen_rule,exnum
Output:
    Distillation sequence superstructure generated with DSTWU in Aspen Plus.
Variables:
    name_count: Distillation column count.
%}
global dupl aspen column_num columnio mydir
block = aspen.Tree.FindNode('\Data\Blocks');
stream = aspen.Tree.FindNode('\Data\Streams\');
block.Elements.Add('DUPL!DUPL');
block.FindNode('DUPL\Ports\F(IN)').Elements.Add(feedstream);
name_count = 1;
if isscalar(gen_rule)
    period_count = zeros(1, material(end).sep-1);
else
    period_count = zeros(1, material(end).sep-1+length(gen_rule{2}));
end
dupl2={};
sep_ss(length(material), 0, material, 0);
aspen.Save;
column_num = name_count-1;
fprintf('Total column=%d\n',column_num)

%% Superstructure generation function
function sep_ss(number, last_step, material, p)
step = last_step + 1;
if last_step ~= 0
    dupl_D_last = ['D', num2str(last_step), num2str(period_count(last_step))];
    dupl_B_last = ['B', num2str(last_step), num2str(period_count(last_step))];
end
if number == 1
    return
else
    for k = 1:number - 1
        split_left = k;
        split_right = k + 1;
        if material(split_left).sep == material(split_right).sep
            k = k + 1;
            continue
        end
        period_count(step) = period_count(step) + 1;
        fprintf('step%d: ', step);
        fprintf('%d, %d\n', number, material(1).sep);
        fprintf('%d/%d\n', material(split_left).sep, material(split_right).sep);
        % fprintf('name_count=%d\n', name_count);
        skip=0;
        azeotrope=0;
        if name_count>=5 % when this is set to 0, columns are not merged. Such as aniline extraction
            sep_task=[num2str(material(k).num),num2str(material(split_right).num),num2str(number),num2str(k)];
            a=strcmp(columnio(:,5),sep_task);
            l=find(a==1);
            if ~isempty(l)
                if columnio{l,6}==1 % add selector only for the first time
                    block.Elements.Add(['M',num2str(l),'!Selector']);
                    block.FindNode(['M',num2str(l),'\Ports\P(OUT)']).Elements.Add(['S',num2str(l)]);
                    strname=[num2str(l),'-1']; % e.g. S3-1
                    stream.Elements.Add(['S',strname]);
                    block.FindNode(['M',num2str(l),'\Ports\F(IN)']).Elements.Add(['S',strname]);
                    block.FindNode(['M',num2str(l),'\Input\STREAM']).value=['S',strname];
                    % S-(1) connect to last DUPL (feed stream to the breaked column)
                    for j=2:length(dupl(:,1))
                        a=strcmp(dupl{j,2},num2str(l));
                        b=find(a==1,1);
                        if ~isempty(b)
                            dupl{j,2}(b)=[];
                            block.FindNode([dupl{j,1},'\Ports\P(OUT)']).Elements.Add(['S',strname]);
                            dupl{j,2} = [dupl{j,2}, {strname}];
                            break
                        end
                    end
                    
                    strname=[num2str(l),'-2']; % e.g. S3-2
                    stream.Elements.Add(['S',strname]);
                    block.FindNode(['M',num2str(l),'\Ports\F(IN)']).Elements.Add(['S',strname]);
                    % S-(2) connect to last DUPL (product stream for the current column)
                    switch p
                        case 1
                            block.FindNode([dupl_D_last,'\Ports\P(OUT)']).Elements.Add(['S',strname]);
                            dupl{strcmp(dupl(:,1),dupl_D_last),2} = [dupl{strcmp(dupl(:,1),dupl_D_last),2}, {strname}];
                        case 2
                            block.FindNode([dupl_B_last,'\Ports\P(OUT)']).Elements.Add(['S',strname]);
                            dupl{strcmp(dupl(:,1),dupl_B_last),2} = [dupl{strcmp(dupl(:,1),dupl_B_last),2}, {strname}];
                    end
                    columnio{l,6}=columnio{l,6}+1;
                else
                    repeat=0;
                    strname=[num2str(l),'-',num2str(columnio{l,6}+1)]; % e.g. S3-3
                    switch p
                        case 1
                            for j=2:length(dupl(:,1)) 
                                % 可能出现连入既有塔后后续分离任务也全是既有塔的情况,此时不重复生成流股
                                % e.g. B22连第一个混合塔,后续也重复时该轮的dupl会变,如B24,此时B24不存在,说明此时不用生成流股
                                if strcmp(dupl_D_last,dupl{j,1})
                                    stream.Elements.Add(['S',strname]);
                                    block.FindNode(['M',num2str(l),'\Ports\F(IN)']).Elements.Add(['S',strname]);
                                    % S -N connect to last DUPL
                                    block.FindNode([dupl_D_last,'\Ports\P(OUT)']).Elements.Add(['S',strname]);
                                    dupl{j,2} = [dupl{j,2}, {strname}];
                                    columnio{l,6}=columnio{l,6}+1;
                                    repeat=1;
                                    break
                                end
                            end
                        case 2
                            for j=2:length(dupl(:,1))
                                if strcmp(dupl_B_last,dupl{j,1})
                                    stream.Elements.Add(['S',strname]);
                                    block.FindNode(['M',num2str(l),'\Ports\F(IN)']).Elements.Add(['S',strname]);
                                    % S -N connect to last DUPL
                                    block.FindNode([dupl_B_last,'\Ports\P(OUT)']).Elements.Add(['S',strname]);
                                    dupl{j,2} = [dupl{j,2}, {strname}];
                                    columnio{l,6}=columnio{l,6}+1;
                                    repeat=1;
                                    break
                                end
                            end
                    end
                    if repeat==0
                        dupl2{length(dupl2)+1}=strname;
                    end
                end
                skip=1;
            end
        end
        if skip==0
            % 58th will lag on 8-component，86th lags on 9-component，10=122
            if name_count==58||name_count==86||name_count==122
                aspen.Save;
                try
                    stream.Elements.Add(['S',num2str(name_count)]);
                    block.FindNode('T1\Input\PTOP').value;
                catch
                    disp('paused')
                    pause()
                    [~,block,stream] = evoke(mydir,'base_superstructure');
                    stream.Elements.Add(['S',num2str(name_count)]);
                end
            end
            % connect to last DUPL
            stream.Elements.Add(['S',num2str(name_count)]);
            columnio{name_count,1}=name_count;
            columnio{name_count,2}=['S',num2str(name_count)];
            switch p
                case 0
                    block.FindNode('DUPL\Ports\P(OUT)').Elements.Add(['S', num2str(name_count)]);
                    dupl{1,2} = [dupl{1,2}, num2str(name_count)];
                case 1
                    % fprintf('  connect %s  ', dupl_D_last);
                    block.FindNode([dupl_D_last,'\Ports\P(OUT)']).Elements.Add(['S', num2str(name_count)]);
                    dupl{strcmp(dupl(:,1),dupl_D_last),2} = [dupl{strcmp(dupl(:,1),dupl_D_last),2}, {num2str(name_count)}];
                case 2
                    % fprintf('  connect %s  ', dupl_B_last);
                    block.FindNode([dupl_B_last,'\Ports\P(OUT)']).Elements.Add(['S', num2str(name_count)]);
                    dupl{strcmp(dupl(:,1),dupl_B_last),2} = [dupl{strcmp(dupl(:,1),dupl_B_last),2}, {num2str(name_count)}];
                otherwise
                    disp('Invalid p value. Please check.');
            end
            % Creat a column
            % pause(0.5); % for components greater than 7
            column_name = ['T', num2str(name_count)];
            column_D = [material(split_left).name, num2str(name_count)];
            column_B = [material(split_right).name, num2str(name_count)];
            if length(gen_rule)>1
                for j=1:length(gen_rule{2})
                    if strcmp(material(split_left).name,gen_rule{2}(j).name1) && strcmp(material(split_right).name,gen_rule{2}(j).name2)
                        azeotrope=1;
                        anum=j;
                        break
                    end
                end
            end
            if azeotrope==0
                block.Elements.Add([column_name,'!DSTWU']);
                stream.Elements.Add(column_D);
                stream.Elements.Add(column_B);
                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(['S', num2str(name_count)]);
                block.FindNode([column_name,'\Ports\D(OUT)']).Elements.Add(column_D);
                block.FindNode([column_name,'\Ports\B(OUT)']).Elements.Add(column_B);
                columnio{name_count,3}=column_D;
                columnio{name_count,4}=column_B;
                columnio{name_count,5}=[num2str(material(k).num),num2str(material(split_right).num),num2str(number),num2str(k)];
                columnio{name_count,6}=1;
                columnio{name_count,7}=0;% flowrate for extrectant is zero
                % generate a DUPL for the column output streams
                dupl_D = ['D', num2str(step), num2str(period_count(step))];
                dupl_B = ['B', num2str(step), num2str(period_count(step))];
                for j=split_left:-1:1 % determine if we need a DUPL
                    if material(j).sep~=material(split_left).sep
                        % fprintf('  generate %s  ',dupl_D);
                        block.Elements.Add([dupl_D,'!DUPL']);
                        block.FindNode([dupl_D,'\Ports\F(IN)']).Elements.Add(column_D);
                        duplength=length(dupl(:,1));
                        dupl{duplength+1,1} = dupl_D;
                        dupl{duplength+1,3} = split_left;
                        dupl{duplength+1,4} = k;
                        dupl{duplength+1,5} = name_count;
                        break
                    end
                end
                for j=split_right:number
                    if material(j).sep~=material(split_right).sep
                        % fprintf('  generate %s  ',dupl_B);
                        block.Elements.Add([dupl_B,'!DUPL']);
                        block.FindNode([dupl_B,'\Ports\F(IN)']).Elements.Add(column_B);
                        duplength=length(dupl(:,1));
                        dupl{duplength+1,1} = dupl_B;
                        dupl{duplength+1,3} = split_right;
                        dupl{duplength+1,4} = number - k;
                        dupl{duplength+1,5} = name_count;
                        break
                    end
                end
                % INPUT COLUMN PARAMETERS
                block.FindNode([column_name,'\Input\OPT_NTRR']).value = 'RR';
                block.FindNode([column_name,'\Input\RR']).value = -1.2;
                block.FindNode([column_name,'\Input\LIGHTKEY']).value = material(split_left).name;
                block.FindNode([column_name,'\Input\HEAVYKEY']).value = material(split_right).name;
                block.FindNode([column_name,'\Input\RECOVL']).value = gen_rule{1}(1).recovl;
                block.FindNode([column_name,'\Input\RECOVH']).value = gen_rule{1}(1).recovh;
                for j=1:length(gen_rule{1})
                    if strcmp(material(split_left).name,gen_rule{1}(j).name1) && strcmp(material(split_right).name,gen_rule{1}(j).name2)
                        if ~isempty(gen_rule{1}(j).P)
                            block.FindNode([column_name,'\Input\PTOP']).value = gen_rule{1}(j).P;
                            block.FindNode([column_name,'\Input\PBOT']).value = gen_rule{1}(j).P;%+0.2;
                        else
                            block.FindNode([column_name,'\Input\PTOP']).value = gen_rule{1}(1).P;
                            block.FindNode([column_name,'\Input\PBOT']).value = gen_rule{1}(1).P;%+0.2;
                        end
                        if ~isempty(gen_rule{1}(j).recovl)
                            block.FindNode([column_name,'\Input\RECOVL']).value = gen_rule{1}(j).recovl;
                        end
                        if ~isempty(gen_rule{1}(j).recovh)
                            block.FindNode([column_name,'\Input\RECOVH']).value = gen_rule{1}(j).recovh;
                        end
                        break
                    end
                    if j==length(gen_rule{1})
                        block.FindNode([column_name,'\Input\PTOP']).value = gen_rule{1}(1).P;
                        block.FindNode([column_name,'\Input\PBOT']).value = gen_rule{1}(1).P;%+0.2;
                    end
                end
            else
                disp("Perform extractive distillation")
                block.Elements.Add([column_name,'!SEP']);
                stream.Elements.Add(column_D);
                stream.Elements.Add(column_B);
                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(['S', num2str(name_count)]);
                block.FindNode([column_name,'\Ports\P(OUT)']).Elements.Add(column_D);
                block.FindNode([column_name,'\Ports\P(OUT)']).Elements.Add(column_B);
                columnio{name_count,3}=column_D;
                columnio{name_count,4}=column_B;
                columnio{name_count,5}=[num2str(material(k).num),num2str(material(split_right).num),num2str(number),num2str(k)];
                columnio{name_count,6}=1;
                columnio{name_count,7}=gen_rule{2}(1).F;
                % generate a DUPL for the output of sep
                dupl_D = ['D', num2str(step), num2str(period_count(step))];
                dupl_B = ['B', num2str(step), num2str(period_count(step))];
                for j=split_left:-1:1
                    if material(j).sep~=material(split_left).sep
                        block.Elements.Add([dupl_D,'!DUPL']);
                        block.FindNode([dupl_D,'\Ports\F(IN)']).Elements.Add(column_D);
                        duplength=length(dupl(:,1));
                        dupl{duplength+1,1} = dupl_D;
                        dupl{duplength+1,3} = split_left;
                        dupl{duplength+1,4} = k;
                        dupl{duplength+1,5} = name_count;
                        break
                    end
                end
                % there must be a DUPL in the column bottom when adding an extractant
                    block.Elements.Add([dupl_B,'!DUPL']);
                    block.FindNode([dupl_B,'\Ports\F(IN)']).Elements.Add(column_B);
                    duplength=length(dupl(:,1));
                    dupl{duplength+1,1} = dupl_B;
                    dupl{duplength+1,3} = split_right;
                    dupl{duplength+1,4} = number - k;
                    dupl{duplength+1,5} = name_count;
                % Input sep parameters
                block.FindNode([column_name,'\Input\FRACS\',column_D,'\MIXED\',gen_rule{2}(anum).name1]).value=gen_rule{2}(anum).frac1;
                block.FindNode([column_name,'\Input\FRACS\',column_D,'\MIXED\',gen_rule{2}(anum).name2]).value=gen_rule{2}(anum).frac2;
                if split_left>1
                    for j=split_left-1:-1:1
                        block.FindNode([column_name,'\Input\FRACS\',column_D,'\MIXED\',material(j).name]).value=1;
                    end
                end
                % Add extractant stream
                ex_name=['EX',num2str(anum),'-',num2str(name_count)];
                stream.Elements.Add(ex_name);
                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(ex_name);
                pause(0.5)
                stream.FindNode([ex_name,'\Input\BASIS\MIXED']).value='MOLE-FRAC';
                stream.FindNode([ex_name,'\Input\FLOW\MIXED\',gen_rule{2}(anum).extractant]).value=1;
                stream.FindNode([ex_name,'\Input\TOTFLOW\MIXED']).value=gen_rule{2}(anum).F;
                if isempty(gen_rule{2}(anum).T)
                    stream.FindNode([ex_name,'\Input\TEMP\MIXED']).value=25;
                else
                    stream.FindNode([ex_name,'\Input\TEMP\MIXED']).value=gen_rule{2}(anum).T;
                end
                if isempty(gen_rule{2}(anum).P)
                    stream.FindNode([ex_name,'\Input\PRES\MIXED']).value=gen_rule{1}(1).P;
                else
                    stream.FindNode([ex_name,'\Input\PRES\MIXED']).value=gen_rule{2}(anum).P;
                end
            end
            name_count = name_count + 1;
        end
        % The separated material is removed and the remaining structure is transferred
        material1=material;
        for i=1:number-k
            material1(k+1)=[];
        end
        material2=material;
        for i=1:k
            material2(1)=[]; % delete k times
        end
        if azeotrope==0
            % subsequence generation
            sep_ss(k, step, material1, 1);
            sep_ss(number-k, step, material2, 2);
        else
            % When the extractant is an external substance, it is added to the material and is only effective after the next layer
            temp=strcmp(gen_rule{2}(anum).extractant,{material.name});
            if isempty(find(temp==1,1))
                for i=length(material2):-1:1
                    if material2(i).num>exnum
                        material2(i+1)=material2(i);
                        material2(i+1).sep=material2(i).sep+1;
                    else
                        material2(i+1).name=gen_rule{2}(anum).extractant;
                        material2(i+1).product=1;
                        material2(i+1).noncondensing=0;
                        if strcmp(gen_rule{2}(anum).extractant,'ANI') && strcmp(material2(i).name,'MC')
                            material2(i+1).sep=material2(i).sep;
                        else
                            material2(i+1).sep=material2(i).sep+1;
                        end
                        material2(i+1).num=exnum;
                        break
                    end
                end
                % The subsequence is generated using the new material, and the total material number is +1
                sep_ss(k, step, material1, 1);
                sep_ss(number+1-k, step, material2, 2);
            else
                sep_ss(k, step, material1, 1);
                sep_ss(number-k, step, material2, 2);
            end
        end
    end
end
end

end
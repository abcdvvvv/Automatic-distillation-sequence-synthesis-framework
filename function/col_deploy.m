function col_deploy(material, optim_col, allcol,feedstream)
%col_deploy 最优分离序列生成函数
global aspen dupl columnio
columnio = {};
block = aspen.Tree.FindNode('\Data\Blocks\');
stream = aspen.Tree.FindNode('\Data\Streams\');
dupl{1,5}=0;
deploy(0);
% sep_ss2(length([material.sep]), 1, 0, material, 0); %使用sep_ss2来生成radfrac,前提必须要有optim_column结构体

function deploy(last_col)
p=find([dupl{:,5}]==last_col);
if isempty(p)
    return;
end
for i=1:length(p)
    for j = 1:length(dupl{p(i),2})
        temp=strfind(dupl{p(i),2}{j},'-'); %查找dupl是否连有带-流股
        if isempty(temp) %如果dupl后没有连带-的流股
            p2=find(optim_col==str2double(dupl{p(i),2}{j}));
        else
            p2=find(optim_col==str2double(dupl{p(i),2}{j}(1:temp-1)));
        end
        if ~isempty(p2)
            col2=optim_col(p2);
            % 建塔
            column_name = ['T', num2str(col2)];%col2,last_col是要部署的塔的真实序号
            pump_name=['P', num2str(col2)];
            % col3=find(optim_col == col2);%col3是要部署的塔在optim_col(旧)中的索引,optim(col3).num=col2
            % col3last=find(optim_col == last_col);%col3last是上一座塔在optim_col中的索引
            dupl_D = [column_name,'D'];
            dupl_B = [column_name,'B'];
            block.Elements.Add([column_name,'!RADFRAC']);
            stream.Elements.Add(dupl_D);
            stream.Elements.Add(dupl_B);
            block.FindNode([column_name,'\Input\CONDENSER']).value = 'TOTAL';
            block.FindNode([column_name,'\Ports\LD(OUT)']).Elements.Add(dupl_D);
            block.FindNode([column_name,'\Ports\B(OUT)']).Elements.Add(dupl_B);
            columnio{col2,1}=col2;
            columnio{col2,3}=dupl_D;
            columnio{col2,4}=dupl_B;
            %输入塔参数+连接到上一个DUPL
            dupl_D_last = ['T',num2str(dupl{p(i),5}),'D'];
            dupl_D_last2= ['T',num2str(dupl{p(i),5}),'D2']; %给泵用的
            dupl_B_last = ['T',num2str(dupl{p(i),5}),'B'];
            dupl_B_last2= ['T',num2str(dupl{p(i),5}),'B2'];
            block.FindNode([column_name, '\Input\NSTAGE']).value = round(allcol(col2).stage); %总板数
            switch dupl{p(i),1}(1)
            case 'S'
                disp('  连接进口');
                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(feedstream);
                block.FindNode([column_name,'\Input\FEED_STAGE\',feedstream]).value = round(allcol(col2).fstage); %进料塔板输入
                columnio{col2,2}=feedstream;
            case 'D'
                disp('  连接塔顶');
                if allcol(col2).PBOT>allcol(last_col).PTOP-0.2 %压差判断
                    block.Elements.Add([pump_name,'!PUMP']);
                    block.FindNode([pump_name,'\Input\OPT_SPEC']).value='DELP';
                    block.FindNode([pump_name,'\Input\DELP']).value=round(allcol(col2).PBOT-allcol(last_col).PTOP+0.2,1);
                    block.FindNode([pump_name,'\Ports\F(IN)']).Elements.Add(dupl_D_last);
                    stream.Elements.Add(dupl_D_last2);
                    block.FindNode([pump_name,'\Ports\P(OUT)']).Elements.Add(dupl_D_last2);
                    block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_D_last2);
                    block.FindNode([column_name,'\Input\FEED_STAGE\',dupl_D_last2]).value = round(allcol(col2).fstage);
                    columnio{col2,2}=dupl_D_last2;
                else
                    block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_D_last);
                    block.FindNode([column_name,'\Input\FEED_STAGE\',dupl_D_last]).value = round(allcol(col2).fstage);
                    columnio{col2,2}=dupl_D_last;
                end
            case 'B'
                disp('  连接塔底');
                if allcol(col2).PBOT>allcol(last_col).PBOT-0.2 %压差判断
                    block.Elements.Add([pump_name,'!PUMP']);
                    block.FindNode([pump_name,'\Input\OPT_SPEC']).value='DELP';
                    block.FindNode([pump_name,'\Input\DELP']).value=round(allcol(col2).PBOT-allcol(last_col).PBOT+0.2,1);
                    block.FindNode([pump_name,'\Ports\F(IN)']).Elements.Add(dupl_B_last);
                    stream.Elements.Add(dupl_B_last2);
                    block.FindNode([pump_name,'\Ports\P(OUT)']).Elements.Add(dupl_B_last2);
                    block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_B_last2);
                    block.FindNode([column_name,'\Input\FEED_STAGE\',dupl_B_last2]).value = round(allcol(col2).fstage);
                    columnio{col2,2}=dupl_B_last2;
                else
                    block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_B_last);
                    block.FindNode([column_name,'\Input\FEED_STAGE\', dupl_B_last]).value = round(allcol(col2).fstage);
                    columnio{col2,2}=dupl_B_last;
                end
            end
            %操作规范
            block.FindNode([column_name,'\Input\BASIS_RR']).value = allcol(col2).RR;
            block.FindNode([column_name,'\Input\D:F']).value = allcol(col2).D_F;  
            %压力
            block.FindNode([column_name,'\Input\PRES1']).value = allcol(col2).PTOP; %操作压力
            block.FindNode([column_name,'\Input\DP_STAGE']).value = 0.006; %单板压降
            %判断是否需要分凝器
            if allcol(col2).cond_type==1
                block.FindNode([column_name,'\Ports\VD(OUT)']).Elements.Add(dupl_D);
                block.FindNode([column_name,'\Input\CONDENSER']).value = 'PARTIAL-V';
            end
            %公用工程
            block.FindNode([column_name,'\Input\COND_UTIL']).value='CW';
            T_reb=allcol(col2).TBOT;
            if T_reb<115
                block.FindNode([column_name,'\Input\REB_UTIL']).value='STEAM';
            elseif T_reb>=115 && T_reb<155
                block.FindNode([column_name,'\Input\REB_UTIL']).value='LPS';
            elseif T_reb>=155 && T_reb<179
                block.FindNode([column_name,'\Input\REB_UTIL']).value='MPS';
            elseif T_reb>=179 && T_reb<249
                block.FindNode([column_name,'\Input\REB_UTIL']).value='HPS';
            elseif T_reb>=249
                block.FindNode([column_name,'\Input\REB_UTIL']).value='SHPS';
            end
            break;
        end
    end
    deploy(col2);
end
end

%% 删减空的columnio
k = 1;
while k <= length(columnio(:, 1))
    if isempty(columnio{k, 1})
        columnio(k, :) = [];
    else
        k = k + 1;
    end
end
end
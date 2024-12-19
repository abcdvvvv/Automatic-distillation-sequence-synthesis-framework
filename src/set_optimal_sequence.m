function set_optimal_sequence(material,optim_col,allcol,feedstream)
% Optimal Separation Sequence Generation Function
global aspen dupl columnio
columnio = {};
block = aspen.Tree.FindNode('\Data\Blocks\');
stream = aspen.Tree.FindNode('\Data\Streams\');
dupl{1,5} = 0;
deploy(0);
% sep_ss2(length([material.sep]), 1, 0, material, 0);
% Use sep_ss2 to generate radfrac, provided that the optim_column structure is available.

    function deploy(last_col)
        p = find([dupl{:,5}] == last_col);
        if isempty(p)
            return
        end
        for i = 1:length(p)
            for j = 1:length(dupl{p(i),2})
                temp = strfind(dupl{p(i),2}{j},'-'); % find if the dupl is connected to a stream with "-"
                if isempty(temp) % if dupl does not connect to any stream with "-"
                    p2 = find(optim_col == str2double(dupl{p(i),2}{j}));
                else
                    p2 = find(optim_col == str2double(dupl{p(i),2}{j}(1:temp - 1)));
                end
                if ~isempty(p2)
                    col2 = optim_col(p2);
                    % generate a column
                    column_name = ['T', num2str(col2)]; % col2, last_col is the true number of the column to be deployed
                    pump_name = ['P', num2str(col2)];
                    % col3=find(optim_col == col2);% col3 is the index of the tower to be deployed in optim_col(old),optim(col3).num=col2
                    % col3last=find(optim_col == last_col);% col3last is the index of the last tower in optim_col
                    dupl_D = [column_name,'D'];
                    dupl_B = [column_name,'B'];
                    block.Elements.Add([column_name,'!RADFRAC']);
                    stream.Elements.Add(dupl_D);
                    stream.Elements.Add(dupl_B);
                    block.FindNode([column_name,'\Input\CONDENSER']).value = 'TOTAL';
                    block.FindNode([column_name,'\Ports\LD(OUT)']).Elements.Add(dupl_D);
                    block.FindNode([column_name,'\Ports\B(OUT)']).Elements.Add(dupl_B);
                    columnio{col2,1} = col2;
                    columnio{col2,3} = dupl_D;
                    columnio{col2,4} = dupl_B;
                    % enter column parameters + connect to previous DUPL
                    dupl_D_last = ['T',num2str(dupl{p(i),5}),'D'];
                    dupl_D_last2 = ['T',num2str(dupl{p(i),5}),'D2']; % from pumps
                    dupl_B_last = ['T',num2str(dupl{p(i),5}),'B'];
                    dupl_B_last2 = ['T',num2str(dupl{p(i),5}),'B2'];
                    block.FindNode([column_name, '\Input\NSTAGE']).value = round(allcol(col2).stage); % total stages
                    switch dupl{p(i),1}(1)
                        case 'S'
                            disp('  connect feed')
                            block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(feedstream);
                            block.FindNode([column_name,'\Input\FEED_STAGE\',feedstream]).value = round(allcol(col2).fstage);
                            columnio{col2,2} = feedstream;
                        case 'D'
                            disp('  connect top')
                            if allcol(col2).PBOT > allcol(last_col).PTOP - 0.2 % pressure difference judgment
                                block.Elements.Add([pump_name,'!PUMP']);
                                block.FindNode([pump_name,'\Input\OPT_SPEC']).value = 'DELP';
                                block.FindNode([pump_name,'\Input\DELP']).value = round(allcol(col2).PBOT-allcol(last_col).PTOP+0.2,1);
                                block.FindNode([pump_name,'\Ports\F(IN)']).Elements.Add(dupl_D_last);
                                stream.Elements.Add(dupl_D_last2);
                                block.FindNode([pump_name,'\Ports\P(OUT)']).Elements.Add(dupl_D_last2);
                                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_D_last2);
                                block.FindNode([column_name,'\Input\FEED_STAGE\',dupl_D_last2]).value = round(allcol(col2).fstage);
                                columnio{col2,2} = dupl_D_last2;
                            else
                                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_D_last);
                                block.FindNode([column_name,'\Input\FEED_STAGE\',dupl_D_last]).value = round(allcol(col2).fstage);
                                columnio{col2,2} = dupl_D_last;
                            end
                        case 'B'
                            disp('  connect bottom')
                            if allcol(col2).PBOT > allcol(last_col).PBOT - 0.2 % pressure difference judgment
                                block.Elements.Add([pump_name,'!PUMP']);
                                block.FindNode([pump_name,'\Input\OPT_SPEC']).value = 'DELP';
                                block.FindNode([pump_name,'\Input\DELP']).value = round(allcol(col2).PBOT-allcol(last_col).PBOT+0.2,1);
                                block.FindNode([pump_name,'\Ports\F(IN)']).Elements.Add(dupl_B_last);
                                stream.Elements.Add(dupl_B_last2);
                                block.FindNode([pump_name,'\Ports\P(OUT)']).Elements.Add(dupl_B_last2);
                                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_B_last2);
                                block.FindNode([column_name,'\Input\FEED_STAGE\',dupl_B_last2]).value = round(allcol(col2).fstage);
                                columnio{col2,2} = dupl_B_last2;
                            else
                                block.FindNode([column_name,'\Ports\F(IN)']).Elements.Add(dupl_B_last);
                                block.FindNode([column_name,'\Input\FEED_STAGE\', dupl_B_last]).value = round(allcol(col2).fstage);
                                columnio{col2,2} = dupl_B_last;
                            end
                    end
                    % operating specifications
                    block.FindNode([column_name,'\Input\BASIS_RR']).value = allcol(col2).RR;
                    block.FindNode([column_name,'\Input\D:F']).value = allcol(col2).D_F;
                    % pressure
                    block.FindNode([column_name,'\Input\PRES1']).value = allcol(col2).PTOP;
                    block.FindNode([column_name,'\Input\DP_STAGE']).value = 0.006; % pressure drop each stage
                    % determining if a condenser is needed
                    if allcol(col2).cond_type == 1
                        block.FindNode([column_name,'\Ports\VD(OUT)']).Elements.Add(dupl_D);
                        block.FindNode([column_name,'\Input\CONDENSER']).value = 'PARTIAL-V';
                    end
                    % utilities
                    block.FindNode([column_name,'\Input\COND_UTIL']).value = 'CW';
                    T_reb = allcol(col2).TBOT;
                    if T_reb < 115
                        block.FindNode([column_name,'\Input\REB_UTIL']).value = 'STEAM';
                    elseif T_reb >= 115 && T_reb < 155
                        block.FindNode([column_name,'\Input\REB_UTIL']).value = 'LPS';
                    elseif T_reb >= 155 && T_reb < 179
                        block.FindNode([column_name,'\Input\REB_UTIL']).value = 'MPS';
                    elseif T_reb >= 179 && T_reb < 249
                        block.FindNode([column_name,'\Input\REB_UTIL']).value = 'HPS';
                    elseif T_reb >= 249
                        block.FindNode([column_name,'\Input\REB_UTIL']).value = 'SHPS';
                    end
                    break
                end
            end
            deploy(col2);
        end
    end

% Delete empty columnio
k = 1;
while k <= length(columnio(:,1))
    if isempty(columnio{k,1})
        columnio(k,:) = [];
    else
        k = k + 1;
    end
end
end
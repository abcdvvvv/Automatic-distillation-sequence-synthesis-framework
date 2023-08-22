function errblock=finderror(contents)
rule_num=4; % number of rule
error_row=zeros(rule_num,1);
% Error 1: The calculated reflux ratio is less than 0 or the number of column plates is less than 0. 
% This may be due to the fact that the light and heavy key components are too well separated.
locate=contains(contents,'ERROR WHILE EXECUTING UNIT OPERATIONS BLOCK');
error_line=find(locate==1);
if ~isempty(error_line)
    for i=1:length(error_line)
        error_row(1,i)=error_line(i);
        error_contents{1,i}=char(contents(error_line(i)));
    end
end
% Error 2: Henry constant missing parameter, then cancel Henry component for this model option
locate=contains(contents,'HENRY CONSTANT MODEL HENRY1 HAS MISSING PARAMETERS');
error_line=find(locate==1);
if ~isempty(error_line)
    for i=1:length(error_line)
        error_row(2,i)=error_line(i);
        error_contents{2,i}=char(contents(error_line(i)-1));
    end
end
% Error 3: The design specification does not converge, possibly because the initial value is near the optimal 
% solution resulting in a step size smaller than the convergence accuracy
error_string(3,:)=["ERROR WHILE EXECUTING CONVERGENCE BLOCK: ""$OLVER","*   WARNING WHILE EXECUTING " + ...
    "CONVERGENCE BLOCK: ""$OLVER"];
locate=contains(contents,error_string(3,:));
error_line=find(locate==1);
if ~isempty(error_line)
    for i=1:length(error_line)
        error_row(3,i)=error_line(i);
        error_contents{3,i}=char(contents(error_line(i)-3));% error那个错误-2，warning则-3
    end
end
% Error 4: Unable to solve for azeotropy, etc.
locate=contains(contents,'SEVERE ERROR WHILE EXECUTING UNIT OPERATIONS BLOCK');
error_line=find(locate==1);
if ~isempty(error_line)
    for i=1:length(error_line)
        error_row(4,i)=error_line(i);
        error_contents{4,i}=char(contents(error_line(i)));
    end
end

[r,c]=size(error_row);
a=ones(1,rule_num);
for i=1:r
    for j=1:c
        if error_row(i,j)~=0
            fprintf('Error%d error_row: %d\n',i,error_row(i,j));
            switch i
                case 1
                if error_contents{1,j}(51)=='T'
                    for k=51:54
                        if error_contents{1,j}(k)=='"'
                            break
                        else
                            errblock(1,a(1))=error_contents{1,j}(k);
                            a(1)=a(1)+1;
                        end
                    end
                end
                case 2
                if error_contents{2,j}(11)=='T'
                    for k=11:14
                        if error_contents{2,j}(k)==32
                            break
                        else
                            errblock(2,a(2))=char(error_contents{2,j}(k));
                            a(2)=a(2)+1;
                        end
                    end
                end
                case 3
                if error_contents{3,j}(28)=='T'
                    for k=28:30
                        if error_contents{3,j}(k)==32
                            break
                        else
                            errblock(3,a(3))=error_contents{3,j}(k);
                            a(3)=a(3)+1;
                        end
                    end
                end
                case 4
                if error_contents{1,j}(58)=='T'
                    for k=58:61
                        if error_contents{1,j}(k)=='"'
                            break
                        else
                            errblock(4,a(4))=error_contents{4,j}(k);
                            a(4)=a(4)+1;
                        end
                    end
                end
            end
        else
            break
        end
    end
end

end
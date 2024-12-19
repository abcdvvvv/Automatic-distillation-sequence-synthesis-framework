function a = run2()
% This function detects operating conditions by scanning history
global aspen mydir
aspen.Reinit;
aspen.Run2();
while aspen.Engine.IsRunning == 1
    pause(0.5)
end

runid = aspen.Tree.FindNode('\Data\Results Summary\Run-Status\Output\RUNID').value;
fid = fopen([mydir,runid,'.his'],'r');
Data = textscan(fid,'%s','delimiter','\n','whitespace',' ');
fclose('all');

contents = Data{1};
error_string = ["**  ERROR","*** SEVERE ERROR"];
error_line = contains(contents,error_string);
if find(error_line == 1,1)
    disp('Error')
    a = 1;
else
    disp('Converged')
    a = 0;
end
end
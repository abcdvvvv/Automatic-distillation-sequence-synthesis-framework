function set_property_analysis(filename,unit)
% This function automatically adds property analysis to the simulation file.
% unit: the name of unit set used in the Aspen Plus
global aspen mydir
disp('[Add property analysis]')
aspen.Tree.FindNode("\Data\Properties\Prop-Sets").Elements.Add('PS-1');
aspen.Tree.FindNode("\Data\Properties\Prop-Sets\PS-1\Input\UNITS").Elements.InsertRow(0,0);
aspen.Tree.FindNode("\Data\Properties\Prop-Sets").Elements.Add('PS-2');
aspen.Tree.FindNode("\Data\Properties\Prop-Sets\PS-2\Input\UNITS").Elements.InsertRow(0,0);
aspen.Tree.FindNode("\Data\Properties\Prop-Sets").Elements.Add('PS-3');
aspen.Tree.FindNode("\Data\Properties\Prop-Sets\PS-3\Input\UNITS").Elements.InsertRow(0,0);
aspen.Tree.FindNode("\Data\Properties\Prop-Sets\PS-3\Input\UNITS").Elements.InsertRow(0,1);
aspen.Save
aspen.Quit
release(aspen)

contents=fileread([mydir,filename]);
oldtext{1}=['"PS-1" ? ; "',unit,'_MOLE" ; \ P1 1 \ \ P2'];
oldtext{2}=['"PS-2" ? ; "',unit,'_MOLE" ; \ P1 1 \ \ P2'];
oldtext{3}=['"PS-3" ? ; "',unit,'_MOLE" ; \ P1 1 \ \ P1 2 \ \ P2'];
newtext{1}=['"PS-1" ? ; "',unit,'_MOLE" ; \ P1 ID = DHVLMX UNITS = ( "J/kmol" ) \ \ P2 SYSPRES = YES'];
newtext{2}=['"PS-2" ? ; "',unit,'_MOLE" ; \ P1 ID = TCMX UNITS = ( C ) \ \ P2 SYSPRES = YES'];
newtext{3}=['"PS-3" ? ; "',unit,'_MOLE" ; \ P1 ID = PBUB UNITS = ( Pa ) \ \ P1 ID = PDEW UNITS = ( Pa ) \ \ P2 TEMP = ( 318.15 <22> <1> ) SYSPRES = YES SYSTEMP = NO'];
for i=1:3
    contents=replace(contents,oldtext{i},newtext{i});
end
delete([mydir,filename]);
fileID = fopen([mydir,filename],'w'); % create a new file
fprintf(fileID,'%s',contents); % write to a file
fclose(fileID);

evoke2(mydir,filename)
pause(1)

aspen.Tree.FindNode("\Data\Setup\ReportOptions\Stream-Report\Input\PROPERTIES").Elements.InsertRow(0,0);
aspen.Tree.FindNode("\Data\Setup\ReportOptions\Stream-Report\Input\PROPERTIES").Elements.InsertRow(0,1);
aspen.Tree.FindNode("\Data\Setup\ReportOptions\Stream-Report\Input\PROPERTIES").Elements.InsertRow(0,2);
aspen.Tree.FindNode("\Data\Setup\ReportOptions\Stream-Report\Input\PROPERTIES\#0").value='PS-1';
aspen.Tree.FindNode("\Data\Setup\ReportOptions\Stream-Report\Input\PROPERTIES\#1").value='PS-2';
aspen.Tree.FindNode("\Data\Setup\ReportOptions\Stream-Report\Input\PROPERTIES\#2").value='PS-3';
end
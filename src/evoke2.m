function evoke2(mydir,filename)
global aspen
aspen = actxserver('apwn.document'); % 38.0(V12)
aspen.InitFromArchive2([mydir,filename]);
aspen.Visible = 1;
aspen.SuppressDialogs = 1;
end
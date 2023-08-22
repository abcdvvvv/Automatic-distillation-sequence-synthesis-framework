function qmin2factor(allcol,optim_col)
% Improved quadratic interpolation algorithm
global aspen columnio cost1 t
block = aspen.Tree.FindNode('\Data\Blocks');
disp('【Single column optimization】')

for i=1:length(optim_col)
    t=optim_col(i); % t is the column to be optimized
    c=ceil(allcol(t).minstage);
    a=c+1; b=round(1.55*c)+15;
    cost1=zeros(2,b+30);
        fprintf('RR*2\n'); % optional
        block.FindNode(['T',num2str(t),'\Input\BASIS_RR']).value=block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input\UB\1']).value;
        block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input\UB\1']).value=block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input\UB\1']).value*2;
    [s,bfs]=qmin(a,b,0.1,1e-5);
    fprintf('best: stage=%d,feed=%d\n',round(s),bfs);
    block.FindNode(['T',num2str(t),'\Input\NSTAGE']).value=round(s);
    block.FindNode(['T',num2str(t),'\Input\FEED_STAGE\',columnio{i,2}]).value=bfs;
    block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Input\CA_STAGE2\INT-1\CS-1']).value=s-1;
    % reconcile
    block.FindNode(['T',num2str(t),'\Input\BASIS_RR']).value = block.FindNode(['T',num2str(t),'\Output\MOLE_RR']).value;
    block.FindNode(['T',num2str(t),'\Input\D:F']).value = block.FindNode(['T',num2str(t),'\Output\MOLE_DFR']).value;
    block.FindNode(['T',num2str(t),'\Subobjects\Design Specs\1\Input\SPEC_ACTIVE\1']).value='NO';
    block.FindNode(['T',num2str(t),'\Subobjects\Design Specs\1\Input\SPEC_ACTIVE\2']).value='NO';
    block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input\VARY_ACTIVE\1']).value='NO';
    block.FindNode(['T',num2str(t),'\Subobjects\Vary\1\Input\VARY_ACTIVE\2']).value='NO';
end

end

%% total stages
function [s,bfs]=qmin(a,b,delta,epsilon)
s0=a; maxj=20; maxk=30; big=1e6; err=100; k=1;
S(k)=s0; cond=0; h=(b-a)/2; ds=1;
if abs(s0)>1e4
    h=abs(s0)*(1e-4);
end
s1=s0+h; s2=s0+2*h;
[phi0,fs(s0)]=golds(s0); [phi2,fs(s2)]=golds(s2);
sh=(fs(s2)-fs(s0))/(s2-s0); % scale factor q
f=@(sx)(sx-a)*sh+fs(a);

while k<maxk && err>epsilon && cond~=5
    if k>=2
        f1=(feeds(s0+ds,f(s0+ds))-feeds(s0,f(s0)))/ds;
        if f1>0
            h=-abs(h);
        end
    end
    phi1=feeds(s1,f(s1));
    cond=0;
    j=0; 
    while j<maxj && abs(h)>delta && cond==0
        if phi0<phi1
            s2=s1; phi2=phi1; h=0.5*h;
            s1=s0+h; phi1=feeds(s1,f(s1));
        elseif phi2<phi1
            s1=s2; phi1=phi2; h=2*h;
            s2=s0+2*h; phi2=feeds(s2,f(s2));
        else
            cond=-1;
        end
        j=j+1;
    end
    if abs(h)>big || abs(s0)>big
        cond=5;
    end
    if cond==5
        sb=s1;
        phib=feeds(s1,f(s1));
    else
        d=2*(2*phi1-phi0-phi2);
        if d<0
            hb=h*(4*phi1-3*phi0-phi2)/d;
        else
            hb=h/3;
            cond=4;
        end
        sb=s0+hb;
        phib=feeds(sb,f(sb));
        h=abs(h);
        h0=abs(hb);
        h1=abs(hb-h);
        h2=abs(hb-2*h);
        if h0<h, h=h0; end
        if h1<h, h=h1; end
        if h2<h, h=h2; end
        if h==0, h=hb; end
        if h<delta, cond=1; end
        if abs(h)>big || abs(sb)>big, cond=5; end
        err=abs(phi1-phib);
        s0=sb;
        k=k+1;
        S(k)=s0;
    end
    if cond==2 && h<delta
        cond=3;
    end
end
s=s0; [~,bfs]=feeds(s,f(s));
end

%% find best feed location
function [minimum,fs]=feeds(st,f)
global cost1
st=round(st);
f=round(f);
if cost1(1,st)~=0
    minimum=cost1(1,st);
    fs=cost1(2,st);
    return;
else
    a=phi(st,f); b=phi([],f+1);
    if a<b
        while a<b
            f=f-1;
            b=a;
            a=phi([],f);
        end
        fs=f+1;
        minimum=b;
    else
        while a>b
            f=f+1;
            a=b;
            b=phi([],f+1);
        end
        fs=f-1;
        minimum=a;
    end
    cost1(1,st)=minimum;
    cost1(2,st)=fs;
    fprintf(' stage=%d,feed=%d\n',st,fs);
end
end

%% golden section
function [minimum,fs]=golds(st)
global aspen cost1 t
st=round(st);
if cost1(1,st)~=0
    minimum=cost1(1,st);
    fs=cost1(2,st);
    return;
else
    block = aspen.Tree.FindNode('\Data\Blocks');
    aspen.Reinit;
    fprintf('Total stages=%d\n',st);
    cost2=zeros(1,st-2);
    block.FindNode(['T',num2str(t),'\Input\NSTAGE']).value=st;
    block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Input\CA_STAGE2\INT-1\CS-1']).value=st-1;
    if st<10
        for i=3:st-2
            cost2(i)=phi([],i);
        end
        cost2(cost2==0)=inf;
        [minimum,fs]=min(cost2);
    else
        % search in [a0=3,b0=st-2]
        a=3; b=st-2;
        t=(sqrt(5)-1)/2; h=b-a;
        %cost2(round(a))=phi(a); cost2(round(b))=phi(b);
        p=a+(1-t)*h;q=a+t*h;
        cost2(round(p))=phi([],p); cost2(round(q))=phi([],q);
        k=1; G(k,:)=[a,p,q,b];
        while (cost2(round(p))<=cost2(round(q)) && q-a>1)||(cost2(round(p))>cost2(round(q)) && b-p>1)
            if cost2(round(p))<cost2(round(q))
                b=q; q=p; cost2(round(q))=cost2(round(p)); p=a+(1-t)*(b-a); 
                if cost2(round(p))==0
                    cost2(round(p))=phi([],p);
                end
            else
                a=p; p=q; cost2(round(p))=cost2(round(q)); q=a+t*(b-a);
                if cost2(round(q))==0
                    cost2(round(q))=phi([],q);
                end
            end
            k=k+1; G(k,:)=[a,p,q,b];
        end
        % ds=abd(b-a); dphi=abs(phib-phia);
        if cost2(round(p))<=cost2(round(q))
            fs=round(p);
        else
            fs=round(q);
        end
        minimum=cost2(fs);
        cost1(1,st)=cost2(fs);
        cost1(2,st)=fs;
    end
    fprintf('  stage=%d, feed=%d\n',st,fs);
end
end

%% cost calculation
function cost=phi(st,fs)
global aspen allcol columnio AF t
block = aspen.Tree.FindNode('\Data\Blocks');

if ~isempty(st)
    fprintf('Total stages=%d\n',st);
    block.FindNode(['T',num2str(t),'\Input\NSTAGE']).value=st;
    block.FindNode(['T',num2str(t),'\Subobjects\Column Internals\INT-1\Input\CA_STAGE2\INT-1\CS-1']).value=st-1;
end
    fs=round(fs);
    fprintf('  feed=%d ',fs);
    % num=find([columnio{:,1}]==t);
    block.FindNode(['T',num2str(t),'\Input\FEED_STAGE\',columnio{[columnio{:,1}]==t,2}]).value=fs;
    aspen.Reinit;
    a=run();
    pause(1);
    if a
        cost=1e8; % punishment
    else
        allcol(t)=readcolumn(allcol,t);
        OPEX = fOPEX(allcol,t);
        CAPEX = fCAPEX(allcol,t);
        fprintf('  OPEX=%.3d, CAPEX*%.3f=%.3d\n',OPEX,AF,CAPEX*AF);
        cost=OPEX+CAPEX*AF;
    end
    pause(3);
end
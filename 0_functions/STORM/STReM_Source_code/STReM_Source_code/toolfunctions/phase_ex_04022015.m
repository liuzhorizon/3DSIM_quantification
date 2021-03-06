function phase=phase_ex_04022015(ratio,z0,loop_r,loop_a)
% ratio=f/r
xx=linspace(-1,1,loop_r);
yy=linspace(-1,1,loop_a);
%lambda=5.32*1e-7;
lambda=5.85*1e-7;
[x,y]=meshgrid(xx,yy);
h=sqrt(x.^2+y.^2);
f=ratio*max(xx);

n=1.518;
%n=1.65;
%NA=1.45;
NA=1.17;
zp=z0*(2*n-2*sqrt(n^2-NA^2))*ratio^2;
f=f/2;
h=h/2;
%phase=f./sqrt(f^2+h.^2).*zp*1;
%phase=f./sqrt(f^2+h.^2)*z0*(2*n-2*sqrt(n^2-NA^2));
phase=sqrt((f+zp).^2+h.^2)-sqrt(f.^2+h.^2);
phase=2*pi/lambda*phase;
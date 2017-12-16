% -------------------------------------------------------------------------
%
% File : EKFSLAM.m
%
% Discription : Simultaneous Localization And Mapping with EKF
%
% Environment : MATLAB
%
% Author : Atsushi Sakai
%
% Copyright (c): 2014 Atsushi Sakai
%
% License : GPL Software License Agreement
% -------------------------------------------------------------------------

function EKFSLAM()
close all;
clear all;
disp('EKFSLAM sample program start!!')
 
time = 0;
endtime = 60; % �V�~�����[�V�����I������[sec]
global dt;
dt = 0.1; % �V�~�����[�V�������ݎ���[sec]
nSteps = ceil((endtime - time)/dt);%�V�~�����[�V�����̃X�e�b�v��
 
%�v�Z���ʊi�[�p�ϐ�
result.time=[];
result.xTrue=[];
result.xd=[];
result.xEst=[];
result.z=[];
result.PEst=[];
result.u=[];

% State Vector [x y yaw]'
xEst=[0 0 0]';
global PoseSize;PoseSize=length(xEst);%���{�b�g�̎p���̏�Ԑ�[x,y,yaw]
global LMSize;LMSize=2;%�����h�}�[�N�̏�ԗ�[x,y]
% True State
xTrue=xEst;
 
% Dead Reckoning State
xd=xTrue;
 
% Covariance Matrix for predict
R=diag([0.2 0.2 toRadian(1)]).^2;
 
% Covariance Matrix for observation
global Q;
Q=diag([10 toRadian(30)]).^2;%range[m], Angle[rad]

% Simulation parameter
global Qsigma
Qsigma=diag([0.1 toRadian(20)]).^2;
global Rsigma
Rsigma=diag([0.1 toRadian(1)]).^2;

%Landmark�̈ʒu [x, y]
LM=[0 15;
    10 0;
    15 20];
  
MAX_RANGE=20;%�ő�ϑ�����

alpha=1;%�����h�}�[�N���ʗp�}�n���m�r�X����臒l

PEst = eye(3);
initP=eye(2)*1000;
%movcount=0;
 
tic;
% Main loop
for i=1 : nSteps
    time = time + dt;
    % Input
    u=doControl(time);
    % Observation
    [z,xTrue,xd,u]=Observation(xTrue, xd, u, LM, MAX_RANGE);
    
    % ------ EKF SLAM --------
    % Predict
    xEst = f(xEst, u);
    [G,Fx]=jacobF(xEst, u);
    PEst= G'*PEst*G + Fx'*R*Fx;
    
    % Update
    for iz=1:length(z(:,1))%���ꂼ��̊ϑ��l�ɑ΂���
        %�ϑ��l�������h�}�[�N�Ƃ��Ēǉ�
        zl=CalcLMPosiFromZ(xEst,z(iz,:));%�ϑ��l���̂��̂���LM�̈ʒu���v�Z
        %��ԃx�N�g���Ƌ����U�s��̒ǉ�
        xAug=[xEst;zl];
        PAug=[PEst zeros(length(xEst),LMSize);
              zeros(LMSize,length(xEst)) initP];
        
        mdist=[];%�}�n���m�r�X�����̃��X�g
        for il=1:GetnLM(xAug) %���ꂼ��̃����h�}�[�N�ɂ���
            if il==GetnLM(xAug)
                mdist=[mdist alpha];%�V�����ǉ������_�̋����̓p�����[�^�l���g��
            else
                lm=xAug(4+2*(il-1):5+2*(il-1));
                [y,S,H]=CalcInnovation(lm,xAug,PAug,z(iz,1:2),il);
                mdist=[mdist y'*inv(S)*y];%�}�n���m�r�X�����̌v�Z
            end
        end
        
        %�}�n���m�r�X�������ł��߂����̂ɑΉ��t��
        [C,I]=min(mdist);
      
        %��ԋ��������������̂��ǉ��������̂Ȃ�΁A���̊ϑ��l�������h�}�[�N�Ƃ��č̗p
        if I==GetnLM(xAug)
            %disp('New LM')
            xEst=xAug;
            PEst=PAug;
        end
        
        lm=xEst(4+2*(I-1):5+2*(I-1));%�Ή��t����ꂽ�����h�}�[�N�f�[�^�̎擾
        %�C�m�x�[�V�����̌v�Z
        [y,S,H]=CalcInnovation(lm,xEst,PEst,z(iz,1:2),I);
        K = PEst*H'*inv(S);
        xEst = xEst + K*y;
        PEst = (eye(size(xEst,1)) - K*H)*PEst;
    end
    
    xEst(3)=PI2PI(xEst(3));%�p�x�␳
    
    %Simulation Result
    result.time=[result.time; time];
    result.xTrue=[result.xTrue; xTrue'];
    result.xd=[result.xd; xd'];
    result.xEst=[result.xEst;xEst(1:3)'];
    result.u=[result.u; u'];
    
    %Animation (remove some flames)
    if rem(i,5)==0 
        Animation(result,xTrue,LM,z,xEst,zl);
        %movcount=movcount+1;
        %mov(movcount) = getframe(gcf);% �A�j���[�V�����̃t���[�����Q�b�g����
    end
end
toc

%�A�j���[�V�����ۑ�
%movie2avi(mov,'movie.avi');

DrawGraph(result,xEst,LM);

function [y,S,H]=CalcInnovation(lm,xEst,PEst,z,LMId)
%�Ή��t�����ʂ���C�m�x�[�V�������v�Z����֐�
global Q;
delta=lm-xEst(1:2);
q=delta'*delta;
zangle=atan2(delta(2),delta(1))-xEst(3);
zp=[sqrt(q) PI2PI(zangle)];%�ϑ��l�̗\��
y=(z-zp)';
H=jacobH(q,delta,xEst,LMId);
S=H*PEst*H'+Q;

function n=GetnLM(xEst)
%�����h�}�[�N�̐����v�Z����֐�
n=(length(xEst)-3)/2;

function zl=CalcLMPosiFromZ(x,z)
%�ϑ��l����LM�̈ʒu���v�Z����֐�
zl=x(1:2)+[z(1)*cos(x(3)+z(2));z(1)*sin(x(3)+z(2))];

function Animation(result,xTrue,LM,z,xEst,zl)
%�A�j���[�V������`�悷��֐�
hold off;
plot(result.xTrue(:,1),result.xTrue(:,2),'.b');hold on;
plot(LM(:,1),LM(:,2),'pk','MarkerSize',10);hold on;
%�ϑ����̕\��
if~isempty(z)
    for iz=1:length(z(:,1))
        ray=[xTrue(1:2)';z(iz,3:4)];
        plot(ray(:,1),ray(:,2),'-r');hold on;
    end
end
%SLAM�̒n�}�̕\��
for il=1:GetnLM(xEst);
    plot(xEst(4+2*(il-1)),xEst(5+2*(il-1)),'.c');hold on;
end
plot(zl(1,:),zl(2,:),'.b');hold on;
plot(result.xd(:,1),result.xd(:,2),'.k');hold on;
plot(result.xEst(:,1),result.xEst(:,2),'.r');hold on;
arrow=0.5;
x=result.xEst(end,:);
quiver(x(1),x(2),arrow*cos(x(3)),arrow*sin(x(3)),'ok');hold on;
axis equal;
grid on;
%�����ۑ�����ꍇ
%movcount=movcount+1;
%mov(movcount) = getframe(gcf);% �A�j���[�V�����̃t���[�����Q�b�g����
drawnow;

function x = f(x, u)
% Motion Model
global dt;
global PoseSize;
global LMSize;
 
F = horzcat(eye(PoseSize),zeros(PoseSize,LMSize*GetnLM(x)));
 
B = [dt*cos(x(3)) 0
     dt*sin(x(3)) 0
     0 dt];

x= x+F'*B*u;
x(3)=PI2PI(x(3));%�p�x�␳

function [G,Fx]=jacobF(x, u)
% �^�����f���̃��R�r�s��̌v�Z�֐�
global dt;
global PoseSize;
global LMSize;

Fx = horzcat(eye(PoseSize),zeros(PoseSize,LMSize*GetnLM(x)));
 
jF=[0 0 -dt*u(1)*sin(x(3))
    0 0 dt*u(1)*cos(x(3))
    0 0 0];

G=eye(length(x))+Fx'*jF*Fx;

function H=jacobH(q,delta,x,i)
%�ϑ����f���̃��R�r�s����v�Z����֐�
sq=sqrt(q);
G=[-sq*delta(1) -sq*delta(2) 0 sq*delta(1) sq*delta(2);
    delta(2)    -delta(1)   -1 -delta(2)    delta(1)];
G=G/q;
F=[eye(3) zeros(3,2*GetnLM(x));
   zeros(2,3) zeros(2,2*(i-1)) eye(2) zeros(2,2*GetnLM(x)-2*i)];
H=G*F;

function u = doControl(time)
%Calc Input Parameter
T=10; % [sec]
 
% [V yawrate]
V=1.0; % [m/s]
yawrate = 5; % [deg/s]
 
u =[ V*(1-exp(-time/T)) toRadian(yawrate)*(1-exp(-time/T))]';

function [z, x, xd, u] = Observation(x, xd, u, LM ,MAX_RANGE)
%Calc Observation from noise prameter
global Qsigma;
global Rsigma;
 
x=f(x, u);% Ground Truth
u=u+Qsigma*randn(2,1);%add Process Noise
xd=f(xd, u);% Dead Reckoning
%Simulate Observation
z=[];
for iz=1:length(LM(:,1))
    %LM�̈ʒu�����{�b�g���W�n�ɕϊ�
    yaw=zeros(3,1);
    yaw(3)=-x(3);
    localLM=HomogeneousTransformation2D(LM(iz,:)-x(1:2)',yaw');
    d=norm(localLM);%����
    if d<MAX_RANGE %�ϑ��͈͓�
        noise=Rsigma*randn(2,1);
        z=[z;[d+noise(1) PI2PI(atan2(localLM(2),localLM(1))+noise(2)) LM(iz,:)]];
    end
end

function DrawGraph(result,xEst,LM)
%Plot Result
 figure(1);
hold off;
x=[ result.xTrue(:,1:2) result.xEst(:,1:2)];
set(gca, 'fontsize', 16, 'fontname', 'times');
plot(x(:,1), x(:,2),'-b','linewidth', 4); hold on;
plot(result.xd(:,1), result.xd(:,2),'-k','linewidth', 4); hold on;
plot(x(:,3), x(:,4),'-r','linewidth', 4); hold on;
plot(LM(:,1),LM(:,2),'pk','MarkerSize',10);hold on;%�^�̃����h�}�[�N�̈ʒu
%LM�̒n�}�̕\��
for il=1:GetnLM(xEst);
    plot(xEst(4+2*(il-1)),xEst(5+2*(il-1)),'.g');hold on;
end
 
title('EKF SLAM Result', 'fontsize', 16, 'fontname', 'times');
xlabel('X (m)', 'fontsize', 16, 'fontname', 'times');
ylabel('Y (m)', 'fontsize', 16, 'fontname', 'times');
legend('Ground Truth','Dead Reckoning','EKF SLAM','True LM','Estimated LM');
grid on;
axis equal;

function angle=PI2PI(angle)
%���{�b�g�̊p�x��-pi~pi�͈̔͂ɕ␳����֐�
angle = mod(angle, 2*pi);

i = find(angle>pi);
angle(i) = angle(i) - 2*pi;

i = find(angle<-pi);
angle(i) = angle(i) + 2*pi;

function out = HomogeneousTransformation2D(in, base, mode)
%function out = HomogeneousTransformation2D(in, base,mode)
%HOMOGENEOUSTRANSFORMATION2D �񎟌������ϊ��֐�
%   ��̓_�̕ϊ�����C�����̓_�̈ꊇ�ϊ��܂ŉ\�D
%   ���[�U�⃌�[�_�̓_�Q�����W�ϊ�����̂ɕ֗��ł��D
%   ������in��base��������ꂽ�ꍇ�C�e�_����]��������i����D
%
%   Input1:�ϊ��O�x�N�g�� [x_in_1 y_in_1;
%                        x_in_2  y_in_2;
%                               ....]
%           *�ϊ��O�x�N�g���́C�R�߈ȏ�̗v�f���܂܂�Ă��Ă��C
%            �ŏ��̂Q�����o���C�c��͖������܂��D
%   Input2:��x�N�g��(�g���b�N�̈ʒu�Ƃ�) [x_base y_base theta_base]
%   Input3:�����ϊ����[�h�@���̕ϐ��͈����Ƃ��ē���Ȃ��Ă������܂��D
%           ���������Ȃ��ꍇ�C�f�t�H���g�Ŋe�_����]��������i����D
%           mode=0�̏ꍇ���e�_����]��������i����D
%           mode=1�̏ꍇ�C���i������ɉ�]���܂��D
%
%   Output1:�ϊ���x�N�g�� [x_out y_out;
%                        x_out_2  y_out_2;
%                               ....]

%��]�s��
Rot=[cos(base(3)) sin(base(3)); -sin(base(3)) cos(base(3))];

%�_��������base���W��z��Ɋi�[
Nin=size(in);
baseMat=repmat(base(1:2),Nin(1),1);

% x-y�ȊO�̃f�[�^�������Ă����ꍇ�D��񑼂̕ϐ��ɒu���Ă����D
if Nin(2)>=3
    inxy=in(:,1:2);
    inOther=in(:,3:end);
    in=inxy;
end

%�����ϊ�
if nargin==2 || mode==0 %��]�����i
    out=baseMat+in*Rot;
else %���i����]
    out=(baseMat+in)*Rot;
end
    
%��菜�����l����������D
if Nin(2)>=3
    out=[out inOther];
end

function radian = toRadian(degree)
% degree to radian
radian = degree/180*pi;

function degree = toDegree(radian)
% radian to degree
degree = radian/pi*180;
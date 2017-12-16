% -------------------------------------------------------------------------
%
% File : DynamicWindowApproachSample.m
%
% Discription : Mobile Robot Motion Planning with Dynamic Window Approach
%
% Environment : Matlab
%
% Author : Atsushi Sakai
%
% Copyright (c): 2014 Atsushi Sakai
%
% License : Modified BSD Software License Agreement
% -------------------------------------------------------------------------

function [] = DynamicWindowApproachSample()
 
close all;
clear all;
 
disp('Dynamic Window Approach sample program start!!')

x=[0 0 pi/2 0 0]';%���{�b�g�̏������[x(m),y(m),yaw(Rad),v(m/s),��(rad/s)]
goal=[10,10];%�S�[���̈ʒu [x(m),y(m)]
%��Q�����X�g [x(m) y(m)]
obstacle=[0 2;
          4 2;
          4 4;
          5 4;
          5 5;
          5 6;
          5 9
          8 8
          8 9
          7 9];
      
obstacleR=0.5;%�Փ˔���p�̏�Q���̔��a
global dt; dt=0.1;%���ݎ���[s]

%���{�b�g�̗͊w���f��
%[�ō����x[m/s],�ō��񓪑��x[rad/s],�ō��������x[m/ss],�ō������񓪑��x[rad/ss],
% ���x�𑜓x[m/s],�񓪑��x�𑜓x[rad/s]]
Kinematic=[1.0,toRadian(20.0),0.2,toRadian(50.0),0.01,toRadian(1)];

%�]���֐��̃p�����[�^ [heading,dist,velocity,predictDT]
evalParam=[0.1,0.2,0.1,3.0];
area=[-1 11 -1 11];%�V�~�����[�V�����G���A�̍L�� [xmin xmax ymin ymax]

%�V�~�����[�V��������
result.x=[];
tic;
%movcount=0;
% Main loop
for i=1:5000
    %DWA�ɂ����͒l�̌v�Z
    [u,traj]=DynamicWindowApproach(x,Kinematic,goal,evalParam,obstacle,obstacleR);
    x=f(x,u);%�^�����f���ɂ��ړ�
    
    %�V�~�����[�V�������ʂ̕ۑ�
    result.x=[result.x; x'];
    
    %�S�[������
    if norm(x(1:2)-goal')<0.5
        disp('Arrive Goal!!');break;
    end
    
    %====Animation====
    hold off;
    ArrowLength=0.5;%���̒���
    %���{�b�g
    quiver(x(1),x(2),ArrowLength*cos(x(3)),ArrowLength*sin(x(3)),'ok');hold on;
    plot(result.x(:,1),result.x(:,2),'-b');hold on;
    plot(goal(1),goal(2),'*r');hold on;
    plot(obstacle(:,1),obstacle(:,2),'*k');hold on;
    %�T���O�Օ\��
    if ~isempty(traj)
        for it=1:length(traj(:,1))/5
            ind=1+(it-1)*5;
            plot(traj(ind,:),traj(ind+1,:),'-g');hold on;
        end
    end
    axis(area);
    grid on;
    drawnow;
    %movcount=movcount+1;
    %mov(movcount) = getframe(gcf);% �A�j���[�V�����̃t���[�����Q�b�g����
end
figure(2)
plot(result.x(:,4));
toc
%movie2avi(mov,'movie.avi');
 

function [u,trajDB]=DynamicWindowApproach(x,model,goal,evalParam,ob,R)
%DWA�ɂ����͒l�̌v�Z������֐�

%Dynamic Window[vmin,vmax,��min,��max]�̍쐬
Vr=CalcDynamicWindow(x,model);
%�]���֐��̌v�Z
[evalDB,trajDB]=Evaluation(x,Vr,goal,ob,R,model,evalParam);

if isempty(evalDB)
    disp('no path to goal!!');
    u=[0;0];return;
end

%�e�]���֐��̐��K��
evalDB=NormalizeEval(evalDB);

%�ŏI�]���l�̌v�Z
feval=[];
for id=1:length(evalDB(:,1))
    feval=[feval;evalParam(1:3)*evalDB(id,3:5)'];
end
evalDB=[evalDB feval];

[maxv,ind]=max(feval);%�ł��]���l���傫�����͒l�̃C���f�b�N�X���v�Z
u=evalDB(ind,1:2)';%�]���l���������͒l��Ԃ�

function [evalDB,trajDB]=Evaluation(x,Vr,goal,ob,R,model,evalParam)
%�e�p�X�ɑ΂��ĕ]���l���v�Z����֐�
evalDB=[];
trajDB=[];

for vt=Vr(1):model(5):Vr(2)
    for ot=Vr(3):model(6):Vr(4)
        %�O�Ղ̐���
        [xt,traj]=GenerateTrajectory(x,vt,ot,evalParam(4),model);
        %�e�]���֐��̌v�Z
        heading=CalcHeadingEval(xt,goal);
        dist=CalcDistEval(xt,ob,R);
        vel=abs(vt);
        
        evalDB=[evalDB;[vt ot heading dist vel]];
        trajDB=[trajDB;traj];     
    end
end

function EvalDB=NormalizeEval(EvalDB)
%�]���l�𐳋K������֐�
if sum(EvalDB(:,3))~=0
    EvalDB(:,3)=EvalDB(:,3)/sum(EvalDB(:,3));
end
if sum(EvalDB(:,4))~=0
    EvalDB(:,4)=EvalDB(:,4)/sum(EvalDB(:,4));
end
if sum(EvalDB(:,5))~=0
    EvalDB(:,5)=EvalDB(:,5)/sum(EvalDB(:,5));
end

function [x,traj]=GenerateTrajectory(x,vt,ot,evaldt,model)
%�O�Ճf�[�^���쐬����֐�
global dt;
time=0;
u=[vt;ot];%���͒l
traj=x;%�O�Ճf�[�^
while time<=evaldt
    time=time+dt;%�V�~�����[�V�������Ԃ̍X�V
    x=f(x,u);%�^�����f���ɂ�鐄��
    traj=[traj x];
end

function stopDist=CalcBreakingDist(vel,model)
%���݂̑��x����͊w���f���ɏ]���Đ����������v�Z����֐�
global dt;
stopDist=0;
while vel>0
    stopDist=stopDist+vel*dt;%���������̌v�Z
    vel=vel-model(3)*dt;%�ō�����
end

function dist=CalcDistEval(x,ob,R)
%��Q���Ƃ̋����]���l���v�Z����֐�

dist=2;
for io=1:length(ob(:,1))
    disttmp=norm(ob(io,:)-x(1:2)')-R;%�p�X�̈ʒu�Ə�Q���Ƃ̃m�����덷���v�Z
    if dist>disttmp%�ŏ��l��������
        dist=disttmp;
    end
end

function heading=CalcHeadingEval(x,goal)
%heading�̕]���֐����v�Z����֐�

theta=toDegree(x(3));%���{�b�g�̕���
goalTheta=toDegree(atan2(goal(2)-x(2),goal(1)-x(1)));%�S�[���̕���

if goalTheta>theta
    targetTheta=goalTheta-theta;%�S�[���܂ł̕��ʍ���[deg]
else
    targetTheta=theta-goalTheta;%�S�[���܂ł̕��ʍ���[deg]
end

heading=180-targetTheta;

function Vr=CalcDynamicWindow(x,model)
%���f���ƌ��݂̏�Ԃ���DyamicWindow���v�Z
global dt;
%�ԗ����f���ɂ��Window
Vs=[0 model(1) -model(2) model(2)];

%�^�����f���ɂ��Window
Vd=[x(4)-model(3)*dt x(4)+model(3)*dt x(5)-model(4)*dt x(5)+model(4)*dt];

%�ŏI�I��Dynamic Window�̌v�Z
Vtmp=[Vs;Vd];
Vr=[max(Vtmp(:,1)) min(Vtmp(:,2)) max(Vtmp(:,3)) min(Vtmp(:,4))];
%[vmin,vmax,��min,��max]

function x = f(x, u)
% Motion Model
global dt;
 
F = [1 0 0 0 0
     0 1 0 0 0
     0 0 1 0 0
     0 0 0 0 0
     0 0 0 0 0];
 
B = [dt*cos(x(3)) 0
    dt*sin(x(3)) 0
    0 dt
    1 0
    0 1];

x= F*x+B*u;

function radian = toRadian(degree)
% degree to radian
radian = degree/180*pi;

function degree = toDegree(radian)
% radian to degree
degree = radian/pi*180;
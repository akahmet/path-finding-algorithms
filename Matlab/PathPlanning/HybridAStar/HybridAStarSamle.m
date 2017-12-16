function [] = RRTSample()
%AStarSample() A*�@�ɂ��ŒZ�o�H�T���v���O����
%
% Author: Atsushi Sakai
%
% Copyright (c) 2014, Atsushi Sakai
% All rights reserved.
% License : Modified BSD Software License Agreement

clear all;
close all;
disp('Hybrid A Star Path Planning start!!');

%�p�����[�^
global p;
p.xyTick=1;    %x-y�𑜓x
p.angleTick=5; %�p�x�𑜓x[deg]
p.start=[1, 1];%�X�^�[�g�n�_ [x,y,yaw]
%p.goal =[3,7,90/p.angleTick];%�S�[���n�_   [x,y,yaw]
p.goal =[7,3];%�S�[���n�_   [x,y,yaw]
p.XYMAX=11;     %�}�b�v�̍ő�c��

%���E�f�[�^�̎擾
obstacle=GetBoundary(p);

%��Q���f�[�^�̎擾 ���E�f�[�^�ƍ��킹�Ď擾����

%���ԏ�^��Q���̏ꍇ
obstacle=GetParkingLotObstacle(obstacle);

%�ŒZ�o�H�𐶐�
path=RRT(obstacle);

%�O���t�쐬
figure(1)
hold off;
if length(obstacle)>=1
    plot(obstacle(:,1),obstacle(:,2),'om');hold on;
end
PlotArrow(p.start,p.angleTick);
PlotArrow(p.goal,p.angleTick);
for i=1:length(path(:,1))
    PlotArrow(path(i,:),p.angleTick);hold on;
end
plot(path(:,1),path(:,2),'-r');hold on;
axis([0-0.5 p.XYMAX+1+0.5 0-0.5 p.XYMAX+1+0.5])
grid on;

end

function path=RRT(obstacle)
% A*�@�ɂ���čŒZ�o�H��T������v���O����
% �ŒZ�o�H�̃p�X�̍��W���X�g��Ԃ�
global p;
p.GoalProb=0.5;
findFlag=false;%�S�[�������t���O

tree=[p.start p.start 0];

while ~findFlag
      if rand()>p.GoalProb
        target=p.goal;
      else
        target=GetRandomPosi();
      end
      
      %�p�X�T���̃X�e�b�v����
      %animation(open,close,p,obstacle);
end

%�ŒZ�p�X�̍��W���X�g���擾
path=GetPath(close,p.start)

end

function target=GetRandomPosi()
global p

target=[p.XYMAX*rand() p.XYMAX*rand()];

end

function result=h(a,b)
%�q���[���X�e�B�b�N�֐�
%�����ł͓񎟌���Ԃ�a,b�̃m��������
result=norm(a(1:2)-b(1:2));
%result=norm(a-b);

end

function m=GetNextNode(node,next)
%�אڃm�[�h���v�Z����m�[�h
global p;
node(3)=PI2PI(node(3)+next(3),p.angleTick);
phi=toRadian(node(3)*p.angleTick);
R = [ cos(phi) sin(phi); -sin(phi) cos(phi) ];
xy=next(1:2)*R;
m=[node(1)+xy(1) node(2)+xy(2) node(3)+next(3) node(4)];
m(3)=PI2PI(m(3),p.angleTick);
m(4)=m(4)+next(4)+h(m(1:3),p.goal)-h(node(1:3),p.goal);%�R�X�g�̌v�Z
end

function obstacle=GetObstacle(nob,obstacle,p)
%�����Ŏw�肳�ꂽ���̏�Q�����쐬���A
%�����̒�����X�^�[�gor�S�[���n�_�ɔz�u���ꂽ���̈ȊO��Ԃ��֐�

%�����ŏ�Q�����쐬
ob=round(rand([nob,2])*p.XYMAX);

%�X�^�[�g�n�_�ƃS�[���ɏ�Q�����z�u���ꂽ�ꍇ�͏Ȃ�
removeInd=[];%�폜�����Q���̃C���f�b�N�X�i�[�p���X�g
for io=1:length(ob(:,1))
    if(isSamePosi(ob(io,:),p.start) || isSamePosi(ob(io,:),p.goal))
        removeInd=[removeInd;io];
    end   
end
ob(removeInd,:)=[];%���X�g

obstacle=[obstacle;ob];

end

function result=isSamePosi(a,b)
%3x1�̃x�N�g�����������ǂ����𔻒f����֐�
global p;
result=false;
if length(a)>=3
    d=a(1:3)-b;

    %Map�̉𑜓x���瓯���O���b�h���ǂ������v�Z����
    if abs(d(1))<p.xyTick/2 && abs(d(2))<p.xyTick/2 && abs(d(3))<1
        result=true;
    end
else
    d=a-b(1:2);
    if abs(d(1))<p.xyTick && abs(d(2))<p.xyTick
        result=true;
    end
end

end

function boundary=GetBoundary(p)
% �G���A���E�f�[�^�̎擾
boundary=[];
for i1=0:(p.XYMAX+1)
    boundary=[boundary;[0 i1]];
end
for i2=0:(p.XYMAX+1)
    boundary=[boundary;[i2 0]];
end
for i3=0:(p.XYMAX+1)
    boundary=[boundary;[p.XYMAX+1 i3]];
end
for i4=0:(p.XYMAX+1)
    boundary=[boundary;[i4 p.XYMAX+1]];
end
boundary=[boundary;[11 11]];
boundary=[boundary;[9 1]];
boundary=[boundary;[10 2]];
boundary=[boundary;[11 3]];
boundary=[boundary;[10 1]];
boundary=[boundary;[11 2]];
boundary=[boundary;[11 1]];

end

function animation(open,close,p,obstacle)
% �T���̗l�q�𒀎��I�ɕ\������֐�

figure(1)
hold off;
%if length(obstacle)>=1
%    plot(obstacle(:,1),obstacle(:,2),'om');hold on;
%end
plot3(p.start(1),p.start(2),p.start(3),'*r');hold on;
plot3(p.goal(1),p.goal(2),p.goal(3),'*b');hold on;
plot3(open(:,1),open(:,2),open(:,3),'xr');hold on;
plot3(close(:,1),close(:,2),close(:,3),'xk');hold on;

%axis([0-0.5 p.XYMAX+1+0.5 0-0.5 p.XYMAX+1+0.5])
grid on;
%pause;

end

function flag=isObstacle(m,obstacle)

for io=1:length(obstacle(:,1))
    if isSamePosi(obstacle(io,:),m(1:2))
        flag=true;return;
    end
end
flag=false;%��Q���ł͂Ȃ�
end

function next=MotionModel(tick)
%�אڃm�[�h�ւ̈ړ����f�� �����ς��邱�ƂŃ��{�b�g�̈ړ����w��ł���
% [dx dy dyaw cost]
% next=[1 0    0/tick 1
%       1 1   45/tick 2
%       1 -1  -45/tick 2
%       -1 0   0/tick 3
%       -1 1  45/tick 4
%       -1 -1 -45/tick 4];

movedis=1;
dangle=-30:15:30;
rad=toRadian(dangle);
next=[];
for i=1:length(rad)
    next=[next;[movedis*cos(rad(i)) movedis*sin(rad(i)) -dangle(i)/tick 1]];
end

end

function obstacle=GetParkingLotObstacle(obstacle)
%���ԏ�^�̏�Q���}�b�v���擾����֐�

%�����ŏ�Q�����쐬
ob=[1 6;
    2 6;
    3 6;
    4 6;
    5 6;
    6 6;
    7 6;
    8 6;
    2 7;
    2 8;
    4 7;
    4 8;
    6 7;
    6 8;
    8 7;
    8 8];
obstacle=[obstacle;ob];

end

function [minCostN,minInd]=GetMinCostNode(open)
%open�ȃm�[�h�̒��ōŏ��R�X�g�m�[�h���擾
[Y,I] = sort(open(:,4));
open=open(I,:);
minInd=I(1);
minCostN=open(1,:);
end

function path=GetPath(close,start)
%�X�^�[�g����S�[���܂ł̍��W���X�g���擾����֐�
ind=1;%goal��close���X�g�̐擪�ɓ����Ă���
path=[];
while 1
    %���W�����X�g�ɓo�^
    path=[path; close(ind,1:3)];
    
    %�X�^�[�g�n�_�܂œ��B���������f
    if isSamePosi(close(ind,1:3),start)   
        break;
    end
    
    %close���X�g�̒��Őe�m�[�h��T��
    for io=1:length(close(:,1))
        if isSamePosi(close(io,1:3),close(ind,5:7))
            ind=io;
            break;
        end
    end
end

end

function [flag, targetInd]=FindList(m,open,close)
    targetInd=0;
    %open���X�g�ɂ��邩?
    if ~isempty(open)
        for io=1:length(open(:,1))
            if isSamePosi(open(io,:),m(1:3))
                flag=1;
                targetInd=io;
                return;
            end
        end
    end
    %close���X�g�ɂ��邩?
    if ~isempty(close)
        for ic=1:length(close(:,1))
            if isSamePosi(close(ic,:),m(1:3))
                flag=2;
                targetInd=ic;
                return;
            end
        end
    end
    %�ǂ���ɂ���������
    flag=3;return;
end

function angle=PI2PI(angle,tick)
    angledeg=angle*tick;
    while angledeg>180
        angledeg=angledeg-360;
    end
    while angledeg<-180
        angledeg=angledeg+360;
    end
    angle=angledeg/tick;
end

function PlotArrow(x,tick)
ArrowLength=0.5;%���̒���
yaw=x(3)*tick*pi/180;
quiver(x(1),x(2),ArrowLength*cos(yaw),ArrowLength*sin(yaw),'ok');hold on;
end   

function radian = toRadian(degree)
% degree to radian
radian = degree/180*pi;
end
    
function deg = toDegree(radian)
% radian to deg
deg = radian*180/pi;
end




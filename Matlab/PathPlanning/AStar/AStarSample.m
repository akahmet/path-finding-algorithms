function [] = AStarSample()
%AStarSample() A*�@�ɂ��ŒZ�o�H�T���v���O����
%
% Author: Atsushi Sakai
%
% Reference:A*�ɂ��ŒZ�o�H�T��MATLAB�v���O���� - MY ENIGMA 
%           http://d.hatena.ne.jp/meison_amsl/20140503/1399080847
%
% Copyright (c) 2014, Atsushi Sakai
% All rights reserved.
% License : Modified BSD Software License Agreement

clear all;
close all;
disp('A Star Path Planning start!!');

%�p�����[�^
p.start=[1,1];  %�X�^�[�g�n�_
p.goal=[10,3];  %�S�[���n�_
p.XYMAX=11;     %�}�b�v�̍ő�c��

%���E�f�[�^�̎擾
obstacle=GetBoundary(p);

%��Q���f�[�^�̎擾 ���E�f�[�^�ƍ��킹�Ď擾����
nObstacle=20;%��Q���̐�
obstacle=GetObstacle(nObstacle,obstacle,p);

%�ŒZ�o�H�𐶐�
path=AStar(obstacle,p);

%�O���t�쐬
figure(1)
if length(obstacle)>=1
    plot(obstacle(:,1),obstacle(:,2),'om');hold on;
end
plot(p.start(1),p.start(2),'*r');hold on;
plot(p.goal(1),p.goal(2),'*b');hold on;
if length(path)>=1
    plot(path(:,1),path(:,2),'-r');hold on;
end
axis([0-0.5 p.XYMAX+1+0.5 0-0.5 p.XYMAX+1+0.5])
grid on;

end

function path=AStar(obstacle,p)
% A*�@�ɂ���čŒZ�o�H��T������v���O����
% �ŒZ�o�H�̃p�X�̍��W���X�g��Ԃ�

path=[];%�p�X
%�v�Z���m�[�h���i�[�p[x,y,cost,px(�e�m�[�h),py(�e�m�[�h)] start�m�[�h���i�[����
open=[p.start(1) p.start(2) h(p.start,p.goal) p.start(1) p.start(2)];
close=[];%�v�Z�ς݃m�[�h���i�[�p

%�אڃm�[�h�ւ̈ړ����f�� �����ς��邱�ƂŃ��{�b�g�̈ړ����w��ł���
next=MotionModel();

findFlag=false;%�S�[�������t���O

while ~findFlag
      %open�Ƀf�[�^���Ȃ��ꍇ�̓p�X��������Ȃ������B  
      if isempty(open(:,1)) disp('No path to goal!!'); return; end
      %open�ȃm�[�h�̒��ōł��R�X�g�����������̂�I��
      [Y,I] = sort(open(:,3));
      open=open(I,:);
      
      %�S�[������
      if isSamePosi(open(1,1:2),p.goal)
          disp('Find Goal!!');
          %�S�[���̃m�[�h��Close�̐擪�Ɉړ�
          close=[open(1,:);close];open(1,:)=[];
          findFlag=true;
          break;
      end
      
      for in=1:length(next(:,1))
          %�אڃm�[�h�̈ʒu�ƃR�X�g�̌v�Z
          m=[open(1,1)+next(in,1) open(1,2)+next(in,2) open(1,3)];
          m(3)=m(3)+next(in,3)+h(m(1:2),p.goal)-h(open(1,1:2),p.goal);%�R�X�g�̌v�Z
          
          %�אڃm�[�h����Q���������玟�̃m�[�h��T��
          if isObstacle(m,obstacle) continue; end
          
          %open��close�̃��X�g�̒���m���܂܂�邩��T��
          [flag, targetInd]=FindList(m,open,close);

          if flag==1 %open���X�g�ɂ���ꍇ
              if m(3)<open(targetInd,3)
                  open(targetInd,3)=m(3);
                  open(targetInd,4)=open(1,1);
                  open(targetInd,5)=open(1,2);
              end
          elseif flag==2 %close���X�g�ɂ���ꍇ
              if m(3)<close(targetInd,3)
                  %�e�m�[�h�̍X�V
                  close(targetInd,4)=open(1,1);
                  close(targetInd,5)=open(1,2);
                  open=[open; close(targetInd,:)];
                  close(targetInd,:)=[];%Open���X�g�Ɉړ�
              end
          else %�ǂ���ɂ������ꍇ
              %open���X�g�ɐe�m�[�h�̃C���f�b�N�X�Ƌ��ɒǉ�
              open=[open;[m open(1,1) open(1,2)]];
          end
      end

      %�אڃm�[�h�v�Z����open�m�[�h��close�m�[�h�ֈړ�
      if findFlag==false
          close=[close; open(1,:)];
          open(1,:)=[];
      end
      
      %�p�X�T���̃X�e�b�v����
      %animation(open,close,p,obstacle);

end

%�ŒZ�p�X�̍��W���X�g���擾
path=GetPath(close,p.start);

end

function result=h(a,b)
%�q���[���X�e�B�b�N�֐�
%�����ł͓񎟌���Ԃ�a,b�̃m��������
result=norm(a-b);

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
%2x1�̃x�N�g�����������ǂ����𔻒f����֐�
result=false;
if a(1)==b(1) && a(2)==b(2)
    result=true;
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
if length(obstacle)>=1
    plot(obstacle(:,1),obstacle(:,2),'om');hold on;
end
plot(p.start(1),p.start(2),'*r');hold on;
plot(p.goal(1),p.goal(2),'*b');hold on;
plot(open(:,1),open(:,2),'xr');hold on;
plot(close(:,1),close(:,2),'xk');hold on;

axis([0-0.5 p.XYMAX+1+0.5 0-0.5 p.XYMAX+1+0.5])
grid on;
pause;

end

function flag=isObstacle(m,obstacle)

for io=1:length(obstacle(:,1))
    if isSamePosi(obstacle(io,:),m(1:2))
        flag=true;return;
    end
end
flag=false;%��Q���ł͂Ȃ�
end

function next=MotionModel()
%�אڃm�[�h�ւ̈ړ����f�� �����ς��邱�ƂŃ��{�b�g�̈ړ����w��ł���
% [x y cost]
next=[1 1 1
      1 0 1
      0 1 1
      -1 0 1
      0 -1 1
      -1 -1 1
      -1 1 1
      1 -1 1];
end

function path=GetPath(close,start)
%�X�^�[�g����S�[���܂ł̍��W���X�g���擾����֐�
ind=1;%goal��close���X�g�̐擪�ɓ����Ă���
path=[];
while 1
    %���W�����X�g�ɓo�^
    path=[path; close(ind,1:2)];
    
    %�X�^�[�g�n�_�܂œ��B���������f
    if isSamePosi(close(ind,1:2),start)   
        break;
    end
    
    %close���X�g�̒��Őe�m�[�h��T��
    for io=1:length(close(:,1))
        if isSamePosi(close(io,1:2),close(ind,4:5))
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
            if isSamePosi(open(io,:),m(1:2))
                flag=1;
                targetInd=io;
                return;
            end
        end
    end
    %close���X�g�ɂ��邩?
    if ~isempty(close)
        for ic=1:length(close(:,1))
            if isSamePosi(close(ic,:),m(1:2))
                flag=2;
                targetInd=ic;
                return;
            end
        end
    end
    %�ǂ���ɂ���������
    flag=3;return;
end
    

    




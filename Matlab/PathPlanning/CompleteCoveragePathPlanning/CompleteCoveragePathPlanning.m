function [] = CompleteCoveragePathPlanning()
clear all;
close all;
disp('CompleteCoveragePathPlanning start!!');

%�p�����[�^
p.start=[1,1];  %�X�^�[�g�n�_
p.goal=[10,10]; %�S�[���n�_
p.XYMAX=11;     %�}�b�v�̍ő�c��

%Map�̏������@Unknown=inf
map=zeros(p.XYMAX,p.XYMAX)+inf;

%�S�[�����R�X�g0�ɐݒ�
map(p.goal(1),p.goal(2))=0;

%���E�f�[�^�̎擾
p=GetBoundary(p);

%��Q���f�[�^
p.obstacle=[];
%p.obstacle=[3 3];
%p.obstacle=[3 3;5 7];
p.obstacle=[3 1;3 2;3 3;3 4;3 5;3 6;7 7];

%Map��Distance transform
%map=DistanceTransform(map,p);

%Obstacle Transform
map=PathTransform(map,p);

%�ŒZ�o�H�𐶐�
sind=ComputeShortestPath(map,p);

%�J�o���[�W�p�X�̐���
cind=ComputeCoveragePath(map,p);

%�p�X�̃X�e�b�v����
animation(cind,p);

%�O���t�쐬
figure(1)
plot(p.boundary(:,1),p.boundary(:,2),'xk');hold on;
if length(p.obstacle)>=1
    plot(p.obstacle(:,1),p.obstacle(:,2),'om');hold on;
end
plot(p.start(1),p.start(2),'*r');hold on;
plot(p.goal(1),p.goal(2),'*b');hold on;
plot(cind(:,1),cind(:,2),'-b');hold on;
plot(sind(:,1),sind(:,2),'-r');hold on;
axis([0-0.5 p.XYMAX+1+0.5 0-0.5 p.XYMAX+1+0.5])
grid on;

end

function map=PathTransform(map,p)

obmap=ObstacleTransform(map,p);

while(1)
    maptmp=map;%�Q�Ɨp�ɃR�s�[
    for ix=1:p.XYMAX
        for iy=1:p.XYMAX
            for incx=-1:1
                for incy=-1:1
                    %�Q�Ɛ�̃O���b�h�̃C���f�b�N�X
                    indx=ix+incx;
                    indy=iy+incy;
                    
                    %�������g���Q�Ƃ��Ă�����X�L�b�v
                    if (incx==0)&&(incy==0) continue;end
                    
                    %�C���f�b�N�X���I�[�o�t���[������X�L�b�v
                    if(indx<=0||indx>p.XYMAX) continue;end
                    if(indy<=0||indy>p.XYMAX) continue;end
                    
                    %�ڕW�̃O���b�g��inf�ȊO�̏ꍇ
                    if maptmp(indx,indy)~=inf
                        c=maptmp(indx,indy)+1+1/obmap(ix,iy);
                        if c<=map(ix,iy) map(ix,iy)=c; end;
                    end
                end
            end
        end
    end
    %Start�n�_�܂ŒT������
    if map(p.start(1),p.start(2))~=inf break; end;
end

end

function map=ObstacleTransform(map,p)
%���ׂẴO���b�g�ɑ΂��āA��Q���Ƃ̋������v�Z���A���̍ŏ��l���i�[����

%���E�f�[�^�Ə�Q���f�[�^���i�[
ob=[p.boundary;p.obstacle];
for ix=1:p.XYMAX
    for iy=1:p.XYMAX
        n=[];
        for io=1:length(ob(:,1))
            n=[n norm(ob(io,:)-[ix iy])];
        end
        map(ix,iy)=min(n);
    end
end

end

function p=GetBoundary(p)
p.boundary=[];
for i1=0:(p.XYMAX+1)
    p.boundary=[p.boundary;[0 i1]];
end
for i2=0:(p.XYMAX+1)
    p.boundary=[p.boundary;[i2 0]];
end
for i3=0:(p.XYMAX+1)
    p.boundary=[p.boundary;[p.XYMAX+1 i3]];
end
for i4=0:(p.XYMAX+1)
    p.boundary=[p.boundary;[i4 p.XYMAX+1]];
end
p.boundary=[p.boundary;[11 11]];
p.boundary=[p.boundary;[9 1]];
p.boundary=[p.boundary;[10 2]];
p.boundary=[p.boundary;[11 3]];
p.boundary=[p.boundary;[10 1]];
p.boundary=[p.boundary;[11 2]];
p.boundary=[p.boundary;[11 1]];

end

function animation(ind,p)

for i=1:length(ind(:,1))
    hold off;
    plot(p.boundary(:,1),p.boundary(:,2),'xk');hold on;
    if length(p.obstacle)>=1
        plot(p.obstacle(:,1),p.obstacle(:,2),'og');hold on;
    end
    plot(p.start(1),p.start(2),'*r');hold on;
    plot(p.goal(1),p.goal(2),'*b');hold on;
    plot(ind(i,1),ind(i,2),'*r');hold on;
    plot(ind(1:i,1),ind(1:i,2),'-b');hold on;
    axis([0-0.5 p.XYMAX+1+0.5 0-0.5 p.XYMAX+1+0.5])
    grid on;
    pause;
end

end

function indresult=ComputeCoveragePath(map,p)

indresult=[];
ix=p.start(1);
iy=p.start(2);
while(1)
    result=[];
    indresult=[indresult;[ix iy]];
    map(ix,iy)=-1;
    for incx=-1:1
        for incy=-1:1
            indx=ix+incx;
            indy=iy+incy;
            
            %�������g���Q�Ƃ��Ă�����X�L�b�v
            if (incx==0)&&(incy==0) continue;end
 
            %�C���f�b�N�X���I�[�o�t���[������X�L�b�v
            if(indx<=0||indx>p.XYMAX) continue;end
            if(indy<=0||indy>p.XYMAX) continue;end
            
            if (map(indx,indy)>=0)&&(map(indx,indy)~=inf)
                result=[result;[map(indx,indy) indx indy]];
            end
        end
    end
    %���[�J���~�j�}
    if length(result)==0
        disp('local minima!!');
        map(indresult(end-1,1),indresult(end-1,2))=100;
        continue;
        %break;
    end
    rsize=size(result(:,1));
    %result
    %indresult
    %result������������Ƃ�
    if rsize(1,1)~=1
        [mi mj]=max(result);
        ix=result(mj(1),2);
        iy=result(mj(1),3);
    else
        ix=result(1,2);
        iy=result(1,3);
    end
    if ix==p.goal(1)&&iy==p.goal(2)
        indresult=[indresult;[ix iy]];
        break;
    end
end

end

function indresult=ComputeShortestPath(map,p)
indresult=[];
ix=p.start(1);
iy=p.start(2);
while(1)
    result=[];
    indresult=[indresult;[ix iy]];
    for incx=-1:1
        for incy=-1:1
            indx=ix+incx;
            indy=iy+incy;
            
            %�������g���Q�Ƃ��Ă�����X�L�b�v
            if (incx==0)&&(incy==0) continue;end
            
            %�C���f�b�N�X���I�[�o�t���[������X�L�b�v
            if(indx<=0||indx>p.XYMAX) continue;end
            if(indy<=0||indy>p.XYMAX) continue;end
            
            result=[result;[map(indx,indy) indx indy]];
        end
    end
    [mi mj]=min(result);
    ix=result(mj(1),2);
    iy=result(mj(1),3);
    
    if ix==p.goal(1)&&iy==p.goal(2)
        indresult=[indresult;[ix iy]];
        break;
    end
    
end

end

function map=DistanceTransform(map,p)

while(1)
    maptmp=map;%�Q�Ɨp�ɃR�s�[
    for ix=1:p.XYMAX
        for iy=1:p.XYMAX
            for incx=-1:1
                for incy=-1:1
                    indx=ix+incx;
                    indy=iy+incy;
                    
                    %�������g���Q�Ƃ��Ă�����X�L�b�v
                    if (incx==0)&&(incy==0) continue;end
                    
                    %�C���f�b�N�X���I�[�o�t���[������X�L�b�v
                    if(indx<=0||indx>p.XYMAX) continue;end
                    if(indy<=0||indy>p.XYMAX) continue;end
                    
                    %�J�����g�O���b�g��inf�ŖڕW�̃O���b�g��inf�ȊO�̏ꍇ
                    if maptmp(indx,indy)~=inf&&(map(ix,iy)==inf)
                        map(ix,iy)=maptmp(indx,indy)+1;
                    end
                end
            end
        end
    end
    %Start�n�_�܂ŒT������
    if map(p.start(1),p.start(2))~=inf break; end;
end

end


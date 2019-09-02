#创建lvm 并挂载的脚本. 不用顾忌其它所有问题.
#这个脚本预设前面的所有事情已经搞定. 只看最终结果有没有完成来回报输出
#! /bin/bash



set -- `getopt  yd:v:l:m: "$@"`
#y 无需确认
#d disk 硬盘
#v vgname
#l lvname

#m mvdir 将已存在的目录移动到磁盘中,并且挂载到参数给定目录
#sh createmount.sh [options(-y -d /dev/sdb -v vgspace -l lvspace )] [parameter(/www)]


while [ -n "$1"  ]
do
	
	case "$1" in 
	-y) echo "静默模式"
		confirm=y;;
	-d) 
	#echo "disk磁盘-> $2"
		disk=$2
		shift;;
	#-p) echo "path挂载路径-> $2"
	#	shift;;
	-v)
	# echo "vgname vg名 -> $2"
		vgname=$2
		shift;;
	-l)
	# echo "lvname lv名 -> $2"
		lvname=$2
		shift;;
	-m) echo "移动$mvpath 至硬盘"
		mvdir=y
		mvpath=$2
		shift;; 		

	--)shift
		break;;

	*) echo "$1 不是选项"
	esac
	shift
	
done





if [ $disk  ];then
	disk=$disk
	echo "[已选]"
else
	disk=/dev/sdb
	echo "[默认]"
fi
echo "操作的硬盘为$disk"


if [ $vgname  ];then
	vgname=$vgname
	echo "[已选]"
else
	vgname=vgspace
	echo "[默认]"
fi
echo "卷组名为$vgname"


if [ $lvname ];then
	lvname=$lvname
	echo "[已选]"
else
	lvname=lvspace
	echo "[默认]"
fi
echo "逻辑卷名为$lvname"

if [ $1 ];then
        dir=$1
        echo "[已选]"
else
        dir=/www
        echo "[默认]"
fi
echo "挂载硬盘至$dir"

if [ "$mvdir"x = "y"x ];then
	echo "[已选]"
	tmp=/tmp$mvpath
	mkdir -p $tmp	
else
	echo "[默认(不进行)]"
fi
echo "移动$mvpath 中的所有文件至硬盘并挂载"



lvmpath=/dev/${vgname}/${lvname}


#disk=/dev/sdb
#if /www已经存在 需要询问是否覆盖
#dir=/www

#vgname=vgspace
#lvname=lvspace



if [ -d  $dir   ];then
	if [ $tmp ];then
		echo "正在将$mvpath 目录移动至硬盘[y/n]"
		if [ "$confirm"x = "y"x ];then
			echo "静默模式,skip input"
		else
			read -n 1 -p "mv $mvpath to $lvmpath now! press [y/n] to continue." confirm 
		fi 
	else
		echo "$dir 目录已经存在,是否覆盖挂载上去 [y/n]"
	
		if [ "$confirm"x = "y"x ];then
			echo "静默模式,skip input" 
		else
			read -n 1 -p "$dir is exists!press [y/n] to overwrite this dir!" confirm 
		fi
	fi	
	
	if [ "$confirm"x = "y"x  ];then 
		echo "overwrite $dir /move  $mvpath now.覆盖/移动该目录"		
	else	
		echo "cancel. 取消操作.(ERROR 2)"
		exit 2 
	fi

else
	mkdir $dir 
fi








#其实这里有点冗余. 可以不用设置这个.不过估计ubuntu可能会需要用到. 所以就加这么一段吧
num=`ls ${disk}* | wc |awk '{print $1}'`
if [ $num -ne 1  ] ;then
	echo "已经有分区存在或者没有sdb盘.此脚本必须在清空所有分区的情况下才能使用"
	exit 1
fi 


#之前其它的脚本会在此处加ddd .这里这一步暂且略过
echo "n
p
1
2048


w
"|fdisk $disk 

pvcreate "${disk}1"
vgcreate $vgname "${disk}1"
echo y|lvcreate -l 100%VG  -n $lvname $vgname

echo y|mkfs.ext4 $lvmpath

cp /etc/fstab /etc/fstab.bak

echo "${lvmpath}	${dir}	ext4	defaults	0 0" >>/etc/fstab

if [ $tmp ];then
	mount $lvmpath $tmp
	mv -f  $mvpath/* $tmp
	echo "已将$mvpath 移动至$lvmpath 中,进行下一步"
	umount $lvmpath	
fi
	

mount $lvmpath 

if [ $? -eq 0 ];then
	echo "成功把$lvmpath 挂载至$dir"
	exit 0
else
	echo "mount ${lvmpath} 命令失败.请手动检查问题"
	#挂载失败的情况下删除最后一行避免重启失败
	sed -i '$d' /etc/fstab	
	exit 3
fi






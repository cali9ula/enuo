#创建lvm 并挂载的脚本. 不用顾忌其它所有问题.
#这个脚本预设前面的所有事情已经搞定. 只看最终结果有没有完成来回报输出
#! /bin/bash



set -- `getopt  y "$@"`
#y 无需确认
#d disk 硬盘
#p path 挂载的路径
#v vgname
#l lvname



disk=/dev/sdb
#if /www已经存在 需要询问是否覆盖
dir=/www

vgname=vgspace
lvname=lvspace
lvmpath=/dev/${vgname}/${lvname}


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

echo "${lvmpath}	${dir}	ext4	defaults	0 0" >>/etc/fstab

mount $lvmpath

if [ $? -eq 0 ];then
	echo "成功把$lvmpath挂载至$dir"
	exit 0
else
	echo "mount ${lvmpath} 命令失败.请手动检查问题"
	exit 2
fi






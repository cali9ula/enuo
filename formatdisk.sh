#! /bin/bash
#默认硬盘设置为/dev/sdb. 有想作死的也可以改成sda

set -- `getopt  y "$@"`

#如果有选项则根据选项来操作
while [ -n $1 ]
do
		case "$1" in 
		-y) echo "静默允许删除操作"
			confirm=y;;
		--) shift
				break;;
		*) echo "$1 没有这个选项";;
		esac
		shift
done

#排除掉选项后如果仍有参数则为路径
if [ $1 ];then
		disk=$1
else
		disk=/dev/sdb
fi

if [ -e $disk ];then
		#这里说明找到了这个路径,不过也没啥好做的
		#pass
		echo "找到$disk 文件,下一步"
else
		echo "未找到$disk 这个路径.取消操作(ERROR  1)"
		exit 1
fi

echo "此程序将会删除$disk 下的所有数据,请键入[y/n]来继续操作"
if [ "$confirm"x = "y"x  ];then
		echo "静默模式, skip input"
else
		read -n 1 -p "It's FORMAT $disk DELETE ALL DATA now! press [y/n] to continue!" confirm
fi


if [  "$confirm"x = "y"x ];then 
		echo "FORMAT $disk ALL DATA ,正在删除该目录下所有数据并格式化"
else
		echo "cancel. 取消操作.(ERROR 2)"
		exit 2 
fi

fuser -v >/dev/null 
if [ $? -eq 127 ];then
	yum install -y psmisc
fi

#yum install -y psmisc

for partion in `ls $disk*`
do
	if [ $partion  ]
	then 
		#找到pv之上的vg
		vgpth=`pvs|grep $partion |awk '{print $2}'`
		
		if [ $vgpth ]
		then 
		
			#找到vg之上的lv
			lvpth=`lvs |grep $vgpth|awk '{print $1}'`
			
			#拼接出完整的lvmpath
			lvmpath=/dev/$vgpth/$lvpth
			
			#如果确实有lvmpath
			cat /etc/fstab|grep "$lvmpath"
			if [ $? -eq 0 ]
			then
				#备份 /etc/fstab 后,注释掉带lvmpath的一行. 避免重启挂掉
				echo y|cp /etc/fstab /etc/fstab.bak
				#给这一行加注释
				tmp=`echo $lvmpath | sed 's|\/|\\\/|g'`
				sed -i "s|^$tmp|#&|" /etc/fstab				

				#sed -i "s/^$lvmpath/#&/" /etc/fstab
				#后期弃用fstab作为开机挂载方式. 改用开机自启动的脚本来使用mount命令
			fi
			
			#如果上面的安装没有成功的话.这一步会报错,就得修改fstab文件然后重启了
			fuser -km $lvmpath
			umount $lvmpath
			dmsetup remove $lvmpath
			wipefs -af $lvmpath
			echo y|lvremove $vgpth/$lvpth
			
		fi
		echo y|vgremove $vgpth
	fi
	echo y|pvremove $partion
	echo y|mkfs.ext4  $partion
	wipefs -af $partion
	#sed -i "s/^$partion/#&/" /etc/fstab
	tmp=`echo $partion |sed 's|\/|\\\/|g'`
        sed -i "s|^$tmp|#&|" /etc/fstab	

done


#直接使用mkfs.ext4 /dev/sdb就可以删除其上所有分区 
#wipefs -af /dev/sdb 也可以
echo y|mkfs.ext4  $disk
wipefs -af $disk

#到此结束 删除所有分区
exit 0

#! /bin/bash
#默认硬盘设置为/dev/sdb. 有想作死的也可以改成sda
disk=/dev/sdb
yum install -y psmisc


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
				sed -i 's/^$lvmpath/#&/' /etc/fstab
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
done


#直接使用mkfs.ext4 /dev/sdb就可以删除其上所有分区 
#wipefs -af /dev/sdb 也可以
echo y|mkfs.ext4  $disk
wipefs -af $disk

#到此结束 删除所有分区
exit 0
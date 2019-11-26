#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# 该脚本用于屏蔽多次登录失败的ip.
# 注意! 若一个ip成功登录过.就会加入白名单.以避免误伤
# Define 参数为登录失败次数.登录失败超过这个次数就会加入黑名单
DEFINE="20"



nowdir=$(cd `dirname $0`; pwd)

grep "$(basename $0)" /etc/crontab
if [ $? -ne 0 ] ; then
        echo  "*/10 * * * * root sh $nowdir/$(basename $0) ; echo $?  \`date\`  >>/etc/crontab.log">> /etc/crontab
fi


# hostpath 黑白名单的根目录
hostpath="/etc/script/hosts"
#mkdir -v $hostpath >/dev/null
if [ ! -d $hostpath ] ;then
	mkdir $hostpath -p
else
	echo $hostpath exits.
fi


# blackpath whitepath 即指向白名单黑名单所在位置
blackpath="$hostpath/black.txt"
whitepath="$hostpath/white.txt"



cat /var/log/secure|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}' > $blackpath

for i in `cat  $blackpath`
do
	IP=`echo $i |awk -F= '{print $1}'`
	NUM=`echo $i|awk -F= '{print $2}'`
	if [ $NUM -gt $DEFINE ];then
		grep $IP /etc/hosts.deny > /dev/null
		if [ $? -gt 0 ];then
			echo "sshd:$IP:deny" >> /etc/hosts.deny
		fi
	fi
done

cat /var/log/secure|awk '/Accepted/{print $(NF-3)}'|uniq > $whitepath

for ip in `cat  $whitepath`
do
	grep "$ip" /etc/hosts.allow >/dev/null 
	if [ $? -ne 0 ] ;then
		
		echo "sshd:$ip:allow">>/etc/hosts.allow
	fi
done





while [ -n "$1" ]
do
		case "$1" in 
		-f) echo "静默";;
		-y) echo "确定";;
		-a) echo "自动";;
		--) shift
				break;;
		*) echo "错误的选项";;
		esac
		shift
done

count=1 
for param in $@
do
		echo "选项 #$count:$param"
		count=$[ $count+1 ]
done




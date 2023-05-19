#!/bin/bash
basedir=$(cd `dirname $0` && pwd)
if [ $(uname -a|awk -F 'el' '{print $2}'|awk -F '.' '{print $1}') == 7 ];then
	 sshpass &>/dev/null || yum -y localinstall $basedir/sshpass-1.06-2.el7.x86_64.rpm &>/dev/null
elif [ $(uname -a|awk -F 'el' '{print $2}'|awk -F '.' '{print $1}') == 6 ];then
	sshpass &>/dev/null || yum -y localinstall $basedir/$basedir/sshpass-1.06-2.el6.x86_64.rpm &>/dev/null
else
	echo '没有符合该操作系统版本的sshpass软件包安装'
fi
docker_install_linux7(){
	#安装目录不存在则创建该目录
	sshpass -p "$passwd" ssh -p $sshport root@$ip -o StrictHostKeyChecking=no " [ -d $installationdir ] || mkdir -p $installationdir"
	sshpass -p "$passwd" scp -P $sshport -o StrictHostKeyChecking=no -r $basedir/docker_rpm7 root@$ip:$installationdir
	starttime=$(date +"%F %T")
	echo "当前时间为:$starttime,正在通过rpm方式安装docker,请耐心等待不要退出"
	sshpass -p "$passwd" ssh -p $sshport root@$ip -o StrictHostKeyChecking=no "
	yum -y localinstall /home/docker_rpm7/*.rpm &>/dev/null
	cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
	sysctl -p &>/dev/null
	cat > /etc/docker/daemon.json <<EOF
{
	\"data-root\":\"$installationdir/docker\",
	\"registry-mirrors\":[\"https://hub.mirror.c.163.com\"]
}
EOF
	systemctl daemon-reload && systemctl enable docker &>/dev/null && systemctl start docker && echo 'docker启动成功' || echo 'docker启动失败'
	"
	endtime=$(date +"%F %T")
	interval=$[$(date +%s -d "$endtime")-$(date +%s -d "$starttime")]
	echo "当前时间为：$endtime,安装启动耗时:${interval}s"
}		
cat <<EOF
-----------------
1、安装docker
2、安装k8s master
3、安装k8s worker
4、k8s worker加入k8s master集群
-----------------
EOF

read -p "请选择您需要安装的软件(1-2):" choose

case $choose in 
	1)
	read -p '请输入安装docker的服务器ip地址:' ip
        read -p '请输入安装docker的服务器root用户密码:' passwd
        read -p '请输入安装docker的服务器ssh端口：' sshport
	read -p '请输入安装路径:' installationdir
	sshpass -p "$passwd" ssh -p $sshport -o StrictHostKeyChecking=no root@$ip '[ "$(rpm -qa |grep docker)" &>/dev/null ]' && echo '请检查docker是否已安装,如需卸载重装执行命令rpm -qa|grep docker|xargs rpm -e --nodeps' && exit
	[ "$(sshpass -p "$passwd" ssh -p $sshport -o StrictHostKeyChecking=no root@$ip uname -a|awk -F 'el' '{print $2}'|awk -F '.' '{print $1}')" == 7 ] && 
	echo "当前操作系统版本为7,执行对应安装方法" && docker_install_linux7 || echo "当前操作系统版本不支持使用该脚本安装该软件"

;;
	2)
	echo "bbb"
;;
	*)
	echo "您输入的选项不在可选范围内,请输入可选范围内的选项"
	exit
;;
esac



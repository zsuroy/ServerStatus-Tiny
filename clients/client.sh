#!/bin/bash

SERVER="http://192.168.1.4/debug/stats/" # api_url: begin with "http(s)" or only ip address(domain)
PORT=35601
USER="SUE-4" # hostname
PASSWORD="123" # the verified password
INTERVAL=1 # Update interval

BACKENDMODE=0 # 后端模式: 0启动
SOURCEID=1  # 网络通讯正常测试源 [0: GFW, 1; CN]
SERVERINFO="\"name\":\"Nova4e\",\"type\":\"termux\",\"host\":\"${USER}\",\"location\":\"CN\",\"region\":\"CN\",\"custom\":\"\","

# adapted for termux
is_termux () {
  echo $PATH | grep "termux" &> /dev/null
  stats=$?
  if [ $stats != 0 ]; then
    echo "[Normal]"
  else
    echo "[Termux]"
  fi
  return $stats
}

# connect test
connect_test () {
  SOURCEID=$1
  CHECK_IP=$2
  if [ $SOURCEID == 0 ]; then
    IP6_ADDR="2001:4860:4860::8888"
    IP4_ADDR="8.8.8.8"
  else
    IP6_ADDR="ipv6.test-ipv6.com"
    IP4_ADDR="ipv4.test-ipv6.com"
  fi
  case $CHECK_IP in
    4)
      if ping -i 0.2 -c 3 -w 3 $IP4_ADDR &> /dev/null; then
        Online="\"online4\":true,"
      else
        curl "https://suroy.cn/ping.html" &> /dev/null
        if [ $? == 0 ]; then
            Online="\"online4\":true,"
        else
            Online="\"online4\":false,"
        fi
      fi
    ;;
    *)
      if ping6 -i 0.2 -c 3 -w 3 $IP6_ADDR &> /dev/null; then
        Online="\"online6\":true,"
      else
        Online="\"online6\":false,"
      fi
    ;;
  esac
  echo $Online
}

server_update () {
  payload="$1"
  # define api
  SERVER_API="$SERVER/app.php?mod=update&host=$USER&psk=$PASSWORD&t=$(date '+%s')"
  curl -H 'Content-Type: application/json' -A 'Mozilla/5.0 (Linux; ServerStatus; Tiny) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36' -X POST -d "${payload}" ${SERVER_API}
  echo "[update]"
}

command_exists () {
	type "$1" &> /dev/null ;
}

if command_exists netcat; then
	NETBIN="netcat"
elif command_exists nc; then
	NETBIN="nc"
elif [ $BACKENDMODE == 0 ]; then
  echo "---[backend]---"
else
	echo "netcat not found, install it."
	exit 1
fi

RUNNING=true
clean_up () {
	echo "Quit." >&2
	RUNNING=false
	rm -f status.log
}

trap clean_up SIGINT SIGTERM EXIT
STRING=""

while $RUNNING; do
	rm -f status.log
	PREV_TOTAL=0
	PREV_IDLE=0
	AUTH=true
	TIMER=0
	# default ipv6
  echo 4 > status.log

	while $RUNNING; do
		if $AUTH; then
			echo "${USER}:${PASSWORD}"
			AUTH=false
		fi
		sleep $INTERVAL
		if ! $RUNNING; then
			exit 0
		fi

		# Connectivity
		if [ $TIMER -le 0 ]; then
			if [ -f status.log ]; then
				CHECK_IP=$(<status.log)
				Online=$(connect_test $SOURCEID $CHECK_IP)
				case $CHECK_IP in
				  4)
				    Online4=${Online}
				    Online6=$(connect_test $SOURCEID 6)
					;;
          *)
            Online6=${Online}
            Online4=$(connect_test $SOURCEID 4)
				  ;;
				esac
				Online="${Online4}${Online6}"
				echo $Online
        TIMER=10
			fi
		else
			let TIMER-=1*INTERVAL
		fi

		# Uptime
		Uptime=$(awk '{ print int($1) }' /proc/uptime)
    if [ $? != 0 ]; then
        # 13:23  up 21 days, 13:18, 3 users, load averages: 1.96 2.15 2.49
        Uptime=`uptime | awk '{print $3,$4,$5}' | sed 's/,$//' | sed 's/ //g' | sed 's/,//g'`
        Uptime='"'$Uptime'"'
    fi


		# Load Average
		Load=$(awk '{ print $1 }' /proc/loadavg) &> /dev/null
    if [ $? != 0 ]; then
        Load=`uptime | awk '{ print $NF-1}'`
    fi

		# Memory
		MemTotal=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
		if [ $? != 0 ]; then
		    MemTotal=`free -h | grep Mem | awk '{print $2}'`
		    if [ $? != 0 ]; then
		        MemTotal=0
		    fi
		fi
		MemFree=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    if [ $? != 0 ]; then
		    MemFree=`free -h | grep Mem | awk '{print $3}'`
		    if [ $? != 0 ]; then
		        MemFree=0
		    fi
		fi
		Cached=$(awk '/\<Cached\>/ {print $2}' /proc/meminfo)
    if [ $? != 0 ]; then
		    Cached=`free -h | grep Mem | awk '{print $6}'`
		    if [ $? != 0 ]; then
		        Cached=0
		    fi
		fi
		MemUsed=$(($MemTotal - ($Cached + $MemFree)))
		SwapTotal=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
    if [ $? != 0 ]; then
		    SwapTotal=`free -h | grep Swap | awk '{print $2}'`
		    if [ $? != 0 ]; then
		        SwapTotal=0
		    fi
		fi
		SwapFree=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
    if [ $? != 0 ]; then
		    SwapFree=`free -h | grep Swap | awk '{print $3}'`
		    if [ $? != 0 ]; then
		        SwapFree=0
		    fi
		fi
		SwapUsed=$(($SwapTotal - $SwapFree))
    if [ $? != 0 ]; then
		    SwapUsed=`free -h | grep Swap | awk '{print $6}'`
		    if [ $? != 0 ]; then
		        SwapUsed=0
		    fi
		fi

		# Disk
		HDD=$(df -Tlm --total -t ext4 -t ext3 -t ext2 -t reiserfs -t jfs -t ntfs -t fat32 -t btrfs -t fuseblk -t zfs -t simfs -t xfs 2>/dev/null | tail -n 1)
		HDDTotal=$(echo -n ${HDD} | awk '{ print $3 }')
		HDDUsed=$(echo -n ${HDD} | awk '{ print $4 }')
		if [ "$HDDTotal" == "" ]; then
		  if [ $(is_termux) != 1 ]; then # BUG: not run into else (fuck bash), means only can run in the termux
		      # about
		      HDDTotal=$(df /data | awk '{print $2}' | tail -n 1)
		      HDDTotal=`echo ${HDDTotal:0:-3}`
		      HDDUsed=$(df /data | awk '{print $3}' | tail -n 1)
		      HDDUsed=`echo ${HDDUsed:0:-3}`
		  else
		      HDDTotal=$(df / | awk '{print $2}' | tail -n 1)
		      HDDTotal=`echo ${HDDTotal:0:-3}`
		      HDDUsed=$(df / | awk '{print $3}' | tail -n 1)
		      HDDUsed=`echo ${HDDUsed:0:-3}`
		  fi
		fi

		# CPU
		# Get the total CPU statistics, discarding the 'cpu ' prefix.
		CPU=($(sed -n 's/^cpu\s//p' /proc/stat))
		IDLE=${CPU[3]} # Just the idle CPU time.
		# Calculate the total CPU time.
		TOTAL=0
		for VALUE in "${CPU[@]}"; do
			let "TOTAL=$TOTAL+$VALUE"
		done
		# Calculate the CPU usage since we last checked.
		let "DIFF_IDLE=$IDLE-$PREV_IDLE"
		let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
		let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
		# Remember the total and idle CPU times for the next check.
		PREV_TOTAL="$TOTAL"
		PREV_IDLE="$IDLE"

		# Network traffic
		NET=($(grep ":" /proc/net/dev | grep -v -e "lo" -e "tun" | awk '{a+=$2}{b+=$10}END{print a,b}'))
		if [ $? != 0 ]; then
		  NetRx=0
		  NetTx=0
		else
      NetRx="${NET[0]}"
      NetTx="${NET[1]}"
    fi

		if [ "$PREV_NetRx" == "" ]; then
			PREV_NetRx="$NetRx"
			PREV_NetTx="$NetTx"
		fi

		let "SpeedRx=($NetRx-$PREV_NetRx)/$INTERVAL"
		let "SpeedTx=($NetTx-$PREV_NetTx)/$INTERVAL"
		PREV_NetRx="$NetRx"
		PREV_NetTx="$NetTx"

		# action bypass mode
    if [ $BACKENDMODE == 0 ]; then
        payload="{${SERVERINFO}${Online}\"uptime\":$Uptime,\"load\":$Load,\"memory_total\":$MemTotal,\"memory_used\":$MemUsed,\"swap_total\":$SwapTotal,\"swap_used\":$SwapUsed,\"hdd_total\":$HDDTotal,\"hdd_used\":$HDDUsed,\"cpu\":${DIFF_USAGE}.0,\"network_rx\":$SpeedRx,\"network_tx\":$SpeedTx}"
        server_update $payload
    else
       	echo -e "update {$Online \"uptime\": $Uptime, \"load\": $Load, \"memory_total\": $MemTotal, \"memory_used\": $MemUsed, \"swap_total\": $SwapTotal, \"swap_used\": $SwapUsed, \"hdd_total\": $HDDTotal, \"hdd_used\": $HDDUsed, \"cpu\": ${DIFF_USAGE}.0, \"network_rx\": $SpeedRx, \"network_tx\": $SpeedTx }"
    fi
	done
	$NETBIN $SERVER $PORT | while IFS= read -r -d $'\0' x; do
		if [ ! -f status.log ]; then
			if grep -q "IPv6" <<< "$x"; then
				echo "Connected." >&2
				echo 4 > status.log
				exit 0
			elif grep -q "IPv4" <<< "$x"; then
				echo "Connected." >&2
				echo 6 > status.log
				exit 0
			fi
		fi
	done

	wait
	if ! $RUNNING; then
		echo "Exiting"
		rm -f status.log
		exit 0
	fi

	# keep on trying after a disconnect
	echo "Disconnected." >&2
	sleep 3
	echo "Reconnecting..." >&2
done

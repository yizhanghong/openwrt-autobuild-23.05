#!/bin/bash

# 缺省duty
default_duty=50000
default_threshold=3

# 检查是否支持PWM
if [ ! -d /sys/class/pwm/pwmchip0 ]; then
	echo -e "\033[1;41;37mFAILURE\033[0m: 硬件设备不支持PWM!"
    exit 1
fi

# 导出pwm0
if [ ! -d /sys/class/pwm/pwmchip0/pwm0 ]; then
	 echo -n 0 > /sys/class/pwm/pwmchip0/export
fi

# 等待pwm0目录生成
while [ ! -d /sys/class/pwm/pwmchip0/pwm0 ]; do
	sleep 1
done

# 停止pwm0
if [ "$(cat /sys/class/pwm/pwmchip0/pwm0/enable)" -eq 1 ]; then
    echo -n 0 > /sys/class/pwm/pwmchip0/pwm0/enable
fi

# 设置周期为50微秒（50000纳秒）
echo -n 50000 > /sys/class/pwm/pwmchip0/pwm0/period
echo -n 1 > /sys/class/pwm/pwmchip0/pwm0/enable

# 风扇最大转速
echo -n ${default_duty} > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# 循环计数
count=0
current_index=-1

# 不同温度对应不同占空比设置
declare -a CpuTemps=(75000 63000 58000 52000 49000)			# 数值越大温度越高，“55000”即55℃。
declare -a PwmDutyCycles=(25000 35000 45000 46990 48000)	# 数值越小速度越快，PWM 占空比。

while true; do
	# 读取CPU温度
	temp=$(cat /sys/class/thermal/thermal_zone0/temp)
	
	# 设置当前的占空比值
	duty_cycle=$default_duty
	update_cycle=false
	
	 # 遍历每个温度阈值
	for i in "${!CpuTemps[@]}"; do
		echo "index_0=$i, temp=$temp, cpu=${CpuTemps[$i]}"
		
		if [[ "$temp" =~ ^[0-9]+$ ]] && [ "$temp" -gt "${CpuTemps[$i]}" ]; then
			if [ "$current_index" -eq "$i" ]; then
				((count++))
			else
				count=1
				current_index=$i
			fi
			
			echo "index_1=$i, temp=$temp, cpu=${CpuTemps[$i]}, count=$count"
			
			if [ $count -ge $default_threshold ]; then
				update_cycle=true
				duty_cycle=${PwmDutyCycles[$i]}
				
				echo "index_2=$i, temp=$temp, cpu=${CpuTemps[$i]}, duty=$duty_cycle"
			fi
			
			break
		fi
	done
	
	# 如果没有匹配的温度区间，重置计数器和索引
	if [ $current_index -ne -1 ] && [ "$temp" -le "${CpuTemps[${current_index}]}" ]; then
		echo "index_3=$current_index, temp=$temp, cpu=${CpuTemps[$i]}, duty=$duty_cycle"
		
		count=0
        current_index=-1
	fi
	
	if [[ $update_cycle = true ]]; then
		echo "temp: ${temp}; duty: ${duty_cycle}； count: ${count}; index: ${current_index}"
		
		# 获取当前的占空比
		cur_duty_cycle=$(cat /sys/class/pwm/pwmchip0/pwm0/duty_cycle)
		
		# 计数置0
		count=0
		
		if [ "${cur_duty_cycle}" -ne "${duty_cycle}" ]; then
			echo -n $duty_cycle > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
		fi
	fi
	
	sleep 2s;
done
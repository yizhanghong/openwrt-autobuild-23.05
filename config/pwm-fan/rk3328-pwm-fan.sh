#!/bin/bash

# 缺省duty
default_duty=50000

# 不同温度对应不同占空比设置
declare -a CpuTemps=(75000 63000 58000 52000 48000)			# 数值越大温度越高，“55000”即55℃。
declare -a PwmDutyCycles=(25000 35000 45000 46990 48000)	# 数值越小速度越快，PWM 占空比。

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

while true; do
	# 读取CPU温度
	temp=$(cat /sys/class/thermal/thermal_zone0/temp)
	
	# 设置当前的占空比值
	duty_cycle=${default_duty}
	
	for i in "${!CpuTemps[@]}"; do
		if [ "$temp" -gt "${CpuTemps[$i]}" ]; then
			duty_cycle=${PwmDutyCycles[$i]}
			break
		fi
	done
	
	echo "temp: ${temp}; duty: ${duty_cycle}"
	
	# 获取当前的占空比
    cur_duty_cycle=$(cat /sys/class/pwm/pwmchip0/pwm0/duty_cycle)
	
	if [ "${cur_duty_cycle}" -ne "${duty_cycle}" ]; then
		echo -n $duty_cycle > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
	fi
	
	sleep 2s;
done
#!/bin/bash

. diyconfig/plugin-setup.sh
. diyconfig/themes-setup.sh
. diyconfig/system-setup.sh
. diyconfig/network-setup.sh

#********************************************************************************#
# 自定义插件
set_openwrt_plugins()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在获取第三方插件..."
	
	source_type=${local_source_array["Type"]}
	source_path=${local_source_array["Path"]}
	
	# 自定义插件路径
	plugins_path="${source_path}/package/${USER_CONFIG_ARRAY["plugins"]}/plugins" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi
	
	# 设置自定义插件
	set_user_plugins ${source_type} ${source_path} ${plugins_path}
}

# 自定义主题
set_openwrt_themes()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在设置自定义主题..."

	source_type=${local_source_array["Type"]}
	source_path=${local_source_array["Path"]}
	
	# 自定义插件路径
	plugins_path="${source_path}/package/${USER_CONFIG_ARRAY["plugins"]}/themes" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi
	
	# 设置自定义主题
	set_user_themes ${source_type} ${source_path} ${plugins_path}
}

# 自定义配置
set_openwrt_config()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在设置缺省配置..."
	
	source_type=${local_source_array["Type"]}
	source_path=${local_source_array["Path"]}
	
	# 设置自定义配置
	set_user_config ${source_type} ${source_path}
	
	# 设置自定义网络
	set_user_network ${source_type} ${source_path}
}

#********************************************************************************#
# 获取源码配置
get_source_config()
{
	file=$1
	
	# _config
	{
		section_array=()
		get_config_section "_config" "${file}" section_array
		
		if [ ${#section_array[@]} -eq 0 ]; then
			print_log "ERROR" "user config" "没有获取到配置信息, 请检查!"
			return 1
		fi
		
		for section in "${section_array[@]}"; do
			declare -A source_array
			if ! get_config_info "${section}" "${file}" source_array; then
				continue
			fi

			# 源码名称
			source_name="${source_array["Name"]}"
			
			# 源码别名
			alias_name=${source_array["Alias"]}
			
			if [ -z ${source_name} ] || [ -z ${alias_name} ]; then
				continue
			fi
			
			# 获取源码类型
			source_type=${SOURCE_TYPE[${source_name}]}
			
			source_array["Type"]=${source_type}
			
			# 判断关联数组是否有效
			if [ ${#source_array[@]} -gt 0 ]; then
				# 源码路径
				source_array["Path"]="${OPENWRT_WORK_PATH}/${alias_name}"
				
				# 设置源码项目结构体
				set_struct_field SOURCE_CONFIG_ARRAY ${source_type} source_array
			fi	
		done
		
		if [ ${#SOURCE_CONFIG_ARRAY[@]} -eq 0 ]; then
			print_log "ERROR" "user config" "获取到配置信息有误, 请检查!"
			return 1
		fi
	}
}

# 获取自定义配置
get_diy_config()
{
	file=$1
	
	# diyconfig
	{
		declare -A fields_array
		if ! get_config_info "diyconfig" "${file}" fields_array; then
			print_log "ERROR" "user config" "无法获取diyconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# feeds配置名称
		USER_CONFIG_ARRAY["feedsname"]="${fields_array["feeds_name"]}"
		
		# 时区
		USER_CONFIG_ARRAY["timezone"]="${fields_array["time_zone"]}"
		
		# 时区名称
		USER_CONFIG_ARRAY["zonename"]="${fields_array["zone_name"]}"
		
		# 缺省名称
		USER_CONFIG_ARRAY["defaultname"]="${fields_array["user_name"]}"
		
		# 缺省密码
		USER_CONFIG_ARRAY["defaultpasswd"]="${fields_array["user_passwd"]}"
	}
}

# 获取network接口配置
get_network_config()
{
	file=$1
	
	# lanconfig
	{
		declare -A fields_array
		if ! get_config_info "lanconfig" "${file}" fields_array; then
			print_log "ERROR" "user config" "无法获取lanconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# lan接口地址
		NETWORK_CONFIG_ARRAY["lanaddr"]="${fields_array["lan_ipaddr"]}"
		
		# lan接口子网掩码
		NETWORK_CONFIG_ARRAY["lannetmask"]="${fields_array["lan_netmask"]}"
		
		# lan接口广播地址
		NETWORK_CONFIG_ARRAY["lanbroadcast"]="${fields_array["lan_broadcast"]}"
		
		# lan接口dhcp起始地址
		NETWORK_CONFIG_ARRAY["landhcpstart"]="${fields_array["lan_dhcp_start"]}"
		
		# lan接口dhcp地址数量
		NETWORK_CONFIG_ARRAY["landhcpnumber"]="${fields_array["lan_dhcp_number"]}"
	}
	
	# wanconfig
	{
		declare -A fields_array
		if ! get_config_info "wanconfig" "${file}" fields_array; then
			print_log "ERROR" "user config" "无法获取wanconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# wan接口地址
		NETWORK_CONFIG_ARRAY["wanaddr"]="${fields_array["wan_ipaddr"]}"
		
		# wan接口子网掩码
		NETWORK_CONFIG_ARRAY["wannetmask"]="${fields_array["wan_netmask"]}"
		
		# wan接口广播地址
		NETWORK_CONFIG_ARRAY["wanbroadcast"]="${fields_array["wan_broadcast"]}"
		
		# wan接口网关地址
		NETWORK_CONFIG_ARRAY["wangateway"]="${fields_array["wan_gateway"]}"
		
		# wan接口dns地址
		NETWORK_CONFIG_ARRAY["wandnsaddr"]="${fields_array["wan_dnsaddr"]}"
	}
}

# 获取用户配置
get_user_config()
{
	if [ $# -eq 0 ]; then
		print_log "ERROR" "user config" "获取配置函数操作有误, 请检查!"
		return 1
	fi
	
	conf_file=$1
	if [ ! -e "${conf_file}" ]; then
		print_log "ERROR" "user config" "脚本配置文件不存在, 请检查!"
		return 1
	fi
	
	# 获取源码配置
	get_source_config ${conf_file}
	
	# 获取自定义匹配值
	get_diy_config ${conf_file}
	
	# 获取network接口配置
	get_network_config ${conf_file}

	return 0
}

# 获取固件信息
get_firmware_info()
{
	local -n local_source_array="$1"
	local local_source_path="$2"
	
	source_name=${local_source_array["Name"]}
	source_path=${local_source_array["Path"]}
	if [ -z "${source_name}" ] || [ -z "${source_path}" ]; then
		print_log "ERROR" "custom config" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	defaultconf="${USER_CONFIG_ARRAY["defaultconf"]}"
	
	# 获取版本号
	if [ "${source_name}" == "coolsnowwolf" ]; then
		USER_CONFIG_ARRAY["versionnum"]=$(sed -n "s/echo \"DISTRIB_REVISION='\([^\']*\)'.*$/\1/p" ${source_path}/package/lean/default-settings/files/zzz-default-settings)
	fi
	
	# 获取设备名称
	if [ -e "${source_path}/${defaultconf}" ]; then
		USER_CONFIG_ARRAY["devicename"]=$(grep '^CONFIG_TARGET.*DEVICE.*=y' ${source_path}/.config | sed -r 's/.*DEVICE_(.*)=y/\1/')
	fi
	
	# 获取固件名称
	file_date=$(date +"%Y%m%d%H%M")
	if [ -z "${USER_CONFIG_ARRAY["devicename"]}" ]; then
		USER_CONFIG_ARRAY["firmwarename"]="openwrt_firmware_${file_date}"
	else
		USER_CONFIG_ARRAY["firmwarename"]="openwrt_firmware_${USER_CONFIG_ARRAY["devicename"]}_${file_date}"
	fi
	
	if [ -n "${USER_CONFIG_ARRAY["versionnum"]}" ]; then
		firmwarename="${USER_CONFIG_ARRAY["firmwarename"]}_${USER_CONFIG_ARRAY["versionnum"]}"
		USER_CONFIG_ARRAY["firmwarename"]="${firmwarename}"
	fi
	
	local_source_path=${source_path}
	return 0
}
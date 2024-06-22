#!/bin/bash

. diyconfig/lede.sh
. diyconfig/official.sh

#********************************************************************************#
# 第三方插件
addOpenWrtPlugins()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在获取第三方插件..."
	
	source_path=${local_source_array["Path"]}
	source_type=${local_source_array["Type"]}
	
	# 自定义插件路径
	plugins_path="${source_path}/package/${USERCONFIG_ARRAY["plugins"]}/plugins" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi

	case ${source_type} in
	${SOURCE_TYPE[openwrt]})
		setOfficialPlugins ${source_path} ${plugins_path}
		;;
	${SOURCE_TYPE[immortalwrt]})
		setOfficialPlugins ${source_path} ${plugins_path}
		;;
	${SOURCE_TYPE[coolsnowwolf]})
		setLedePlugins ${source_path} ${plugins_path}
		;;
	*)
		;;
	esac
	
	# other package
	{
		if [ ! -d "${plugins_path}/otherpackage" ]; then
			print_log "INFO" "custom config" "获取otherpackage仓库代码..."
			
			url="https://github.com/lysgwl/openwrt-package.git/otherpackage?ref=master"
			get_remote_spec_contents $url "otherpackage" ${plugins_path} ${NETWORK_PROXY_CMD}
		fi
	}
	
	# golang
	{
		#rm -rf ${source_path}/feeds/packages/lang/golang
		print_log "INFO" "custom config" "获取golang仓库代码..."
		
		url="https://github.com/sbwml/packages_lang_golang.git?ref=22.x"
		#clone_repo_contents $url "${source_path}/feeds/packages/lang/golang" ${NETWORK_PROXY_CMD}
	}
}

# 自定义主题
addOpenWrtThemes()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在设置自定义主题..."

	source_path=${local_source_array["Path"]}
	source_type=${local_source_array["Type"]}
	
	# 自定义插件路径
	plugins_path="${source_path}/package/${USERCONFIG_ARRAY["plugins"]}/themes" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi
	
	case ${source_type} in
	${SOURCE_TYPE[openwrt]})
		setOfficialThemes ${source_path} ${plugins_path}
		;;
	${SOURCE_TYPE[immortalwrt]})
		setOfficialThemes ${source_path} ${plugins_path}
		;;
	${SOURCE_TYPE[coolsnowwolf]})
		setLedeThemes ${source_path} ${plugins_path}
		;;
	*)
		;;
	esac
}

# 设置缺省配置
setOpenWrtConfig()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在设置缺省配置..."
	
	source_path=${local_source_array["Path"]}
	source_type=${local_source_array["Type"]}
	
	case ${source_type} in
	${SOURCE_TYPE[openwrt]})
		setOfficialConfig ${source_path}
		;;
	${SOURCE_TYPE[immortalwrt]})
		setOfficialConfig ${source_path}
		;;
	${SOURCE_TYPE[coolsnowwolf]})
		setLedeConfig ${source_path}
		;;
	*)
		;;
	esac
	
	# 设置缺省IP地址
	{
		print_log "INFO" "custom config" "[设置缺省IP地址]"
		file="${source_path}/package/base-files/files/bin/config_generate"
		
		if [ -e ${file} ]; then
			default_ip="${USERCONFIG_ARRAY["defaultip"]}"
			ip_addr=$(sed -n 's/.*lan) ipad=\${ipaddr:-"\([0-9.]\+\)"}.*/\1/p' ${file})
			
			if [ "${ip_addr}" != "${default_ip}" ]; then
				sed -i "s/lan) ipad=\${ipaddr:-\"$ip_addr\"}/lan) ipad=\${ipaddr:-\"${default_ip}\"}/" ${file}
			fi
		fi
	}
	
	# 设置主机名称
	{
		print_log "INFO" "custom config" "[设置主机名称]"
		file="${source_path}/package/base-files/files/bin/config_generate"
		
		if [ -e ${file} ]; then
			default_name="${USERCONFIG_ARRAY["defaultname"]}"
			host_name=$(sed -n "s/.*system\.@system\[-1\]\.hostname='\([^']*\)'/\1/p" ${file})
			
			if [ -z "${host_name}" ]; then
				sed -i '/.*add system system$/a\ \t\tset system.@system[-1].hostname='\''${default_name}'\''' ${file}
			else
				if [ "${host_name}" != "${default_name}" ]; then
					sed -i "s/\(set system.@system\[-1\].hostname=\).*/\1'${default_name}'/" ${file}
				fi
			fi
		fi
	}
	
	# 设置时区
	{
		print_log "INFO" "custom config" "[设置系统时区]"
		file="${source_path}/package/base-files/files/bin/config_generate"
		
		if [ -e ${file} ]; then
			default_timezone="${USERCONFIG_ARRAY["timezone"]}"
			time_zone=$(sed -n "s/.*system\.@system\[-1\]\.timezone='\([^']*\)'/\1/p" ${file})
			
			if [ -n "${time_zone}" ]; then
				if [ "${time_zone}" != "${default_timezone}" ]; then
					sed -i "s/\(set system.@system\[-1\].timezone=\).*/\1'${default_timezone}'/" ${file}
				fi
			fi
			
			default_zonename="${USERCONFIG_ARRAY["zonename"]}"
			zone_name=$(sed -n "s/.*system\.@system\[-1\]\.zonename='\([^']*\)'/\1/p" ${file})
			
			if [ -z "${zone_name}" ]; then
				#sed -i "/.*system.@system\[-1\].timezone.*$/a\ \t\tset system.@system[-1].zonename='\$defaultzonename'" ${file}
				sed -i "/.*system.@system\[-1\].timezone.*\$/a\ \t\tset system.@system[-1].zonename='${default_zonename}'" ${file}
			else
				if [ "${zone_name}" != "${default_zonename}" ]; then
					sed -i "s|\(set system.@system\[-1\].zonename=\).*|\1'${default_zonename}'|" ${file}
				fi
			fi
		fi
	}
	
	# nginx配置文件
	{
		print_log "INFO" "custom config" "[设置nginx配置文件]"
		nginx_cfg="${source_path}/feeds/packages/net/nginx-util/files/nginx.config"
		
		if [ -f ${nginx_cfg} ]; then
			if grep -q "302 https://\$host\$request_uri" $nginx_cfg; then
				if ! grep -q "^#.*302 https://\$host\$request_uri" $nginx_cfg; then
					sed -i "/.*302 https:\/\/\$host\$request_uri/s/^/#/g" $nginx_cfg
				fi
			fi
			
			if ! grep -A 1 '302 https://$host$request_uri' $nginx_cfg | grep -q 'restrict_locally'; then
				sed -i "/302 https:\/\/\$host\$request_uri/ a\ \tlist include 'restrict_locally'\n\tlist include 'conf.d/*.locations'" $nginx_cfg
			fi
		fi
	}
}

#********************************************************************************#
# 获取用户配置
getUserConfig()
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
	
	# 配置文件_config段
	{
		section_array=()
		getConfigSection "_config" "${conf_file}" section_array
		
		if [ ${#section_array[@]} -eq 0 ]; then
			print_log "ERROR" "user config" "没有获取到配置信息, 请检查!"
			return 1
		fi
		
		for section in "${section_array[@]}"; do
			declare -A source_array
			if ! getConfigInfo "${section}" "${conf_file}" source_array; then
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
				set_struct_field SOURCE_ARRAY ${source_type} source_array
			fi	
		done
		
		if [ ${#SOURCE_ARRAY[@]} -eq 0 ]; then
			print_log "ERROR" "user config" "获取到配置信息有误, 请检查!"
			return 1
		fi
	}
	
	# 配置文件diyconfig段
	{
		declare -A fields_array
		if ! getConfigInfo "diyconfig" "${conf_file}" fields_array; then
			print_log "ERROR" "user config" "无法获取diyconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# feeds配置名称
		USERCONFIG_ARRAY["feedsname"]="${fields_array["feeds_name"]}"
		
		# 时区
		USERCONFIG_ARRAY["timezone"]="${fields_array["time_zone"]}"
		
		# 时区名称
		USERCONFIG_ARRAY["zonename"]="${fields_array["zone_name"]}"
		
		# 缺省名称
		USERCONFIG_ARRAY["defaultname"]="${fields_array["user_name"]}"
		
		# 缺省密码
		USERCONFIG_ARRAY["defaultpasswd"]="${fields_array["user_passwd"]}"
		
		# 缺省IP
		USERCONFIG_ARRAY["defaultip"]="${fields_array["user_ip"]}"
	}
	
	return 0
}

# 获取固件信息
getFirmwareInfo()
{
	local -n local_source_array="$1"
	local local_source_path="$2"
	
	source_name=${local_source_array["Name"]}
	source_path=${local_source_array["Path"]}
	if [ -z "${source_name}" ] || [ -z "${source_path}" ]; then
		print_log "ERROR" "custom config" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	defaultconf="${USERCONFIG_ARRAY["defaultconf"]}"
	
	# 获取版本号
	if [ "${source_name}" == "coolsnowwolf" ]; then
		USERCONFIG_ARRAY["versionnum"]=$(sed -n "s/echo \"DISTRIB_REVISION='\([^\']*\)'.*$/\1/p" ${source_path}/package/lean/default-settings/files/zzz-default-settings)
	fi
	
	# 获取设备名称
	if [ -e "${source_path}/${defaultconf}" ]; then
		USERCONFIG_ARRAY["devicename"]=$(grep '^CONFIG_TARGET.*DEVICE.*=y' ${source_path}/.config | sed -r 's/.*DEVICE_(.*)=y/\1/')
	fi
	
	# 获取固件名称
	file_date=$(date +"%Y%m%d%H%M")
	if [ -z "${USERCONFIG_ARRAY["devicename"]}" ]; then
		USERCONFIG_ARRAY["firmwarename"]="openwrt_firmware_${file_date}"
	else
		USERCONFIG_ARRAY["firmwarename"]="openwrt_firmware_${USERCONFIG_ARRAY["devicename"]}_${file_date}"
	fi
	
	if [ -n "${USERCONFIG_ARRAY["versionnum"]}" ]; then
		firmwarename="${USERCONFIG_ARRAY["firmwarename"]}_${USERCONFIG_ARRAY["versionnum"]}"
		USERCONFIG_ARRAY["firmwarename"]="${firmwarename}"
	fi
	
	local_source_path=${source_path}
	return 0
}
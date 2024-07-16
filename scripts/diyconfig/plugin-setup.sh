#!/bin/bash

#********************************************************************************#
# 下载other package
download_other_package()
{
	source_path=$1
	plugins_path=$2
	
	{
		print_log "INFO" "custom config" "获取otherpackage仓库代码..."
		
		local user_array=("${plugins_path}")
		remove_plugin_package "other_config" "${source_path}/package" "${OPENWRT_PLUGIN_FILE}" user_array
		
		user_array=()
		remove_plugin_package "other_config" "${source_path}/feeds" "${OPENWRT_PLUGIN_FILE}" user_array
	
		url="https://github.com/lysgwl/openwrt-package.git/otherpackage?ref=master"	
		get_remote_spec_contents "$url" "other" ${plugins_path} ${NETWORK_PROXY_CMD}
	}
}

# 下载golang
download_golang()
{
	source_path=$1
	
	{
		rm -rf ${source_path}/feeds/packages/lang/golang
		print_log "INFO" "custom config" "获取golang仓库代码..."
		
		url="https://github.com/sbwml/packages_lang_golang.git?ref=22.x"
		clone_repo_contents "$url" "${source_path}/feeds/packages/lang/golang" ${NETWORK_PROXY_CMD}
	}
}

# 下载shidahuilang package
download_shidahuilang_package()
{
	plugins_path=$1
	
	{
		print_log "INFO" "custom config" "获取shidahuilang仓库代码..."
		
		if [ ! -d "${plugins_path}/shidahuilang" ] || [ -z "$(ls -A "${plugins_path}/shidahuilang")" ]; then
			url="https://github.com/lysgwl/openwrt-package.git/shidahuilang?ref=master"
			get_remote_spec_contents "$url" ${plugins_path} ${NETWORK_PROXY_CMD}
		fi
	}
}

# 下载kiddin9 package
download_kiddin9_package()
{
	plugins_path=$1
	
	{
		print_log "INFO" "custom config" "获取kiddin9仓库代码..."
		
		if [ ! -d "${plugins_path}/kiddin9" ] || [ -z "$(ls -A "${plugins_path}/kiddin9")" ]; then
			url="https://github.com/lysgwl/openwrt-package.git/kiddin9/master?ref=master"
			get_remote_spec_contents "$url" ${plugins_path} ${NETWORK_PROXY_CMD}
		fi
	}
}

# 下载siropboy package
download_siropboy_package()
{
	plugins_path=$1
	
	{
		print_log "INFO" "custom config" "获取sirpdboy-package仓库代码..."
		
		if [ ! -d "${plugins_path}/sirpdboy-package" ] || [ -z "$(ls -A "${plugins_path}/sirpdboy-package")" ]; then
			url="https://github.com/sirpdboy/sirpdboy-package.git?ref=main"
			clone_repo_contents "$url" "${plugins_path}" ${NETWORK_PROXY_CMD}
		fi
	}
}

#********************************************************************************#
# 设置light插件
set_light_plugin()
{
	source_path=$1
	
	# 删除luci-light插件
	{
		file="${source_path}/feeds/luci/collections/luci-light"
		print_log "INFO" "custom config" "[删除插件luci-light]"
		
		if [ -d ${file} ]; then	
			rm -rf ${file}
		fi
	}
	
	# 取消luci-ssl对luci-light依赖
	{
		file="${source_path}/feeds/luci/collections/luci-ssl/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-ssl]"
		
		if [ -e ${file} ]; then	
			if grep -q "+luci-light" ${file}; then
				#sed -i 's/+luci-light//g' ${file}
				sed -i 's/\+luci-light//g; s/^\s*//; s/\s*$//' ${file}
			fi
		fi
	}
	
	# 取消luci-ssl-openssl对luci-light依赖
	{
		file="${source_path}/feeds/luci/collections/luci-ssl-openssl/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-ssl-openssl]"
		
		if [ -e ${file} ]; then	
			if grep -q "+luci-light" ${file}; then
				#sed -i 's/+luci-light//g' ${file}
				sed -i 's/\+luci-light//g; s/^\s*//; s/\s*$//' ${file}
			fi
		fi
	}
}

# 设置uhttpd插件依赖
set_uhttpd_plugin()
{
	source_path=$1
	
	{
		file="${source_path}/feeds/luci/collections/luci/Makefile"
		print_log "INFO" "custom config" "[修改uhttpd编译]"
		
		# 取消uhttpd依赖
		if grep -q "+uhttpd" ${file}; then
			#sed -i 's/+uhttpd //g' ${file}
			sed -i 's/\+uhttpd//g; s/^\s*//; s/\s*$//' ${file}
		fi
		
		# 取消uhttpd-mod-ubus依赖
		if grep -q "+uhttpd" ${file}; then
			#sed -i 's/+uhttpd-mod-ubus //g' ${file}
			sed -i 's/\+uhttpd-mod-ubus//g; s/^\s*//; s/\s*$//' ${file}
		fi
	}
}

# 设置bootstrap插件
set_bootstrap_plugin()
{
	source_path=$1
	
	# 取消luci-nginx对luci-theme-bootstrap依赖
	{
		file="${source_path}/feeds/luci/collections/luci-nginx/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-nginx]"
		
		if [ -e ${file} ]; then	
			if grep -q "+luci-theme-bootstrap" ${file}; then
				#sed -i 's/+luci-theme-bootstrap //g' ${file}
				sed -i 's/\+luci-theme-bootstrap//g; s/^\s*//; s/\s*$//' ${file}
			fi
		fi	
	}
	
	# 取消luci-ssl-nginx对luci-theme-bootstrap依赖
	{
		file="${source_path}/feeds/luci/collections/luci-ssl-nginx/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-ssl-nginx]"
		
		if [ -e ${file} ]; then	
			if grep -q "+luci-theme-bootstrap" ${file}; then
				#sed -i 's/+luci-theme-bootstrap //g' ${file}
				sed -i 's/\+luci-theme-bootstrap//g; s/^\s*//; s/\s*$//' ${file}
			fi
		fi	
	}
}

# 设置nginx插件
set_nginx_plugin()
{
	source_path=$1
	
	# 修改nginx配置文件
	{
		nginx_cfg="${source_path}/feeds/packages/net/nginx-util/files/nginx.config"
		print_log "INFO" "custom config" "[设置nginx配置文件]"
		
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

# 设置插件依赖
set_plugin_depends()
{
	source_type=$1
	source_path=$2
	
	{
		case ${source_type} in
		${SOURCE_TYPE[openwrt]} | ${SOURCE_TYPE[immortalwrt]})
			# 设置light插件
			set_light_plugin ${source_path}
			;;
		${SOURCE_TYPE[coolsnowwolf]})
			# 设置uhttpd插件依赖
			set_uhttpd_plugin ${source_path}
			;;
		*)
			;;	
		esac
		
		# 设置bootstrap插件
		set_bootstrap_plugin ${source_path}
	}
}

# 设置插件UI 
set_plugin_webui()
{
	source_type=$1
	source_path=$2
	
	# upnp插件
	{
		case ${source_type} in
		${SOURCE_TYPE[openwrt]} | ${SOURCE_TYPE[immortalwrt]})
			file="${source_path}/feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json"
			if [ -e ${file} ]; then
				sed -i 's/services/network/g' ${file}
			fi
			;;
		*)
			;;	
		esac
	}
}

#********************************************************************************#
# 下载插件
download_user_plugin()
{
	source_path=$
	plugins_path=$2
	
	if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
		if ! input_prompt_confirm "是否需要下载用户插件?"; then
			return
		fi
	fi
	
	# other package
	download_other_package ${source_path} ${plugins_path}
	
	# golang
	download_golang ${source_path}
}

# 设置插件配置
set_plugin_config()
{
	source_type=$1
	source_path=$2
	
	# 设置nginx插件
	set_nginx_plugin ${source_path}
	
	# 设置插件依赖
	set_plugin_depends ${source_type} ${source_path}
	
	# 设置插件UI
	set_plugin_webui ${source_type} ${source_path}
}

# 设置自定义插件
set_user_plugins()
{
	source_type=$1
	source_path=$2
	plugins_path=$3
	
	# 下载插件
	download_user_plugin ${source_path} ${plugins_path}
	
	# 设置插件配置
	set_plugin_config ${source_type} ${source_path}
}
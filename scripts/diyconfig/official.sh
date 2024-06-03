#!/bin/bash

#********************************************************************************#
# 设置Official插件
setOfficialPlugins()
{
	source_path=$1
	plugins_path=$2
	
	# shidahuilang
	if [ ! -d "${plugins_path}/shidahuilang" ]; then
		print_log "INFO" "custom config" "获取shidahuilang仓库代码..."
		
		url="https://github.com/lysgwl/openwrt-package.git/shidahuilang?ref=master"
		#get_remote_spec_contents $url "shidahuilang" ${plugins_path} ${NETWORK_PROXY_CMD}
	fi
	
	# kiddin9
	if [ ! -d "${plugins_path}/kiddin9" ]; then
		print_log "INFO" "custom config" "获取kiddin9仓库代码..."
		
		url="https://github.com/lysgwl/openwrt-package.git/kiddin9/master?ref=master"
		#get_remote_spec_contents $url "kiddin9" ${plugins_path} ${NETWORK_PROXY_CMD}
	fi
	
	# siropboy
	if [ ! -d "${plugins_path}/sirpdboy-package" ]; then
		print_log "INFO" "custom config" "获取sirpdboy-package仓库代码..."
		
		url="https://github.com/sirpdboy/sirpdboy-package.git?ref=main"
		#clone_repo_contents $url "${plugins_path}" ${NETWORK_PROXY_CMD}
	fi
}

# 设置Official主题
setOfficialThemes()
{
	source_path=$1
	plugins_path=$2
	
	# luci-theme-argon
	{
		find ${source_path} -name luci-theme-argon | xargs rm -rf;		
		print_log "INFO" "custom config" "获取luci-theme-argon仓库代码..."
		
		url="https://github.com/jerrykuku/luci-theme-argon.git?ref=master"
		clone_repo_contents $url "${plugins_path}" ${NETWORK_PROXY_CMD}
	}
	
	# luci-theme-argon-config
	{
		find ${source_path} -name luci-theme-argon-config | xargs rm -rf;	
		print_log "INFO" "custom config" "获取luci-theme-argon-config仓库代码..."
		
		url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=master"
		clone_repo_contents $url "${plugins_path}" ${NETWORK_PROXY_CMD}
	}
	
	# luci-theme-edge
	{
		find ${source_path} -name luci-theme-edge | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-edge仓库代码..."
		
		url="https://github.com/kiddin9/luci-theme-edge.git?ref=master"
		clone_repo_contents $url "${plugins_path}/luci-theme-edge" ${NETWORK_PROXY_CMD}
	}
}

# 设置Official配置
setOfficialConfig()
{
	source_path=$1
	
	# luci/Makefile默认编译依赖
	{
		file="${source_path}/feeds/luci/collections/luci/Makefile"
		if [ -e ${file} ]; then
		
			# 修改默认主题
			if grep -q "+luci-light" ${file}; then
				print_log "INFO" "custom config" "[修改默认主题]"
				sed -i 's/luci-light/luci-theme-argon/g' ${file}
			fi
			
			# 取消uhttpd依赖
			print_log "INFO" "custom config" "[修改uhttpd编译]"
			if grep -q "+uhttpd" ${file}; then
				sed -i 's/+uhttpd //g' ${file}
			fi
			
			# 取消uhttpd-mod-ubus依赖
			if grep -q "+uhttpd-mod-ubus" ${file}; then
				sed -i 's/+uhttpd-mod-ubus //g' ${file}
			fi
		fi
	}
	
	# 删除luci-light插件
	{
		file="${source_path}/feeds/luci/collections/luci-light"
		if [ -d ${file} ]; then
			print_log "INFO" "custom config" "[删除插件luci-light]"
			rm -rf ${file}
		fi
	}
	
	# 取消luci-ssl对luci-light依赖
	{
		file="${source_path}/feeds/luci/collections/luci-ssl/Makefile"
		if [ -e ${file} ]; then
			print_log "INFO" "custom config" "[修改插件luci-ssl]"
			
			if grep -q "+luci-light" ${file}; then
				sed -i 's/+luci-light //g' ${file}
			fi
		fi
	}
	
	# 取消luci-ssl-openssl对luci-light依赖
	{
		file="${source_path}/feeds/luci/collections/luci-ssl-openssl/Makefile"
		if [ -e ${file} ]; then
			print_log "INFO" "custom config" "[修改插件luci-ssl-openssl]"
			
			if grep -q "+luci-light" ${file}; then
				sed -i 's/+luci-light //g' ${file}
			fi
		fi
	}
	
	# 取消luci-nginx对luci-theme-bootstrap依赖
	{
		file="${source_path}/feeds/luci/collections/luci-nginx/Makefile"
		if [ -e ${file} ]; then
			print_log "INFO" "custom config" "[修改插件luci-nginx]"
			
			if grep -q "+luci-theme-bootstrap" ${file}; then
				sed -i 's/+luci-theme-bootstrap //g' ${file}
			fi
		fi	
	}
	
	# 取消luci-ssl-nginx对luci-theme-bootstrap依赖
	{
		file="${source_path}/feeds/luci/collections/luci-ssl-nginx/Makefile"
		if [ -e ${file} ]; then
			print_log "INFO" "custom config" "[修改插件luci-ssl-nginx]"
			
			if grep -q "+luci-theme-bootstrap" ${file}; then
				sed -i 's/+luci-theme-bootstrap //g' ${file}
			fi
		fi	
	}
}
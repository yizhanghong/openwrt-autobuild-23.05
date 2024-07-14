#!/bin/bash

#********************************************************************************#
# 获取OpenWrt固件
get_openwrt_firmware()
{
	print_log "TRACE" "get firmware" "正在获取OpenWrt固件，请等待..."
	
	local source_path=""
	if ! get_firmware_info $1 ${source_path}; then
		return
	fi
	
	if ! find "${source_path}/bin/targets/" -mindepth 2 -maxdepth 2 -type d -name '*' | grep -q '.'; then
		print_log "ERROR" "compile firmware" "固件目录不存在, 请检查!"
		return
	fi
	
	# 进入固件目录
	cd ${source_path}/bin/targets/*/*
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
		dir_date=$(date +"%Y%m%d")
		
		if [ -n "$(find . -mindepth 1)" ]; then
			# 版本日期路径
			version_date_path="${OPENWRT_OUTPUT_PATH}/${dir_date}"
			if [ ! -d "${version_date_path}" ]; then
				mkdir "${version_date_path}"
			fi
			
			# 固件路径
			firmware_path="${version_date_path}/${USER_CONFIG_ARRAY["firmwarename"]}"
			if [ ! -d "${firmware_path}" ]; then
				mkdir "${firmware_path}"
			fi
			
			USER_CONFIG_ARRAY["firmwarepath"]="${firmware_path}"
			# 固件输出文件
			firmware_output_file="${firmware_path}.zip"
			
			# 拷贝固件信息
			cp -rf * "${firmware_path}"
			
			# 删除包目录
			if [ -d "${firmware_path}/packages" ]; then
				rm -rf "${firmware_path}/packages"
			fi
			
			if [ "$(find "${firmware_path}" -mindepth 1)" ]; then
				# 压缩打包文件
				zip -j "${firmware_output_file}" "${firmware_path}"/*
			fi
			
			# 删除缓存文件
			rm -rf "${firmware_path}"
		fi
	else
		rm -rf packages
		USER_CONFIG_ARRAY["firmwarepath"]="$PWD"
		
		OPENWRT_FIRMWARE_NAME=${USER_CONFIG_ARRAY["firmwarename"]}
		OPENWRT_FIRMWARE_PATH=${USER_CONFIG_ARRAY["firmwarepath"]}
	fi
	
	print_log "TRACE" "get firmware" "完成获取OpenWrt固件!"
}

# 编译openwrt源码
compile_openwrt_firmware()
{
	print_log "TRACE" "compile firmware" "正在编译OpenWrt固件，请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	path=${local_source_array["Path"]}
	if [ -z "${path}" ]; then
		print_log "ERROR" "compile firmware" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	# 进入源码目录
	pushd ${path} > /dev/null
	
	# 设置信号捕捉来在退出时执行popd
	trap 'popd > /dev/null' EXIT
	
	run_make_command() {
		# 编译openwrt源码
		if [ -z "${NETWORK_PROXY_CMD}" ]; then
			make -j$(nproc) || make -j1 V=s
		else
			${NETWORK_PROXY_CMD} make -j1 V=s
		fi
	}
	
	if ! execute_command_retry 3 5 run_make_command; then
		print_log "ERROR" "compile firmware" "编译OpenWrt固件失败(Err:${ret}), 请检查!"
		return 1
	fi
	
	print_log "TRACE" "compile firmware" "完成编译OpenWrt固件!"
	return 0
}

# 下载openwrt包
download_0penwrt_package()
{
	print_log "TRACE" "download package" "正在下载OpenWrt软件包，请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"

	# 获取路径
	path=${local_source_array["Path"]}
	if [ -z "${path}" ]; then
		print_log "ERROR" "download package" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	# 进入源码目录
	pushd ${path} > /dev/null
	
	# 设置信号捕捉来在退出时执行popd
	trap 'popd > /dev/null' EXIT
	
	run_make_command() {
		# 下载软件包
		${NETWORK_PROXY_CMD} make download -j$(nproc) V=s
		
		find dl -size -1024c -exec ls -l {} \;
		find dl -size -1024c -exec rm -f {} \;
	}
	
	if ! execute_command_retry 3 5 run_make_command; then
		print_log "ERROR" "download package" "下载OpenWrt软件包失败(Err:${ret}), 请检查!"
		return 1
	fi

	print_log "TRACE" "download package" "完成下载OpenWrt软件包!"
	return 0
}

# 设置功能选项
set_menu_options()
{
	print_log "TRACE" "menu config" "正在设置软件包目录，请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	path=${local_source_array["Path"]}
	if [ -z "${path}" ]; then
		print_log "ERROR" "menu config" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	# 缺省feeds配置文件
	default_feeds_file="${path}/${USER_CONFIG_ARRAY["defaultconf"]}"
	
	# 自定义feeds配置文件
	custom_feeds_file="${OPENWRT_CONFIG_PATH}/${USER_CONFIG_ARRAY["feedsname"]}"
	
	# 进入源码目录
	pushd ${path} > /dev/null
	
	# 设置信号捕捉来在退出时执行popd
	trap 'popd > /dev/null' EXIT

	if [ ${USER_CONFIG_ARRAY["mode"]} -ne ${COMPILE_MODE[local_compile]} ]; then
		if [ ! -f "${custom_feeds_file}" ]; then
			print_log "ERROR" "menu config" "自定义feeds配置文件不存在, 请检查!"
			return 1
		fi
		
		cp -rf "${custom_feeds_file}" "${default_feeds_file}"
		make defconfig
	else
		if [ ! -f "${custom_feeds_file}" ]; then
			make menuconfig
		else
			if [ -f "${default_feeds_file}" ]; then
				if input_prompt_confirm "是否使用自定义feeds配置?"; then
					cp -rf "${custom_feeds_file}" "${default_feeds_file}"
				fi
			else
				cp -rf "${custom_feeds_file}" "${default_feeds_file}"
			fi
			
			make menuconfig
		fi

		make defconfig
		./scripts/diffconfig.sh > seed.config
	fi

	print_log "TRACE" "menu config" "完成设置软件包目录!"
	return 0
}

# 设置自定义配置
set_custom_config()
{
	print_log "TRACE" "custom config" "正在设置自定义配置，请等待..."

	# 增加第三方插件
	set_openwrt_plugins $1
	
	# 增加自定义主题
	set_openwrt_themes $1
	
	# 设置openwrt缺省配置
	set_openwrt_config $1
	
	print_log "TRACE" "custom config" "完成设置自定义配置!"
	return 0
}

# 更新 openwrt feeds源
update_openwrt_feeds()
{
	print_log "TRACE" "update feeds" "正在更新OpenWrt Feeds源，请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	path=${local_source_array["Path"]}
	if [ -z "${path}" ]; then
		print_log "ERROR" "update feeds" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	# Update feeds configuration
	print_log "INFO" "update feeds" "更新Feeds源码!"
	if ! execute_command_retry 3 5 "${NETWORK_PROXY_CMD} ${path}/scripts/feeds update -a"; then
		print_log "ERROR" "update feeds" "更新本地源失败, 请检查!"
		return 1
	fi

	# Install feeds configuration
	print_log "INFO" "update feeds" "安装Feds源码!"
	if ! execute_command_retry 3 5 "${NETWORK_PROXY_CMD} ${path}/scripts/feeds install -a"; then
		print_log "ERROR" "update feeds" "安装本地源失败, 请检查!"
		return 1
	fi

	print_log "TRACE" "update feeds" "完成更新OpenWrt Feeds源!"
	return 0
}

# 设置 openwrt feeds源
set_openwrt_feeds()
{
	print_log "TRACE" "setting feeds" "正在设置OpenWrt Feeds源，请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	path=${local_source_array["Path"]}
	if [ -z "${path}" ]; then
		print_log "ERROR" "setting feeds" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	# 设置脚本种子配置文件
	print_log "INFO" "setting feeds" "拷贝Feeds源配置文件!"
	[ -e ${OPENWRT_FEEDS_CONF_FILE} ] && cp -rf ${OPENWRT_FEEDS_CONF_FILE} ${path}
	
	# 设置种子配置文件
	print_log "INFO" "setting feeds" "设置Feeds源配置文件!"
	for key in "${!FEEDS_ARRAY[@]}"; do
		if grep -q "src-git.*${key}.*https" "${path}/feeds.conf.default"; then
			if grep -q "^#.*src-git.*${key}.*https" "${path}/feeds.conf.default"; then
				sed -i "/^#.*${key}/s/#//" "${path}/feeds.conf.default"
			fi
		else
			echo "src-git ${key} ${FEEDS_ARRAY[$key]}" >>${path}/feeds.conf.default
		fi
	done
	
	print_log "TRACE" "setting feeds" "完成设置OpenWrt Feeds源!"
	return 0
}

# 克隆openwrt源码
clone_openwrt_source()
{
	print_log "TRACE" "clone sources" "正在获取OpenWrt源码，请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"

	# 获取url
	url=${local_source_array["URL"]}
	
	# 获取branch
	branch=${local_source_array["Branch"]}
	
	# 获取路径
	path=${local_source_array["Path"]}
	
	if [ -z "${url}" ] || [ -z "${branch}" ] || [ -z "${path}" ]; then
		print_log "ERROR" "clone sources" "获取源码路径失败, 请检查!"
		return 1
	fi
	
	if [ ! -d "${path}" ]; then
		print_log "INFO" "clone sources" "克隆源码文件!"
		
		if ! execute_command_retry 3 5 "${NETWORK_PROXY_CMD} git clone ${url} -b ${branch} --depth=1 ${path}"; then
			print_log "ERROR" "clone sources" "Git获取源码失败, 请检查!"
			return 1
		fi
	else
		print_log "INFO" "clone sources" "更新源码文件!"
		
		if ! execute_command_retry 3 5 "${NETWORK_PROXY_CMD} git -C ${path} pull"; then
			print_log "ERROR" "clone sources" "更新源码失败, 请检查!"
		fi
	fi
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
		ln -sf ${path}  ${SCRIPT_CUR_PATH}
	else
		ln -sf ${path} ${GITHUB_WORKSPACE}/${OPENWRT_SOURCEDIR_NAME}
	fi

	print_log "TRACE" "clone sources" "完成获取OpenWrt源码!"
	return 0
}

#********************************************************************************#
# 自动编译openwrt
auto_compile_openwrt()
{
	# 克隆openwrt源码
	if ! clone_openwrt_source $1; then
		return
	fi
	
	# 设置 openwrt feeds源
	if ! set_openwrt_feeds $1; then
		return
	fi
	
	# 更新 openwrt feeds源
	if ! update_openwrt_feeds $1; then
		return
	fi
	
	# 设置自定义配置
	set_custom_config $1
	
	# 设置功能选项
	if ! set_menu_options $1; then
		return
	fi
	
	# 下载openwrt包
	if ! download_0penwrt_package $1; then
		return
	fi
	
	# 编译openwrt源码
	if ! compile_openwrt_firmware $1; then
		return
	fi
	
	# 获取OpenWrt固件
	get_openwrt_firmware $1
}
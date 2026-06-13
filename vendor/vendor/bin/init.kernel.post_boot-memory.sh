#=============================================================================
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

# vivo wangjiewen add for zram writeback begin
# check osversion >=Funtouch11.5/>=vos2.1
function zwb_support_osversion() {
	Version=$1
	# products for china
	if [ "$OSOverseas" == "no" ]; then
		if [ `echo $Version 11.5 | awk '{print($1<$2)?"1":"0"}'` -eq "1" ]; then
			return 0
		fi
	# products for export
	else
		if [ `echo $Version 2.1 | awk '{print($1<$2)?"1":"0"}'` -eq "1" ]; then
			return 0
		fi
	fi
	return 1
}

function zwb_support() {
	if [ ! -f /sys/block/zram0/backing_dev ]; then
		return 1
	fi

	if [ "$ROMSizeKB" -le "33554432" ];then
		return 1
	fi

	return 0
}

function zwb_version() {
	ZWBVersion=`cat /sys/block/zram0/wb`
	if [ "$ZWBVersion" == ""  ]; then
		ZWBVersion=1
	elif [ "$ZWBVersion" -le "3"   ]; then
		# RAM>=6G, ROM<=64G, keep v1
		if [ "$MemSizeKB" -gt "4194304" ] && [ "$ROMSizeKB" -lt "67108864" ]; then
			ZWBVersion=1
		elif [ "$MemSizeKB" -lt "3145728" ]; then
			ZWBVersion=1
		fi
	fi
}

function zwb_size_v1() {
	if [ $zRamSizeMB -ge 4096 ]; then
		BDSizeMB=3072
		ZWBV1Special=1
	elif [ $zRamSizeMB -ge 3072 ]; then
		BDSizeMB=1024
	elif [ $zRamSizeMB -ge 1536 ]; then
		BDSizeMB=512
	else
		BDSizeMB=`expr $zRamSizeMB / 3`
	fi
}

function zwb_size_v2() {
	if [ $zRamSizeMB -ge 4096 ]; then
		BDSizeMB=4096
		ZWBV2Special=1
	elif [ $zRamSizeMB -ge 3072 ]; then
		BDSizeMB=2048
		ZWBV2Special=2
	elif [ $zRamSizeMB -ge 2048 ]; then
		BDSizeMB=1024
	else
		BDSizeMB=`expr $zRamSizeMB / 3`
	fi
}

function zwb_size_v3() {
	if [ $zRamSizeMB -ge 4096 ]; then
		BDSizeMB=4096
	elif [ $zRamSizeMB -ge 3072 ]; then
		BDSizeMB=2048
	elif [ $zRamSizeMB -ge 2048 ]; then
		BDSizeMB=1024
	else
		BDSizeMB=`expr $zRamSizeMB / 3`
	fi
	CachePage=`expr \( $BDSizeMB / 2 + $zRamSizeMB \) \* 256`
}

function zwb_size_v4_0() {
	zRamSizeOldMB=$zRamSizeMB
	zRamSizeMBShow=`expr $RamSizeGB \* 1024`
	if [ $zRamSizeMBShow -gt 8192 ]; then
		let zRamSizeMBShow=8192
	fi
	BDSizeMB=`expr $zRamSizeMBShow / 4`

	zRamSizeMB=$zRamSizeMBShow
	if [ $RamSizeGB -gt 8 ]; then
		#zRamSizeMB=12288
		zRamSizeMB=11264
	fi
}

function zwb_size_v4_1() {
	zRamSizeOldMB=$zRamSizeMB
	zRamSizeMBShow=`expr $RamSizeGB \* 1024`
	if [ $zRamSizeMBShow -gt 16384 ]; then
		let zRamSizeMBShow=16384
	fi
	BDSizeMB=`expr $zRamSizeMBShow / 4`
	zRamSizeMB=$zRamSizeMBShow
}

# for >os4.0(upgrade and new project) and >fos4.0(only new project) support v4.1
function zwb_size_v4_1_support() {
	if [ "$OSOverseas" == "no" ] ; then
		if [ `echo $OSVersion 14.0 | awk '{print($1<$2)?"1":"0"}'` -eq "1" ]; then
			return 1
		fi
	else
		if [ `echo $OSFirstVersion 5.0 | awk '{print($1<$2)?"1":"0"}'` -eq "1" ]; then
			return 1
		fi
	fi
	return 0
}

function zwb_size_v4() {
	if zwb_size_v4_1_support ; then
		zwb_size_v4_1
	else
		zwb_size_v4_0
	fi
}

function zwb_size()
{
	if [ "$ZWBVersion" -eq "1" ]; then
		zwb_size_v1
	elif [ "$ZWBVersion" -eq "2" ]; then
		zwb_size_v2
	elif [ "$ZWBVersion" -eq "3" ]; then
		zwb_size_v3
	elif [ "$ZWBVersion" -eq "4" ]; then
		zwb_size_v4
	fi

	if [ "$ZWBVersion" -eq "4" ]; then
		setprop persist.vendor.vivo.zramwb.size $zRamSizeMBShow
	else
		setprop persist.vendor.vivo.zramwb.size $BDSizeMB
	fi
}

function zwb_user_chioce() {
	# user choice
	ZWBTriggerUser=`getprop persist.vendor.vivo.zramwb.enable`
	if [ "$ZWBTriggerUser" == "" ]; then
		ZWBTriggerUser=`getprop ro.vivo.zramwb.default`
		if [ "$ZWBTriggerUser" != "1" ] && [ "$ZWBTriggerUser" != "0" ]; then
			ZWBTriggerUser=1
		fi
	fi
}

function zwb_storage_chioce() {
	ZWBTrigger=$ZWBTriggerUser
	if [ "$ZWBTrigger" == "0" ]; then
		return
	fi

	# get life_time from ufs or emmc
	if [ -d /sys/ufs ]; then
		life_time_a=`cat /sys/ufs/life_time_a`
		life_time_b=`cat /sys/ufs/life_time_b`
	else
		life_time_a=`cat /sys/block/mmcblk0/device/dev_left_time_a`
		life_time_b=`cat /sys/block/mmcblk0/device/dev_left_time_b`
	fi

	# memory life > 5 then close zram writeback
	if [ "$life_time_a" != "0x00" ] && [ "$life_time_a" != "0x01" ] && [ "$life_time_a" != "0x02" ] && [ "$life_time_a" != "0x03" ] && [ "$life_time_a" != "0x04" ] && [ "$life_time_a" != "0x05" ]; then
		ZWBTrigger=0
	fi
	if [ "$life_time_b" != "0x00" ] && [ "$life_time_b" != "0x01" ] && [ "$life_time_b" != "0x02" ] && [ "$life_time_b" != "0x03" ] && [ "$life_time_b" != "0x04" ] && [ "$life_time_b" != "0x05" ]; then
		ZWBTrigger=0
	fi
}

# ZWBTriggerUser & ZWBTrigger
function zwb_chioce() {
	zwb_user_chioce
	zwb_storage_chioce
}

function zwb_storage_check() {
	ROMFreeSizeKB=`df -k | grep /data$ | awk '{print $4}'`
	if [ "$ROMSizeKB" -lt "33554432" ]; then
		return 1
	elif [ "$ROMSizeKB" -lt "67108864" ]; then
		if [ "$ROMFreeSizeKB" -lt "10240000" ]; then
			return 1
		fi
	elif [ "$ROMSizeKB" -lt "134217728" ]; then
		if [ "$ROMFreeSizeKB" -lt "16384000" ]; then
			return 1
		fi
	elif [ "$ROMSizeKB" -lt "536870912" ]; then
		if [ "$ROMFreeSizeKB" -lt "25600000" ]; then
			return 1
		fi
	else
		if [ "$ROMFreeSizeKB" -lt $BDSizeMB ]; then
			return 1
		fi
	fi

	return 0
}

function zwb_create_file() {
	BDPath="/data/vendor/swap/zram"
	if [ "$ZWBTriggerUser" -eq "0" ]; then
		rm $BDPath
		return
	fi

	# can delete after. just useful at loop device to file mode.
	Created=`getprop persist.vendor.vivo.zramwb.filecreate`
	if [ "$Created" != "2" ]; then
		rm $BDPath
	fi
	setprop persist.vendor.vivo.zramwb.filecreate 2

	is_f2fs1=`df -t f2fs | grep /data$`
	is_f2fs2=`mount -r -t f2fs | grep " /data "`
	# check this file. If it's un pinned, then recreate.
	if [ "$is_f2fs1" != "" ] || [ "$is_f2fs2" != "" ]; then
		is_un_pinfile=`f2fs_io pinfile get $BDPath | grep un-pinned`
		if [ "$is_un_pinfile" != "" ]; then
			rm $BDPath
		fi
	fi

	FileSizeB=`stat -c "%s" $BDPath`
	BDSizeB=`expr $BDSizeMB \* 1048576`
	if [ "$BDSizeB" == "$FileSizeB" ] || ! zwb_storage_check ; then
		return
	fi

	if [ "$is_f2fs1" == "" ] && [ "$is_f2fs2" == "" ]; then
		dd if=/dev/zero of=$BDPath bs=1m count=$BDSizeMB
	else
		touch $BDPath
		chattr -c $BDPath
		f2fs_io pinfile set $BDPath
		fallocate -l $BDSizeB -o 0 $BDPath
	fi
}

function zwb_v1_special() {
	if [ "$ZWBV1Special" -ne "1" ]; then
		return
	fi
	BDSizeMB=1536
}

function zwb_v2_special() {
	if [ "$ZWBV2Special" == "1" ]; then
		BDSizeMB=2048
	elif [ "$ZWBV2Special" == "2" ]; then
		BDSizeMB=1536
	fi
}

function zwb_v4_special() {
	if [ "$ZWBTrigger" -ne "1"  ]; then
		zRamSizeMB=$zRamSizeOldMB
	fi
}

function zwb_sp() {
	if [ "$ZWBVersion" -eq "1" ]; then
		zwb_v1_special
	elif [ "$ZWBVersion" -eq "2" ]; then
		zwb_v2_special
	elif [ "$ZWBVersion" -eq "4" ]; then
		zwb_v4_special
	fi
}

function zwb_core() {
	zwb_sp
	if [ "$ZWBTrigger" -eq "1" ]; then
		if [ "$ZWBVersion" -le "3" ]; then
			zRamSizeMB=`expr $BDSizeMB + $zRamSizeMB`
		fi
		echo $BDPath > /sys/block/zram0/backing_dev
	fi
}

function zwb_parameter_v1() {
	BDSizePage=`expr $BDSizeMB \* 256`
	if [ "$ZWBV1Special" == "1" ]; then
		echo $BDSizePage > /sys/block/zram0/zram_wb/bd_size_limit
	fi

	# bd_reclaim_min should be min watermark diff at least
	if [ -f /sys/block/zram0/zram_wb/bd_reclaim_min ]; then
		# (1536 << 10 / 4) * 2%
		if [ "$MemSizeKB" -lt "3145728" ]; then
			echo 7900 > /sys/block/zram0/zram_wb/bd_reclaim_min
		# (2048 << 10 / 4) * 2%
		elif [ "$MemSizeKB" -lt "4194304" ]; then
			echo 10500 > /sys/block/zram0/zram_wb/bd_reclaim_min
		# (3072 << 10 / 4) * 2%
		elif [ "$MemSizeKB" -lt "6291456" ];then
			echo 15800 > /sys/block/zram0/zram_wb/bd_reclaim_min
		# (4096 << 10 / 4) * 2%
		else
			echo 24000 > /sys/block/zram0/zram_wb/bd_reclaim_min
		fi
	fi
}

function zwb_parameter_v2() {
	BDSizePage=`expr $BDSizeMB \* 256`
	if [ "$ZWBV2Special" == "1" ] || [ "$ZWBV2Special" == "2" ]; then
		echo $BDSizePage > /sys/block/zram0/zram_wb/bd_size_limit
	fi

	if [ "$MemSizeKB" -lt "4194304" ]; then
		echo 80 > /sys/block/zram0/zram_wb/dswappiness_low
		echo 110 > /sys/block/zram0/zram_wb/dswappiness_high
	elif [ "$MemSizeKB" -lt "6291456" ]; then
		echo 80 > /sys/block/zram0/zram_wb/dswappiness_low
		echo 120 > /sys/block/zram0/zram_wb/dswappiness_high
	else
		echo 60 > /sys/block/zram0/zram_wb/dswappiness_low
		echo 80 > /sys/block/zram0/zram_wb/dswappiness_high
	fi
}

function zwb_parameter_v3() {
	echo $CachePage > /sys/block/zram0/zram_wb/cache
}

function zwb_parameter() {
	if [ ! -d /sys/block/zram0/zram_wb ]; then
		return
	fi

	if [ "$ZWBVersion" -eq "1" ]; then
		zwb_parameter_v1
	elif [ "$ZWBVersion" -eq "2" ]; then
		zwb_parameter_v2
	elif [ "$ZWBVersion" -eq "3" ]; then
		zwb_parameter_v3
	fi
}

function zwb_init() {
	if ! zwb_support ; then
		return
	fi

	zwb_size
	zwb_chioce
	zwb_create_file
	zwb_core
}

function zram_size_init_old() {
	let zRamSizeMB="( $RamSizeGB * 1024 ) / 2"
	# use MB avoid 32 bit overflow
	if [ $zRamSizeMB -gt 4096 ]; then
		let zRamSizeMB=4096
	fi
}

function zram_size_init_v4() {
	if [ "$RamSizeGB" -le "3" ];then
		zRamSizeMB=1536
	elif [ "$RamSizeGB" -le "4" ];then
		zRamSizeMB=2048
	elif [ "$RamSizeGB" -le "6" ];then
		zRamSizeMB=3072
	elif [ "$RamSizeGB" -le "8" ];then
		zRamSizeMB=6144
	else
		zRamSizeMB=12288
	fi
}

function zram_size_init() {
	if [ "$ZWBVersion" -eq "4" ] ; then
		zram_size_init_v4
	else
		zram_size_init_old
	fi
}

function base_info() {
	OSFirstVersion=`getprop ro.vivo.fist.os.version`
	OSVersion=`getprop ro.vivo.os.version`
	OSOverseas=`getprop ro.vendor.vivo.product.overseas`

	MemSizeKB=$MemTotal
	ROMSizeKB=`df -k | grep /data$ | awk '{print $2}'`
	if [ $RamSizeGB -gt 6 ] && [ $RamSizeGB -le 8 ]; then
		RamSizeGB=8
	elif [ $RamSizeGB -gt 8 ] && [ $RamSizeGB -lt 12 ]; then
		RamSizeGB=12
	elif [ $RamSizeGB -gt 12 ] && [ $RamSizeGB -lt 16 ]; then
		RamSizeGB=16
	fi

	zwb_version
}

function zram_algorithm_init() {
	echo "lz4" > /sys/block/zram0/comp_algorithm
	echo "algo=lz4m" > /sys/block/zram0/recomp_algorithm
}
# vivo wangjiewen add for zram writeback end

function configure_zram_parameters() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	low_ram=`getprop ro.config.low_ram`


	let RamSizeGB="( $MemTotal / 1048576 ) + 1"
	diskSizeUnit=M
	base_info
	zram_size_init

	# Zram disk - 75%
	#let zRamSizeMB="( $RamSizeGB * 1024 ) * 3 / 4"

	# use MB avoid 32 bit overflow
	#if [ $zRamSizeMB -gt 6144 ]; then
		#let zRamSizeMB=6144
	#fi

	# And enable lz4 zram compression for Go targets.
	if [ "$low_ram" == "true" ]; then
		echo lz4 > /sys/block/zram0/comp_algorithm
	fi

	if [ -f /sys/block/zram0/disksize ]; then
		if [ -f /sys/block/zram0/use_dedup ]; then
			echo 1 > /sys/block/zram0/use_dedup
		fi
		# vivo wangjiewen add for zram writeback begin
		zwb_init
		zram_algorithm_init
		# vivo wangjiewen add for zram writeback end
		echo "$zRamSizeMB""$diskSizeUnit" > /sys/block/zram0/disksize
		# vivo wangjiewen add for zram writeback begin
		zwb_parameter
		# vivo wangjiewen add for zram writeback end

		# ZRAM may use more memory than it saves if SLAB_STORE_USER
		# debug option is enabled.
		if [ -e /sys/kernel/slab/zs_handle ]; then
			echo 0 > /sys/kernel/slab/zs_handle/store_user
		fi
		if [ -e /sys/kernel/slab/zspage ]; then
			echo 0 > /sys/kernel/slab/zspage/store_user
		fi

		mkswap /dev/block/zram0
		swapon /dev/block/zram0 -p 32758
	fi
}

function configure_read_ahead_kb_values() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc -e sd)
	# dmpts holds below read_ahead_kb nodes if exists:
	# /sys/block/dm-0/queue/read_ahead_kb to /sys/block/dm-10/queue/read_ahead_kb
	# /sys/block/sda/queue/read_ahead_kb to /sys/block/sdh/queue/read_ahead_kb

	# Set 128 for <= 4GB &
	# set 512 for >= 5GB targets.
	if [ $MemTotal -le 4194304 ]; then
		ra_kb=128
	else
		ra_kb=512
	fi
	if [ -f /sys/block/mmcblk0/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0/bdi/read_ahead_kb
	fi
	if [ -f /sys/block/mmcblk0rpmb/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
	fi
	for dm in $dmpts; do
		if [ `cat $(dirname $dm)/../removable` -eq 0 ]; then
			echo $ra_kb > $dm
		fi
	done
}

function configure_thp()
{
	## Goal is to allow all allocations to use THP whilst minimizing allocaiton delays
	# Allow all eligibe page faults to use THP
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Prevent page faults on THP-elgible VMAs from causing reclaim or compaction
	echo never > /sys/kernel/mm/transparent_hugepage/defrag

	## Goal is to make khugepaged as inert as possible using the below settings
	# Prevent khugepaged from doing reclaim or compaction
	echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
	# Minimize the number of pages that khugepaged will scan
	echo 1 > /sys/kernel/mm/transparent_hugepage/khugepaged/pages_to_scan
	# Maximize the amount of time that khugepaged is asleep for
	echo 4294967295 > /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
	echo 4294967295 > /sys/kernel/mm/transparent_hugepage/khugepaged/alloc_sleep_millisecs
	# Restrict khugepaged promotions as much as possible. Only allow khugepaged to promote
	# if all pages in a VMA are (1) not invalid PTEs, (2) not swapped out PTEs, (3) not
	# shared PTEs.
	echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none
	echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_swap
	echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_shared
}

function configure_min_free_kbytes()
{
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}
	let RamSizeGB="( $MemTotal / 1048576 ) + 1"
    # Set the min_free_kbytes to standard kernel value
	if [ $RamSizeGB -ge 12 ]; then
		# 12GB, 16GB
		MinFreeKbytes=11584
	elif [ $RamSizeGB -ge 8 ]; then
		# 8GB
		MinFreeKbytes=11584
		WatermarkScale=65
		echo $WatermarkScale > /proc/sys/vm/watermark_scale_factor

	elif [ $RamSizeGB -ge 4 ]; then
		MinFreeKbytes=8192
	elif [ $RamSizeGB -ge 2 ]; then
		MinFreeKbytes=5792
	else
		MinFreeKbytes=4096
	fi

	# We store min_free_kbytes into a vendor property so that the PASR
	# HAL can read and set the value for it.
	echo $MinFreeKbytes > /proc/sys/vm/min_free_kbytes
	setprop vendor.memory.min_free_kbytes $MinFreeKbytes

}

function configure_memory_parameters() {
	# Set Memory parameters.

	configure_zram_parameters
	#configure_read_ahead_kb_values
	configure_thp
	# Enabling or disabling thp will reset the value of min_free_kbytes
	# Call configure_min_free_kbytes after
	configure_min_free_kbytes

	echo 100 > /proc/sys/vm/swappiness

	# Disable periodic kcompactd wakeups. We do not use THP, so having many
	# huge pages is not as necessary.
	echo 0 > /proc/sys/vm/compaction_proactiveness

	#Set per-app max kgsl reclaim limit and per shrinker call limit
	if [ -f /sys/class/kgsl/kgsl/page_reclaim_per_call ]; then
		echo 38400 > /sys/class/kgsl/kgsl/page_reclaim_per_call
	fi
	if [ -f /sys/class/kgsl/kgsl/max_reclaim_limit ]; then
		echo 51200 > /sys/class/kgsl/kgsl/max_reclaim_limit
	fi
}
configure_memory_parameters

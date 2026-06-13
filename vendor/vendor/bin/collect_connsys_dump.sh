#!/vendor/bin/sh

TAG="collect_connsys_dump"
DUMP_HASH_CMM="// ## Firmware version\n\
// ## ----------------\n\
// ## VIVO|11102016|xiaolei.du|QCOM_1.0.1\n\
// ## Description: "

AUTO_TRIGGER_DUMP_HASH_CMM="// ## Firmware version\n\
// ## ----------------\n\
// ## VIVO|11102016|xiaolei.du|QCOM_2.0.1\n\
// ## Description: "

SLEEP_FAIL_DUMP_HASH_CMM="// ## Firmware version\n\
// ## ----------------\n\
// ## VIVO|11102016|xiaolei.du|QCOM_3.0.1\n\
// ## Description: "

# Starts here
log -t ${TAG} "Start ${1} connsys dump..."

AutoTriggerDumpKeyWords="vivo_autominidump:"

is_auto_trigger=`dmesg | grep -i "${AutoTriggerDumpKeyWords}" | tail -1 | cut -d "vivo_autominidump:" -F 2 `
log -t $TAG $is_auto_trigger

if [ "$1" == "clear" ]; then
    rm -rf /data/vendor/ramdump/*
    if [[ -n $is_auto_trigger ]]; then
        sleep 4
        setprop "vendor.wifidump.prop.collect_logs" 1
    fi
    return
fi
if [ "$1" == "mv_logs" ]; then
    if [[ -n $is_auto_trigger ]]; then
        sleep 7
        last_wlan_logs=`ls -t /sdcard/cache/wlan_logs | grep wlan_log head -n1`
        mv /sdcard/cache/wlan_logs/cnss_fw_logs_current_split.txt /data/vendor/ramdump/cnss_fw_logs_current_split.txt
        mv /sdcard/cache/wlan_logs/host_driver_logs_current_split.txt /data/vendor/ramdump/host_driver_logs_current_split.txt
        chmod 777 /data/vendor/ramdump/cnss_fw_logs_current_split.txt
        chmod 777 /data/vendor/ramdump/host_driver_logs_current_split.txt
    fi
    return
fi

platform=`getprop ro.vivo.product.platform`
if [ "$platform" = "SM8350" ]; then
    TargetFiles=("ramdump_wlan")
    KeyWord="\[mhi_process_sfr\] "
elif [ "$platform" = "SM7325" ]; then
    TargetFiles=("ramdump_wpss" "ramdump_wcss")
    KeyWord="wpss subsystem failure reason:"
elif [ "$platform" = "SM8450" ]; then
    TargetFiles=("qcom,cnss")
    KeyWord="\[mhi_process_sfr\] "
elif [ "$platform" = "SM8475" ]; then
    TargetFiles=("qcom,cnss")
    KeyWord="\[mhi_process_sfr\] "
elif [ "$platform" = "SM8550" ]; then
    TargetFiles=("qcom,cnss")
    KeyWord="\[mhi_process_sfr\] "
elif [ "$platform" = "SM8650" ]; then
    TargetFiles=("qcom,cnss" "wlan_driver")
    KeyWord="\[mhi_process_sfr\] "
elif [ "$platform" = "SM8635" ]; then
    TargetFiles=("icnss_wcss" "remoteproc-wpss")
    KeyWord="remoteproc-wpss: fatal error received:"
elif [ "$platform" = "SM8750" ]; then
    TargetFiles=("qcom,cnss" "wlan_driver")
    KeyWord="\[mhi_process_sfr\] "
elif [ "$platform" = "SM8735" ]; then
    TargetFiles=("icnss_wcss" "remoteproc-wpss")
    KeyWord="remoteproc-wpss: fatal error received:"
else
    TargetFiles=("ramdump_w")
    KeyWord="Asserted in"
fi
log -t $TAG "platform=${platform} ,TargetFiles=${TargetFiles} ,Keyword=${KeyWord} ,AutoTriggerDumpKeyWords=${AutoTriggerDumpKeyWords}"

# Reset last dump path
setprop "vendor.wifidump.prop.last_dump_path" ""

timestamp=`date '+%Y_%m_%d_%H_%M_%S'`
# Copy dumps to cache dir
dump_dir="moredump_${timestamp}"
mkdir /data/vendor/ramdump/${dump_dir}
chmod 777 /data/vendor/ramdump/${dump_dir}

for dumpfile in ${TargetFiles[@]}; do
    if [[ `ls /data/vendor/ramdump | grep -c $dumpfile` != 0 ]]; then
        log -t $TAG "There is an elf file exit in /data/vendor/ramdump"
        mv /data/vendor/ramdump/${dumpfile}*.elf /data/vendor/ramdump/${dump_dir}
    else
        latest_elf=`ls -t /data/vendor/ssr_fulldump/${dumpfile}*.elf | head -n1`
        cp ${latest_elf} /data/vendor/ramdump/${dump_dir}
        log -t $TAG "copy ramdump file ${latest_elf} "
    fi
done

#rename elf
for dumpfile in ${TargetFiles[@]}; do
    for i in `ls /data/vendor/ramdump/${dump_dir} | grep $dumpfile`; do
        mv -f /data/vendor/ramdump/${dump_dir}/$i `echo "/data/vendor/ramdump/${dump_dir}/ramdump_wlan_"$i`;
    done
done

if [[ -n $is_auto_trigger ]]; then
    log -t $TAG "collect auto trigger dump "
    # wait for circulate log
    sleep 8
    hash=$timestamp
    echo $hash
    echo "${AUTO_TRIGGER_DUMP_HASH_CMM}${is_auto_trigger} (0x11102016)\n// ## Arguments:    ${hash}" > /data/vendor/ramdump/${dump_dir}/moredump_${timestamp}.cmm
    cat /data/vendor/ramdump/${dump_dir}/moredump_${timestamp}.cmm
    mv /data/vendor/ramdump/cnss_fw_logs_current_split.txt /data/vendor/ramdump/${dump_dir}/cnss_fw_logs_current_split.txt
    mv /data/vendor/ramdump/host_driver_logs_current_split.txt /data/vendor/ramdump/${dump_dir}/host_driver_logs_current_split.txt
    tar_file_path=/data/vendor/ramdump/moredump_${timestamp}.tar.gz
    tar -czf $tar_file_path --exclude=./bluetooth -C /data/vendor/ramdump/ .
    chmod 777 $tar_file_path
    setprop "vendor.wifidump.prop.last_dump_path" ${tar_file_path}
    return
fi

# Save dmesg
product=`getprop ro.vendor.vivo.product.model`
if [[ $(echo $product | grep "F_EX") != "" ]]; then
    log -t $TAG "product=$product. save $KeyWord only."
    dmesg | grep "$KeyWord" > /data/vendor/ramdump/${dump_dir}/kernel.log
else
    log -t $TAG "product=$product. save dmesg."
    dmesg > /data/vendor/ramdump/${dump_dir}/kernel.log
fi

# Calculate hash and write hash file
last_ocur=`cat /data/vendor/ramdump/${dump_dir}/kernel.log | grep -i "${KeyWord}" | tail -1`
echo $last_ocur
stack_trace=`echo $last_ocur | cut -d "${KeyWord}" -F 2`

echo $stack_trace
if [ -z "$stack_trace" ]; then
    log -t $TAG "stack track is not found!!"
    echo "stack track is not found!!"
    return
fi

SYS_MODEL=`getprop ro.vivo.product.model`

hash=($(echo -n $stack_trace | md5sum))
log -t $TAG $stack_trace'| hash:'$hash
hash="${hash}_${SYS_MODEL}"
sleep_fail=`cat /data/vendor/ramdump/${dump_dir}/kernel.log | grep -i "wal_css_handle_sleep_failure" | tail -1`
if [ "$sleep_fail" == "" ]; then
    echo "${DUMP_HASH_CMM}${stack_trace} (0x11102016)\n// ## Arguments:    ${hash}" > /data/vendor/ramdump/${dump_dir}/moredump_${timestamp}.cmm
else
    echo "${SLEEP_FAIL_DUMP_HASH_CMM}${stack_trace} (0x11102016)\n// ## Arguments:    ${hash}" > /data/vendor/ramdump/${dump_dir}/moredump_${timestamp}.cmm
fi

# debug
cat /data/vendor/ramdump/${dump_dir}/moredump_${timestamp}.cmm
tar_file_path=/data/vendor/ramdump/moredump_${timestamp}.tar.gz
tar -czf $tar_file_path --exclude=./bluetooth -C /data/vendor/ramdump/ .
chmod 777 $tar_file_path
setprop "vendor.wifidump.prop.last_dump_path" ${tar_file_path}

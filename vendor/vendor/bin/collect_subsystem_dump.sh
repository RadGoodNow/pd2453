#!/vendor/bin/sh
TAG="collect_subsystem_dump"
DUMP_HASH_CMM="// ## Firmware version\n\
// ## ----------------\n\
// ## VIVO|11048829|wuyuanhan|QCOM_1.0.0\n\
// ## Description: "

AUTO_TRIGGER_DUMP_HASH_CMM="// ## Firmware version\n\
// ## ----------------\n\
// ## VIVO|11048829|wuyuanhan|QCOM_1.0.0\n\
// ## Description: "

# Starts here
log -t ${TAG} "Start ${1} subsystem dump..."

if [ "$2" == "none" -o -z "$2" ]; then
	find /data/vendor/ramdump -type f | grep -v wlan  | grep -v cnss | grep -v moredump | xargs rm -rf
	exit 0
fi
subsys="$2"
echo "subsystem:$subsys."
if [ "$1" == "clear" ]; then
	if [ "$subsys" == "modem" ]; then
		log -t $TAG "rm -rf /data/vendor/ramdump/*mss*"
		rm -rf /data/vendor/ramdump/*mss*
	elif [ "$subsys" == "mss" ]; then
		log -t $TAG "rm -rf /data/vendor/ramdump/*mss*"
		rm -rf /data/vendor/ramdump/*mss*
	else
		log -t $TAG "rm -rf /data/vendor/ramdump/*"$subsys"*"
		rm -rf /data/vendor/ramdump/*"$subsys"*
	fi
	find /data/vendor/ramdump -type f | grep -v wlan  | grep -v cnss | grep -v moredump | xargs rm -rf
	echo "delete old elf."
	check_dir="/data/vendor/ramdump"
	## /data/vendor/ramdump >100M, remove.
	file_size=`du -sm ${check_dir} |awk '{print $1}'`
	echo "DIR [${check_dir}] size is ${file_size}M."
	log -t $TAG "DIR [${check_dir}] size is ${file_size}M."
	if [ ${file_size} -gt 100 ]; then
	   echo "${check_dir} size > 100M, delete."
	   echo "rm ${check_dir}/* -rf"
	   
	   log -t $TAG  "${check_dir} size > 100M, delete."
	   log -t $TAG  "rm ${check_dir}/* -rf"
	   
	   rm ${check_dir}/* -rf
	   sleep 2
	   file_size=`du -sm ${check_dir} |awk '{print $1}'`
	   echo "now, DIR [${check_dir}] size is ${file_size}M."
	   log -t $TAG "now, DIR [${check_dir}] size is ${file_size}M."
	fi
	exit 0
fi

if [ "$1" != "collect" ]; then
	echo "exit,param is invlaid:$1"
	exit 0
fi

platform=`getprop ro.soc.model`
TargetFiles=("remoteproc-mss" "remoteproc-adsp" "remoteproc-cdsp")
KeyWord="\[mhi_process_sfr\] "

log -t $TAG "platform=${platform} ,TargetFiles=${TargetFiles}"

timestamp=`date '+%Y-%m-%d %H:%M:%S'`
# Copy dumps to cache dir
root_dump_dir="ssrminidump"
dump_dir="${root_dump_dir}/$subsys/"
full_dump_dir="/data/vendor/ramdump/${dump_dir}"
full_dump_root_dir="/data/vendor/ramdump/${root_dump_dir}"
mkdir -p ${full_dump_dir}/
chmod 777 -R ${full_dump_root_dir}/

#copy ramdump elf
for dumpfile in ${TargetFiles[@]}; do
    if [[ `ls /data/vendor/ramdump | grep -c $dumpfile` != 0 ]]; then
        log -t $TAG "There is an elf file exit in /data/vendor/ramdump"
        cp /data/vendor/ramdump/${dumpfile}*.elf ${full_dump_dir}${dumpfile}.elf
        rm -rf /data/vendor/ramdump/*"$subsys"*
        rm -rf /data/vendor/ramdump/*mss*
        log -t $TAG "copy ramdump file mv /data/vendor/ramdump/${dumpfile}*.elf ${full_dump_dir}${dumpfile}.elf"
    fi
done

#generate log file
dmesg > ${full_dump_dir}/kmsg.log
/system/bin/logcat -t 20000 > ${full_dump_dir}/logcat.log
getprop ro.vivo.product.version > ${full_dump_dir}/version.txt
echo $timestamp > ${full_dump_dir}/time.txt
echo "no" > ${full_dump_dir}/last_time.txt
line_reason=`dmesg | grep 'ssr mon' | tail -n 1`

### crash info, eg: [ 9560.957592] ssr mon update [modem] crash info, count=5, reason:qmi_nas_bbk.c:393:Assertion 0 failed
echo ${line_reason#*reason:} > ${full_dump_dir}/reason.txt
echo $subsys > ${full_dump_dir}/subsys.txt

# Calculate hash and write hash file
rm -rf ${full_dump_dir}/hash_buf.txt
cat ${full_dump_dir}/reason.txt >${full_dump_dir}/hash_buf.txt
cat ${full_dump_dir}/subsys.txt >>${full_dump_dir}/hash_buf.txt
cat ${full_dump_dir}/version.txt >>${full_dump_dir}/hash_buf.txt


md5sum -b ${full_dump_dir}/hash_buf.txt >${full_dump_dir}/hash.txt
hash_buf=`cat ${full_dump_dir}/hash_buf.txt`
md5_buf=`cat ${full_dump_dir}/hash.txt`
log -t $TAG "hash_buf:${hash_buf}, md5:${md5_buf} ######"
cat ${full_dump_dir}/hash_buf.txt
cat ${full_dump_dir}/hash.txt
#rm -rf ${full_dump_dir}/hash_buf.txt
echo tar zcvf ${full_dump_dir}/../subsystem_ramdump.tar.gz ${full_dump_dir}
rm -rf ${full_dump_dir}/subsystem_minidump.tar.gz
tar zcvf ${full_dump_dir}/../subsystem_minidump.tar.gz ${full_dump_dir}
mv  ${full_dump_dir}/../subsystem_minidump.tar.gz  ${full_dump_dir}/subsystem_minidump.tar.gz

chmod 777 -R ${full_dump_dir}

## trigger copy ramdump file"
setprop "persist.vendor.ssr.vivo.copydump" "0"
log -t $TAG "persist.vendor.ssr.vivo.copydump" "0"
sleep 2
log -t $TAG "persist.vendor.ssr.vivo.copydump" "1"
setprop "persist.vendor.ssr.vivo.copydump" "1"
sleep 3
log -t $TAG "delete temp files."
rm -rf ${full_dump_dir}/
echo finish.

log -t ${TAG} "End ${1} subsystem dump..."
exit 0

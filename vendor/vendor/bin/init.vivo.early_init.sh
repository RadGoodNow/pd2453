#! /vendor/bin/sh

export PATH=/vendor/bin

function vivo_bsp_ftrace_instance() {
	# vivo.bsp.ftrace.instance init 0
	setprop vivo.bsp.ftrace.instance 0

	kernel_cmdline=`cat /proc/cmdline`
	if echo ${kernel_cmdline} | grep 'boot_bsptmode=1'; then
		echo "vivo_bsp_ftrace_instance: boot_bsptmode=1" > /dev/kmsg
	else
		echo "vivo_bsp_ftrace_instance: boot_bsptmode=0" > /dev/kmsg
		exit 0
	fi

	tracefs=/sys/kernel/tracing
	if [ -d $tracefs ]; then
		VIVOBSP=$tracefs/instances/vivobsp
		mkdir $VIVOBSP

		# disable vivobsp ftrace instance
		echo 0 > $VIVOBSP/tracing_on

		# disable main ftrace
		echo "vivo_bsp_ftrace_instance: disable main ftrace" > /dev/kmsg
		echo 0 > /sys/kernel/tracing/tracing_on
		setprop vivo.bsp.ftrace 0


		# set buffer size
		echo 81920 > $VIVOBSP/buffer_size_kb

		# record-tgid
		echo 1 > $VIVOBSP/options/record-tgid
		# timer
		echo 1 > $VIVOBSP/events/timer/enable
		# workqueue
		echo 1 > $VIVOBSP/events/workqueue/enable
		# irq
		echo 1 > $VIVOBSP/events/irq/enable
		# sched
		echo 1 > $VIVOBSP/events/sched/enable
		#schedwalt
		echo 1 > $VIVOBSP/events/schedwalt/sched_find_best_target/enable
		echo 1 > $VIVOBSP/events/schedwalt/sched_set_preferred_cluster/enable
		echo 1 > $VIVOBSP/events/schedwalt/sched_cpu_util/enable
		echo 1 > $VIVOBSP/events/schedwalt/sched_compute_energy/enable
		echo 1 > $VIVOBSP/events/schedwalt/sched_enq_deq_task/enable
		# power
		echo 1 > $VIVOBSP/events/power/enable
		# regulator
		echo 1 > $VIVOBSP/events/regulator/enable
		# fastrpc
		echo 1 > $VIVOBSP/events/fastrpc/enable


		# enable vivobsp ftrace instance
		echo "vivo_bsp_ftrace_instance: enable vivobsp ftrace instance" > /dev/kmsg
		echo 1 > $VIVOBSP/tracing_on
		setprop vivo.bsp.ftrace.instance 1
		# end
	fi
}

vivo_bsp_ftrace_instance

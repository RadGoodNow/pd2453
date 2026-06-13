#!/vendor/bin/sh

logdir=/data/media/0/iclogs
if [ ! -d $logdir ];then
    echo $logdir does not exist and creat it
    mkdir -p $logdir
fi

current_time=$(date +%Y%m%d_%H%M%S)
logfile=$logdir/iclog_$current_time.txt
echo current_time is $current_time
echo logfile is $logfile

/vendor/bin/nvt_test uartlog > $logfile &

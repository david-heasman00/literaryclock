#!/bin/sh
#Add debugging logs
exec > /mnt/us/timelit/kual_debug.log 2>&1
set -x

#Pre-emptively add source folder for python not found error via KUAL
#source /etc/profile

BASEDIR="/mnt/us/timelit"

#Fix sustem paths - self healing for reboots
/bin/mkdir -p /var/spool/cron/crontabs
/bin/chmod 755 /var/spool/cron/crontabs

clockrunning=1

# check if the clock 'app' is not running (by checking if the clockisticking file is there) 
test -f "$BASEDIR/clockisticking" || clockrunning=0

if [ $clockrunning -eq 0 ]; then

	/usr/bin/lipc-set-prop com.lab126.powerd preventScreenSaver 1 || true
	/sbin/stop framework || true
	/sbin/stop powerd || true

	
	/usr/sbin/eips -c  # clear display
	#echo "Clock is not ticking. Lets wind it."
	#eips "Clock is not ticking. Lets wind it."

	# THE ENGINE: Add the timer to the Kindle schedule
    (/usr/bin/crontab -l 2>/dev/null | /bin/grep -v "timelit.sh"; echo "* * * * * /bin/sh $BASEDIR/timelit.sh") | /usr/bin/crontab -

	# run showMetadata.sh to enable the keystrokes that will show the metadata
    # sh "$BASEDIR/showMetadata.sh"

    /bin/touch "$BASEDIR/clockisticking"
    /bin/sh "$BASEDIR/timelit.sh"

else

    /bin/rm "$BASEDIR/clockisticking"
	/usr/bin/killall showMetadata.sh waitforkey || true

	# STOP THE ENGINE: Remove the timer from the schedule
    /usr/bin/crontab -l 2>/dev/null | /bin/grep -v "timelit.sh" | /usr/bin/crontab -

	/usr/sbin/eips -c  # clear display
	#echo "Clock is ticking. Make it stop."
	#eips "Clock is ticking. Make it stop."

	# go to home screen
	# echo "send 102">/proc/keypad
	
	/sbin/start powerd || true
	/usr/bin/lipc-set-prop com.lab126.powerd preventScreenSaver 0 || true
	/sbin/start framework || true
	
fi
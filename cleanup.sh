#!/bin/bash
#shopt -s nullglob dotglob

#CHECK FOOR DEPENDENCIES
if ! command -v fdfind &>/dev/null; then echo "PLEASE INSTALL fd-find, sudo apt install fd-find!" && exit; fi
if ! command -v sd &>/dev/null; then echo "PLEASE INSTALL sd, cargo install sd!" && exit; fi

#full absolute script path
SCRIPT=$(readlink -f "$0")
#script folder absolute
SCRIPTPATH=$(dirname "$SCRIPT")
#process id of the script
SCRIPTID=$BASHPID
#file the logs will be written
LOGPATH="$SCRIPTPATH/logs/cleanup.log"
#check for --debug as argument to enable logs
DEBUG=$(if [[ "$1" == "--debug" ]]; then echo 1; else echo 0; fi)

# remove existing log
if [ -f "$LOGPATH" ]; then rm -f $LOGPATH; fi

# create folder for loif not exit
if [ $DEBUG -eq 1 ] && ! [ -d "$SCRIPTPATH/logs" ]; then
	mkdir "$SCRIPTPATH/logs"
fi

#simple log to $LOGPATH/nav.log 2 str args possible call it like log "message" "message"
log() {
	if [ $DEBUG -eq 1 ]; then
		echo "$1" >>$LOGPATH
		echo "$2" >>$LOGPATH
	fi
}

#index all md file in docs (not used right now)
CLEANUP_FILES=$(fdfind . "./docs" -e md -d 1 | sort)

#main function
cleanup() {
	for file in $CLEANUP_FILES; do
		if ! [ -d $(echo $file | sd '(.*)\.md' '$1') ]; then
			mkdir $(echo $file | sd '(.*)\.md' '$1')
			log $(echo $file | sd '(.*)\.md' 'Folder created $1')
			mv $file $(echo $file | sd '(.*)\.md' '$1')
		fi
	done
}

cleanup

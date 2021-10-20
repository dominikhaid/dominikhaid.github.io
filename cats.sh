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
LOGPATH="$SCRIPTPATH/logs/cats.log"
#check for --debug as argument to enable logs
DEBUG=$(if [[ "$1" == "--debug" ]]; then echo 1; else echo 0; fi)

# remove existing log
if [ -f "$LOGPATH" ]; then rm -f $LOGPATH; fi

# create folder for loif not exit
if [ $DEBUG -eq 1 ] && ! [ -d "$SCRIPTPATH/logs" ]; then
	mkdir "$SCRIPTPATH/logs"
fi

#simple log to $LOGPATH/nav.log 1 arg str 2 array call it like log "message" ARRAY
logArr() {
	if [ $DEBUG -eq 1 ]; then
		echo "$1" >>$LOGPATH

		if [ -z "$2" ]; then
			local -n logArr=$2
			printf "%s\n" $logArr >>$LOGPATH
		fi
	fi
}

#simple log to $LOGPATH/nav.log 2 str args possible call it like log "message" "message"
log() {
	if [ $DEBUG -eq 1 ]; then
		echo "$1" >>$LOGPATH
		echo "$2" >>$LOGPATH
	fi
}

#index all docs folders (not used right now)
CREATE_INDEXPAGES=$(fdfind . "./docs" -t d -d 3 | sort)

#create index page args file title
writeHead() {
	cat <<FOE >>$1
---
layout: topic
title: ${2}
---

<section class="col-12 flex-wrap d-flex text-box flex-justify-start ml-0">
## {{ page.title | upcase }}
FOE

}

#write rest  of the index page args, $file
writeEnd() {
	cat <<FOE >>$1
{: .link-box.ml-0}
</section>
FOE

}

#write indexd list elements to file, args $file $string
writeList() {
	cat <<FOE >>$1
 $2. [$3]($4)
FOE
}

#main function
category() {
	declare -i cnt=1
	declare -a list
	for folder in $CREATE_INDEXPAGES; do
		title=$(echo $folder | sd '.*/(.*)$' '$1' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')
		newFile=$(echo "$folder.md")
		if ! [ -f "$folder.md" ]; then
			writeHead $newFile $title
			cnt=1
			for file in $(eval fdfind . $folder -e md -d 1 | sort); do
				filename=$(echo "$file" | sd '.*/(.*).md$' '$1' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')
				link=$(echo "$file" | sd '(.*).md$' '/$1')
				writeList $newFile $cnt $filename $link
				cnt+=1
			done
			writeEnd $newFile
		fi
	done
}

category

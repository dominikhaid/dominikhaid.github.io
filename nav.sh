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
LOGPATH="$SCRIPTPATH/logs/nav.log"
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

#setup variables just in our json output, like $url or $title
filenameFromater() {
	url=$(echo $file | sd '(.*).md' '$1')
	title=$(echo $file | sd 'docs/(.*).md' '$1' | awk '{print toupper($0)}')
	page2=$(echo $file | sd 'docs/(.*)/(.*).md' '$2' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')
	page3=$(echo $file | sd 'docs/(.*)/(.*)/(.*).md' '$3' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')

	tmp=$(echo $file | sd '(.*)/(.*)/(.*)' '$2')
	tmp_sub=""
}

# index all pages to TOPPAGES SUBPAGES arrays
indexAllPages() {
	if ! [[ "$tmp" == "" ]] && ! [[ "$tmp" =~ ".md" ]]; then
		TOPPAGES+="docs/$tmp "
	elif ! [[ "$tmp" == "" ]] && [[ "$tmp" =~ ".md" ]]; then
		TOPPAGES+=$(echo "$tmp " | sd 'docs/(.*).md' 'docs/$1')
	fi

	tmp=$(echo $file | sd '(.*)/(.*)/(.*)/(.*)' '$2/$3')
	if ! [[ "$tmp" == "" ]] && ! [[ "$tmp" =~ ".md" ]]; then
		SUBPAGES+="$tmp "
	fi
}

#first file scaned triggers this, $OUTPUT will be prepared
initOutput() {
	CURRENT_GRP=$tmp_grp
	if [ $(echo "$file" | tr -cd '/' | wc -c) -eq 2 ]; then
		log "NEW PAGE LEVEL 2" $file
		PAGES_ARR_STR+='{"page": "'$page2'","url": "/'$url'"},'
	else
		log "ADD ITEM LEVEL 1" $tmp_grp

		log "1. NEW PAGE LEVEL 1" $file
		TOPIC_TITLE_STR+='"title": "'$title'","url": "/'$url'",'
	fi
}

#create a new topic, 1 level grp
newTopic() {
	log "1. CLOSE ITEM LEVEL 1"
	CURRENT_GRP=$tmp_grp
	log "ADD NEW ITEM LEVEL 1" $tmp_grp
	OUTPUT+='{'$TOPIC_TITLE_STR' "pages": ['$PAGES_ARR_STR'],},'

	TOPIC_TITLE_STR=''
	PAGES_ARR_STR=''
	SUBPAGES_ARR_STR=''

	if [ $(echo "$file" | tr -cd '/' | wc -c) -eq 3 ]; then
		tmp_sub=$(echo $file | sd '(.*)/(.*)/(.*)/(.*)' '$2/$3')
		CURRENT_SUB=$tmp_sub
		log "ADD NEW SUBPAGES ARR level 3" $tmp_sub

		addNewSubpageToString
	elif [ $(echo "$file" | tr -cd '/' | wc -c) -eq 2 ]; then
		log "NEW PAGE LEVEL 2" $file
		PAGES_ARR_STR+='{"page": "'$page2'","url": "/'$url'"},'
	else
		log "2. NEW PAGE LEVEL 1" $file
		TOPIC_TITLE_STR+='"title": "'$title'","url": "/'$url'",'
	fi
}

# write all $OUTPUT to file
writeToFile() {
	OUTPUT+='{'$TOPIC_TITLE_STR' "pages": [ '$PAGES_ARR_STR']},'
	OUTPUT+=']}]}'
	OUTPUT=$(echo $OUTPUT | sd ',}' '}')
	OUTPUT=$(echo $OUTPUT | sd ',]' ']')
	echo $OUTPUT >"./_data/nav.json"
}

#just close the current subpage grp
closeSubCheck() {
	log "CLOSE SUBPAGES ARR LEVEL 3"
	if ! [[ $SUBPAGES_ARR_STR == '' ]]; then
		PAGES_ARR_STR=$(echo $PAGES_ARR_STR | sd '},$' '')
		PAGES_ARR_STR+=', "subpages": ['$SUBPAGES_ARR_STR']},'
		SUBPAGES_ARR_STR=''
	fi
}

# handle Index pages for Subpages level 3
handleSubIndexPages() {
	if
		! [[ $CURRENT_SUB == $(echo $file | sd 'docs/(.*).md' '$1') ]]
	then
		closeSubPagesAndWrite
	else
		log "NEW PAGE LEVEL 2" $file
		PAGES_ARR_STR+='{"page": "'$page2'","url": "/'$url'"},'
	fi
}

# close the current subpage and write the current file to level 2
closeSubPagesAndWrite() {
	closeSubCheck
	CURRENT_SUB=""
	if [ $(echo "$file" | tr -cd '/' | wc -c) -eq 1 ]; then
		log "2. NEW PAGE LEVEL 1" $file
		TOPIC_TITLE_STR+='"title": "'$title'","url": "/'$url'",'
	else
		log "NEW PAGE LEVEL 2 / CLOSE SUB" $file
		PAGES_ARR_STR+='{"page": "'$page2'","url": "/'$url'"},'
	fi
}

#trim tmp_grp to topic?/page?/subpage , like docker or programming/java or programming/javascript/react
tirmToPath() {
	tmp_grp=$(echo $tmp | sd 'docs/(.*)' '$1' | sd '(.*)/(.*)' '$1')
	if [[ $(echo "$tmp_grp" | sd '.*(\.md)' '$1') == ".md" ]]; then
		tmp_grp=$(echo $tmp_grp | sd 'docs/(.*)' '$1' | sd '(.*).md' '$1')
	fi
}
#add a new page to the PAGES_ARR_STR
addNewPageToString() {
	log "NEW PAGE LEVEL 2" $file
	PAGES_ARR_STR+='{"page": "'$page2'","url": "/'$url'"},'
}

#add a new topic to the TOPIC_TITLE_STR
addNewTopicToString() {
	log "3. NEW PAGE LEVEL 1" $file
	TOPIC_TITLE_STR+='"title": "'$title'","url": "/'$url'",'
}

#add the filte to SUBPAGES_ARR_STR
addNewSubpageToString() {
	log "NEW PAGE LEVEL 3" $file
	SUBPAGES_ARR_STR+='{"page": "'$page3'","url": "/'$url'"},'
}

TOPICS=()
TOPPAGES=()
SUBS=()
SUBPAGES=()
SUBSUBPAGES=()
SUBSUBS=()

CURRENT_GRP=''
CURRENT_SUB=''

PAGES_ARR_STR=''
TOPIC_TITLE_STR=''
SUBPAGES_ARR_STR=''

OUTPUT='{"items": [{ "topics": ['

#index all docs folders (not used right now)
FOLDERS=$(fdfind . "./docs" -t d -d 3 | sort)
#index all md file in docs (not used right now)
FILES=$(fdfind . "./docs" -e md -d 3 | sort)

#main function
main() {
	for file in $FILES; do
		filenameFromater
		indexAllPages
		tirmToPath

		if [[ "$CURRENT_GRP" == "" ]]; then
			#Check if its the first file and start the output
			#This will just runs for the file
			initOutput
		elif ! [[ "$CURRENT_GRP" == $tmp_grp ]]; then
			#check if its a new topic or the previous
			# Items will get closed here, new topic starts and ends here
			newTopic
		else
			#existing topic will be continued here
			tmp_sub=$(echo $file | sd '(.*)/(.*)/(.*)/(.*)' '$2/$3')
			if [[ "${SUBPAGES[@]}" =~ "${tmp_sub}" ]]; then
				#check if current file is existing in the index subpages
				if ! [[ "$CURRENT_SUB" == $tmp_sub ]]; then
					#check if there is already a subpage for this topic
					if ! [[ "$CURRENT_SUB" == "" ]]; then
						#check if we must close the grp, CURRENT_SUB == '' is done by use to close on porpus
						closeSubCheck
					fi
					#set the CURRENT_SUB to the new file
					CURRENT_SUB=$tmp_sub
					log "ADD NEW SUBPAGES ARR level 3" $tmp_sub
					addNewSubpageToString
				else
					addNewSubpageToString
				fi
			elif ! [[ "$CURRENT_SUB" == "" ]]; then
				#check if CURRENT_SUB is set, if not we unset it un porpus to get here
				if [ $(echo "$tmp_sub" | tr -cd '/' | wc -c) -eq $(echo "docs/$CURRENT_SUB" | tr -cd '/' | wc -c) ]; then
					handleSubIndexPages
				else
					closeSubPagesAndWrite
				fi
			else
				if [ $(echo "$file" | tr -cd '/' | wc -c) -eq 2 ] || [ $(echo "$tmp_sub" | tr -cd '/' | wc -c) -eq 2 ]; then
					#count dashes in path to see if we are level 2 or 1
					addNewPageToString
				else
					log "ADD NEW ITEM LEVEL 1" $tmp_grp
					addNewTopicToString
				fi
			fi

		fi

	done
}

main
writeToFile

TOPPAGES=$(printf "%s\n" $TOPPAGES | sort -u)
SUBPAGES=$(printf "%s\n" $SUBPAGES | sort -u)

log "TOP LEVEL" TOPPAGES
logArr "TOP SUB" SUBPAGES

log "FOLDERS" FOLDERS
log "FILES" FILES

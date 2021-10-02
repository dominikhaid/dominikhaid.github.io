#! /bin/bash
shopt -s nullglob dotglob
options=($(echo $@ | tr " " "\n"))

#NOTE DEAFULTS
folder='./assets/images'
type="jpg"
ext=".jpg"
convert=$type
regType=".jpg|.jpeg"
findRule="-iname '*.jpg' -o -iname '*.jpeg'"
quality=75
declare -i summ=0
declare -a width=(640 1200 1920 3840)
#width=800

#NOTE ARRY TEST declare -p width 2>/dev/null | grep 'declare \-a' >/dev/null && echo "var is an array"
is_array() { #detect if arg is an array, returns 0 on sucess, 1 otherwise
	[ -z "$1" ] && echo 1 && return 1
	if [ -n "$BASH" ]; then
		declare -p ${1} 2>/dev/null | grep 'declare \-a' >/dev/null && echo 0 && return 0
	fi
	echo 1 && return 1
}

# if [[ $(is_array width) == 0 ]]; then
#     echo "array"
# else
#     echo "no"
# fi

# exit

#NOTE TOOLS
__help=$"
Usage: $(basename $0) [OPTIONS]
Options:
  -f                           Set folder defaults to ./
  -t                           Set type defaults to jpg
  -c                           Set convert defaults to input type
  -q                           Set quality defaults to 75
  -w                           Set output width defaults to 800
"

__init=$"
Starting batch converting images
____________________________________________________________________
in: $folder recursively
types: $type
"

#NOTE DISPLAY HELP
info() {
	echo "$__help"
	exit
}

#NOTE PRINT SUMMERY
summery() {
	__summery=$"
___________________________________________________________________
Total convertions: $1  Folder: $folder Input Type: ${type} Output Type: ${convert}  Witdh: $width
Output pattern: filename_${width}_${quality}${type}
_____________________________________________________________________
"

	echo "$__summery"
}

#NOTE HANDEL ARGUMENTS
set_variables() {
	declare -i i=0
	for o in "${options[@]}"; do
		param=${options[$i + 1]}

		if [ $o = '-t' ] && [ ! -z "$param" ]; then
			type=$param
			ext=".jpg"
			regType=".jpg"
			findRule="-iname '*.$type'"
			if [$type == 'jpg'] || [$type == "jpeg"]; then
				regType=".jpg|.jpeg"
				findRule="-iname '*.jpg' -o -iname '*.jpeg'"
			fi
		fi

		if [ $o = '-f' ] && [ ! -z "$param" ]; then
			folder=$param
		fi

		if [ $o = '-c' ] && [ ! -z "$param" ]; then
			convert=$param
		fi

		if [ $o = '-q' ] && [ ! -z "$param" ]; then
			quality=$param
		fi

		if [ $o = '-w' ] && [ ! -z "$param" ]; then
			width=$param
		fi

		i+=1
	done
}

#NOTE COPY / RENAME / COMPRESS
copy_compress() {
	declare -i cnt=0
	for i in $(eval find $folder "$findRule" | sd '.*_\d\d?\d?\d_\d\d?\d.*' ''); do
		if [[ $(echo $i) == '' || "$i" =~ '_ignore' ]]; then
			continue
		fi

		if [[ $(echo $i | sd '.*_\d\d?\d?\d_\d\d?\d.*'$ext '') == '' ]]; then
			continue
		fi

		if [[ "$ext" == ".jpg" && ! "$i" =~ ".jpg" && ! "$i" =~ ".jpeg" ]]; then
			continue
		fi

		if [[ "$ext" != ".jpg" && ! "$i" =~ "$ext" ]]; then
			continue
		fi

		for wdth_ind in "${width_call[@]}"; do

			if test -f $(echo "${i}?w=${wdth_ind}&q=${quality}" | sd '(?P<fn>.*?)(?P<ty>'$ext')\?w=(?P<wdt>\d+)&q=(?P<qlt>\d+)' '${fn}_${wdt}_${qlt}${ty}'); then
				continue
			fi

			if [[ "$i" =~ "${wdth_ind}_${quality}${ext}" ]]; then
				continue
			fi

			#NOTE COPY FILE AND DO COVERSION
			f_magic=$(echo "${i}?w=${wdth_ind}&q=${quality}" | sd '(?P<fn>.*?)(?P<ty>'$regType')\?w=(?P<wdt>\d+)&q=(?P<qlt>\d+)' '${fn}_${wdt}_${qlt}${ty}')
			f_copy=$(echo "${i}?w=${wdth_ind}&q=${quality}" | sd '(?P<fn>.*?)(?P<ty>'$regType')\?w=(?P<wdt>\d+)&q=(?P<qlt>\d+)' '${fn}$ty ${fn}_${wdt}_${qlt}${ty}')
			cp $f_copy

			#NOTE IF COVERSION NEEDED
			if [[ "$i" =~ ".jpeg" ]]; then
				mogrify -format $convert -quality $quality -resize ${wdth_ind}x "$f_magic"
				rm $f_magic
			elif [[ $type != $convert ]]; then
				mogrify -format $convert -quality $quality -resize ${wdth_ind}x "$f_magic"
				rm $f_magic
			else
				mogrify -quality $quality -resize ${wdth_ind}x "$f_magic"
			fi
			cnt+=1
		done

	done

	echo "$cnt"
}

if [ "$1" == '--help' ]; then
	info
else
	echo "$__init"
	set_variables
	#NOTE SET WIDTH TO AN ARRAY
	if [[ $(is_array width) == 0 ]]; then
		width_call=("${width[@]}")
		#copy_compress
		summ=$(copy_compress)
	else
		declare -a width_call=($width)
		summ=$(copy_compress)
	fi
	summery $summ
	echo "---- DONE ----"
fi
exit

#TODO TYPE ARRAY AS ARG
#TODO WIDTH ARRAY AS ARG
#TODO FOLDER ARRAY AS ARG
#TODO PREVENT RESAVE CONVERTED PICTURES

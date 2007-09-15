#!/bin/bash

faq_init() {
	local i=0
	unset faq_array
	while read -d $'\n' line ;do
		i=$((i+1))
		faq_array[$i]="$line"
	done < ./faq.txt
}

# $1 = from who (n!u@h)
# $2 = what channel
# $3 = the message
faq_on_channel_PRIVMSG() {
	local sender="$1"
	local channel="$2"
	local query="$3"
	if [[ "$query" =~ ^\;faq.* ]]; then
		query="${query//\;faq/}"
		query="${query/^ /}"
		query_time="$(date +%H%M)$line"
		if [[ "$last_query" != "$query_time" ]] ; then #must be atleast 1 min old or different query...
			last_query="$(date +%H%M)$line"
			if [[ "$query" -gt 0 ]] && [[ "$query" -lt 54 ]] ; then
				log "$channel :$query is numeric"
				irc_msg "$channel" "${faq_array[$query]}"
				sleep 1
			elif [[ "${#query}" -ge 3 ]] ; then
				i=0
				while [[ $i -lt "${#faq_array[*]}" ]] ; do
					i=$((i+1))
					if echo ${faq_array[$i]} | cut -d " " -f 3- | /bin/grep -i -F -m 1 "$query" ; then
						log "$channel :${faq_array[$i]}"
						irc_raw "$channel" "${faq_array[$i]}"
						sleep 1
						break 1
					fi
				done
			fi
		else
			log "ERROR : FLOOD DETECTED"
		fi
	fi

}
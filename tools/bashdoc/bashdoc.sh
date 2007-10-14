#!/bin/bash

# Make env sane
unset LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
unset LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS
unset LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION
export LC_ALL=C
export LANG=C

# Check bash version. We need at least 3.2.x
# Lets not use anything like =~ here because
# that may not work on old bash versions.
if [[ "$(awk -F. '{print $1 $2}' <<< $BASH_VERSION)" -lt 32 ]]; then
	echo "Sorry your bash version is too old!"
	echo "You need at least version 3.2 of bash"
	echo "Please install a newer version:"
	echo " * Either use your distro's packages"
	echo " * Or see http://www.gnu.org/software/bash/"
	exit 2
fi

# To make set -x more usable
export PS4='(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} : '

VERSION="0.1.8"
HEADERS="<!-- Generated by bashdoc version $VERSION, on $(date). -->
<link rel=\"stylesheet\" href=\"style.css\" type=\"text/css\" />
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"

#--------------------------
##	@Synopsis	Reads specialy formated shell scripts and creates docs
##	@Copyright	Copyright 2003, Paul Mahon
##	@Copyright	Copyright 2007, Arvid Norlander
##	@License	GPL v2
##	Parses comments between lines of '#---'
##	Lines to be parsed start with ##. All tags start with @.
##	Lines without a tag are considered simple description of the section.
##	If the line following the comment block doesn't start with 'function'
##	the it's assumed that the comment is for the whole file. Only the first
##	non-function comment block will be used, the other will be ignored.
##	<p>
##	Multiple identical tags are allowed, the contents are appended and separated
##	with a space. @param tags are treated specials and are assumed to be in order.
##	<p>
##	There is an additional &lt;@function FUNCTION_NAME&gt; tag that can be embeded
##	in any bashdoc comment. It will be transformed into a link to that function.
##	Note, this will only work for functions that are defined in the same script.
##	<p><pre>
##	Usage:	[-p project] [-o directory] [-e tag] [--] script [ script ...]
##	-p, --project project   Name of the project
##	-o, --output directory  Specifies the directory you want the resulting html to go into
##	-e, --exclusive tag     Only output if the block has this tag
##	-q, --quiet             Quiet the output
##	-h, --help              Display this help and exit
##	-V, --version           Output version information and exit
##	--                      No more arguments, only scripts
##	script                  The script you want documented
##</pre>
##
#--------------------------

#--------------------------
##	@Arguments	-r: recursive, -o [directory]: output html
##	Parses arguments for this script
##	@Gobals	RECURSIVE, OUT_DIR
#--------------------------
function args()
{
	local retVal=0
	QUIET=0
	while true ; do
		case $1 in
			-p|--project)
				PROJECT="$2"
				let retVal+=2
				shift 2
				;;
			-o|--output)
				OUT_DIR="$2"
				let retVal+=2
				shift 2
				;;
			--help|-h)
				usage
				exit 0
				;;
			--version|-V)
				version
				exit 0
				;;
			--exclusive|-e)
				EXCLUSIVE="${2%%=*}"
				EXCLUSIVE_VAL="${2#*=}"
				let retVal+=2
				shift 2
				;;
			--quiet|-q)
				let QUIET+=1
				let retVal+=1
				shift 1
				;;
			--)
				let retVal++
				return $retVal
				;;
			-*)
				usage
				exit 0
				;;
			*)
				[[ -e $1 ]] && return $retVal
				echo "$1 doesn't exist."
				usage
				exit 1
				;;
		esac
	done
}

#-------------------------
##	Version for this script
##	@Stdout	Version information
#-------------------------
function version()
{
	echo "bashdoc $VERSION - Generate HTML documentation from bash scripts"
	echo ''
	echo 'Copyright (C) 2003 Paul Mahon'
	echo 'Copyright (C) 2007 Arvid Norlander'
	echo 'This is free software; see the source for copying conditions.  There is NO'
	echo 'warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.'
	echo ''
	echo 'Written by Paul Mahon and modified by Arvid Norlander'
}

#-------------------------
##	Usage for this script
##	@Stdout	Usage information
#-------------------------
function usage()
{
cat <<- EOF
bashdoc generates HTML documentation from bash scripts.

Usage: $(basename $0) [-p project] [-o directory] [--] script [script ...]

Options:
  -p, --project project   Name of the project
  -o, --output directory  Specifies the directory you want the resulting html to go into
  -e, --exclusive tag     Only output if the block has this tag
  -q, --quiet             Quiet the output
  -h, --help              Display this help and exit
  -V, --version           Output version information and exit
  --                      No more arguments, only scripts
  script                  The script you want documented

Examples:
  $(basename $0) -p bashdoc -o docs/ bashdoc.sh              Generate documentation for this program.
  $(basename $0) -p appname -o docs/ -e Type=API someapp.sh  Generate documentation for someapp.sh,
                                                             exclude items that do not include the tag
                                                             @Type API
EOF
}


#--------------------------
##	Reads until it has read an entire comment block. A block starts with
##	<br><pre>#---</pre></br>
##	Alone on a line, and continues until the next
##	<br><pre>#---</pre></br>
##	All comment lines inside should have ## at the start or they
##	will be ignored.
##
##	@return 0 Possibly more blocks
##	@return 1 Unexpected end of file
##	@return 2 Expected end of file, no more blocks
##	@Stdin	Reads a chunk
##	@Stdout	Block with starting '##' removed
##	@Globals	paramDesc, retDesc, desc, block, split
#--------------------------
function get_comment_block()
{
	local inComment commentBlock lastLine=""
	commentBlock=""
	while read LINE ; do
		let srcLine++
		if [[ ${LINE:0:4} == '#---' ]] ; then
			if [[ $inComment ]] ; then
				echo "$commentBlock"
				return 0
			else
				inComment=yes
			fi
		elif [[ ${LINE:0:2} != '##' ]] && [[ $inComment ]] ; then
				[[ $QUIET -lt 1 ]] && echo "Line $srcLine of $FILE isn't a doc comment! Ignoring." >&2
		elif [[ $inComment ]] ; then
			commentBlock="$commentBlock"$'\n'${LINE####}
		fi
	done

	#If we make it out here, we hit the end of the file
	if [[ $commentBlock ]] ; then
		#If there is a comment block started, then it never ended
		[[ $QUIET -lt 2 ]] && echo "Unfinished comment block:"
		[[ $QUIET -lt 2 ]] && echo "$commentBlock"
		return 1
	else
		return 2
	fi
}


#-----------------------
##	Parses the comments from stdin. Also reads the (non-commented)
##	function name. Mostly uses <@function parse_block> and
##	<@function output_parsed_block> to do the read work.
##	@Stdin	Reads line after comment block
##	@Globals	paramDesc, retDesc, desc, block, split
#-----------------------
function parse_comments()
{

	#We use a lot of $( echo ... ) in here to trim the blanks

	local funcLine funcName
	paramDesc=()
	retDesc=()
	local FIRST_BLOCK="yes"
	local skipRead
	local outBlock=""
	local lastOutBlock=""
	# 1 = function
	# 2 = variable
	itemtype=0
	while true ; do
		paramNames=()
		paramDesc=()
		split=()
		retDesc=()
		desc=""
		itemtype=0
		block=$( get_comment_block )
		[[ $? -gt 0 ]] && break

		if [[ $skipRead ]] ; then
			skipRead=""
		else
			funcLine=""
			funcName=""
			read funcLine
		fi
		# Is it a function?
		if [[ ${funcLine%%[[:blank:]]*} == function ]] || [[ ${funcLine} =~ \(\)\ \{$ ]]; then
			funcName=$( echo ${funcLine#function} )
			funcName=$( echo ${funcName%%()*} )
			itemtype=1
		# Is it a (global) variable?
		elif [[ ${funcLine} =~ ^(declare -r +)?([^ ]+)=.+$ ]]; then
			varName="${BASH_REMATCH[@]: -1}"
			itemtype=2
		fi
		if [[ $funcName ]] || [[ $varName ]] || [[ $FIRST_BLOCK ]] ; then
			# Only bother with this block if it is a function block or
			#  the first script block

			#This fills in paramDesc[*], tag_*, retDesc
			parse_block
			lastOutBlock="$outBlock"
			outBlock=$(output_parsed_block)

			if [[ $FIRST_BLOCK ]] && [[ ! $funcName ]] && [[ ! $varName ]]; then
				FIRST_BLOCK=""
			fi

			if [[ $itemtype = 2 ]]; then
				funcName="$varName"
			fi
			if [[ $EXCLUSIVE ]] ; then
				# If this is first block, include it anyway.
				if [[ $funcName ]] || [[ $varName ]]; then
					local i="tag_${EXCLUSIVE}"
					if [[ ${!i} != $EXCLUSIVE_VAL ]] ; then
						echo "$funcName block ignored, no $EXCLUSIVE=$EXCLUSIVE_VAL tag." >&2
						# Code duplication but hard to avoid
						for i in ${!tag_*} ; do
							unset $i
						done
						continue
					fi
				fi
			fi

			for i in ${!tag_*} ; do
				unset $i
			done

			FUNC_LIST="$FUNC_LIST $funcName"
			VAR_LIST="$VAR_LIST $varName"
			unset funcName varName
			echo "$outBlock"

		else
			[[ $QUIET -lt 2 ]] && echo "Ignoring non-first non-function/variable comment block" >&2
			[[ $QUIET -lt 1 ]] && echo "$block" >&2
		fi
	done
}

#---------------------
##	Outputs the parsed information in a nice pretty format.
##	@Stdout	formated documentation
##	@Globals	paramDesc, retDesc, desc, block, split
#---------------------
function output_parsed_block()
{
	echo "<hr />"
	if [[ $itemtype -eq 1 ]] && [[ $funcName ]]; then
		echo "<!-- Block for $funcName -->"
		echo "	<h2 id=\"$funcName\" class=\"function\">function <strong>$funcName</strong>()</h2>"
		echo "	<h3>Parameters:</h3>"
		echo "	<ul class=\"paramerters\">"
		if [[ ${#paramDesc[*]} -gt 0 ]] ; then
			for(( i=0; i<"${#paramDesc[@]}"; i++ )) ; do
				echo "		<li class=\"paramerters\">\$$[i+1]: ${paramDesc[i]}</li>"
			done
		else
			echo "<li>None</li>"
		fi
		echo "	</ul>"
		if [[ ${#retDesc[*]} -gt 0 ]] ; then
			echo "	<h3>Returns:</h3>"
			echo "	<ul class=\"returns\">"
			for(( i=0; i<"${#retDesc[@]}"; i++ )) ; do
				echo "		<li class=\"returns\">${retDesc[i]}</li>"
			done
			echo "	</ul>"
		fi

		for i in ${!tag_*} ; do
			# Convert _ in tags to space. Looks better.
			echo "	<h3 class=\"othertag funcothertag ${i/tag_/tag-}\">$(sed 's/_/ /g' <<< "${i#tag_}")</h3>"
			# This may be fun, allow special formatting by tag.
			echo "	<p class=\"othertag funcothertag ${i/tag_/tag-}\">"
			echo "	${!i}"
			echo "	</p>"
			unset $i
		done
		[[ $desc ]] && echo "<h3>Description</h3><p class=\"description funcdescription\">$desc</p>"
	elif [[ $itemtype -eq 2 ]]; then
		echo "<!-- Block for $varName -->"
		echo "	<h2 id=\"$varName\" class=\"variable\">variable <strong>$varName</strong></h2>"
		for i in ${!tag_*} ; do
			# Convert _ in tags to space. Looks better.
			echo "	<h3 class=\"othertag varothertag ${i/tag_/tag-}\">$(sed 's/_/ /g' <<< "${i#tag_}")</h3>"
			# This may be fun, allow special formatting by tag.
			echo "	<p class=\"othertag varothertag ${i/tag_/tag-}\">"
			echo "	${!i}"
			echo "	</p>"
			unset $i
		done
		[[ $desc ]] && echo "<h3>Description</h3><p class=\"description vardescription\">$desc</p>"
	else
		echo '<!-- Header for whole script -->'
		echo "<h1>$FILE</h1>"
		echo "	<p class=\"filedescription\">$desc</p>"
		echo "$desc" >> $SCRIPT_DESC

		for i in ${!tag_*} ; do
			echo "	<h3 class=\"fileothertag ${i/tag_/tag-}\">${i#tag_}</h3>"
			echo "	<p class=\"fileothertag ${i/tag_/tag-}\">${!i}</p>"
			unset $i
		done
	fi

}

#---------------
##	Does the real work of the parsing. Tags start with @. Special
##	tags are @return and @param. Doc lines without a tag are
##	considered description.
##	@Globals	paramDesc, retDesc, desc, block, split
#---------------
function parse_block()
{
	local tag
	local backIFS="$IFS"
	IFS=$'\n'
	for LINE in $block; do
		IFS="$backIFS"
		LINE=$( echo $LINE )
		if [[ ${LINE:0:1} == '@' ]] ; then
			split_tag split $LINE
			case ${split} in
				@param)
					#paramNames[${#paramNames[*]}]=${split[1]}
					paramDesc=( "${paramDesc[@]}" "${split[1]}" )
					;;
				@return)
					retDesc=( "${retDesc[@]}" "${split[1]}" )
					;;
				@*)
					tag=${split[0]#@}
					local value="$(sed 's/\\/\\\\/g;s/\$/\\$/;s/"/\\"/g' <<< "${split[1]}")"
					local i="tag_${tag}"
					if [[ ${!i} ]] ; then
						local varname="tag_${tag}"
						eval "tag_${tag}=\"\${!varname}"$'\n'"${value}\""
					else
						eval "tag_${tag}=\"${value}\""
					fi
					;;
				*)
					echo "We shouldn't get here... it was a tag, but not a tag?" >&2
					;;
			esac
		else
			desc="$desc"$'\n'"$LINE"
		fi
	done
	IFS="$backIFS"
}

#----------------
##	Splits a line that starts with a tag into tag and data.
##	@param	Variable you want the result put into. Array is format is ( tag, data ).
##	@param	Tag
##	@param	Data
##	@Globals	The variable in $1 will get the results
#----------------
function split_tag()
{
	local out="${1}"			;	shift
	local tag=$( echo ${1} )	;	shift
#	local key=$( echo ${1} )	;	shift
	local value=$( echo $* | sed 's/\\/\\\\/g;s/\$/\\$/;s/"/\\"/g' )
	eval "$out=( \"$tag\" \"${value}\" )"
}

#--------------------
##	Outputs a header for script pages
##	@Stdout	html header
##	@param	Script name
#--------------------
function script_header()
{
cat <<- EOF > $OUT_FILE
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		$HEADERS
		<title>$1 - $PROJECT</title>
	</head>
	<body>
		<p class="right">
			<a href="script_list.html">Script Index</a>
		</p>
EOF
}

# Initialise project variables
OUT_DIR=$( dirname $0 )
args "$@"
shift $?
[[ $OUT_DIR ]] || OUT_DIR="."

# Create output directory in case it doesn't exist
mkdir -p "$OUT_DIR" || {
	echo "ERROR: Failed to create output directory."
	exit 1
}
# Copy stylesheet to output directory.
cat <<- EOF >> "${OUT_DIR}/style.css"
/* Based on Trac CSS */
body {
 background: #fff;
 color: #000;
 margin: 10px;
 padding: 0;
}
body, th, td {
 font: normal 13px verdana,arial,'Bitstream Vera Sans',helvetica,sans-serif;
}
h1, h2, h3, h4 {
 font-family: arial,verdana,'Bitstream Vera Sans',helvetica,sans-serif;
 font-weight: bold;
 letter-spacing: -0.018em;
}
h1 { font-size: 19px; margin: .15em 1em 0 0 }
h2 { font-size: 16px; font-weight: normal; }
h3 { font-size: 14px }
hr { border: none;  border-top: 1px solid #ccb; margin: 2em 0 }
address { font-style: normal }
img { border: none }
tt { white-space: pre }
:link, :visited {
 text-decoration: none;
 color: #b00;
 border-bottom: 1px dotted #bbb;
}
:link:hover, :visited:hover {
 background-color: #eee;
 color: #555;
}
h1 :link, h1 :visited ,h2 :link, h2 :visited, h3 :link, h3 :visited,
h4 :link, h4 :visited, h5 :link, h5 :visited, h6 :link, h6 :visited {
 color: inherit;
}

/* Partly own stuff: */
.nav body {
 margin: 0;
 padding: 0;
 background: inherit;
 color: inherit;
}
.nav ul { font-size: 11px; list-style: none; margin: 0; padding: 0; text-align: left }
.nav li {
 display: block;
 padding: 0;
 margin: 0;
 white-space: nowrap;
}

/* Own stuff */
.nav-header {
 font-weight: bold;
}
.right { text-align: right }
.tag-Deprecated { color: #e00; }
EOF

while [[ $# -gt 0 ]] ; do

	echo "Parsing $FILE" >&2
	#Initialise vars for this src
	FILE=$1
	shift
	OUT_FILE=${FILE#/}									#Remove leading /
	OUT_FILE="$OUT_DIR/${OUT_FILE//\//.}.html"
	FUNC_FILE="${OUT_FILE%.html}.funcs"
	VAR_FILE="${OUT_FILE%.html}.vars"
	SCRIPT_DESC="${OUT_FILE%.html}.desc"
	# Store real name (reuse in script list)
	REAL_NAME_FILE="${OUT_FILE%.html}.name"
	echo -n "${FILE#/}" > "$REAL_NAME_FILE"

	FUNC_LIST=""
	VAR_LIST=""

	#Start this src's html file
	script_header "$FILE"

	# Parse and write out function list
	{
		parse_comments < $FILE
		echo "$FUNC_LIST" > $FUNC_FILE
		echo "$VAR_LIST" > $VAR_FILE
	# Convert references like <@function file,functioname> into links
	} | sed -e 's!<@[[:blank:]]*function \([^,>]*\)[[:blank:]]*>!<a href="#\1">\1</a>!g' \
	        -e 's!<@[[:blank:]]*function \([^,>]*\),[[:blank:]]*\([^>]*\)[[:blank:]]*>!<a href="\1#\2">\1</a>!g' >> $OUT_FILE
	#Close off the html for this src
	cat <<- EOF >> $OUT_FILE
		</body>
	</html>
	EOF

done #Go on to next src

#Now for tying the scripts all together
pushd $OUT_DIR >/dev/null

# Start page that will have all the function calls
cat <<- EOF > function_list.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		$HEADERS
		<title>Functions of $PROJECT</title>
	</head>
	<body class="nav">
		<ul class="nav">
EOF

echo "<li class=\"nav nav-header\">Functions</li>" >> function_list.html
# Merge function lists of all sources, sort by function name
for i in *.funcs ; do
	for f in $( cat $i ) ; do
		echo "$f <li class=\"nav nav-function\"><tt>[f]</tt> <a href=\"${i%.funcs}.html#$f\" target=\"main\">$f</a></li>"
	done
done | sort | cut -d' ' -f2- >> function_list.html

echo "<li class=\"nav nav-header\">Variables</li>" >> function_list.html
for i in *.vars ; do
	for v in $( cat $i ) ; do
		echo "$v <li class=\"nav nav-variable\"><tt>[v]</tt> <a href=\"${i%.vars}.html#$v\" target=\"main\">$v</a></li>"
	done
done | sort | cut -d' ' -f2- >> function_list.html

# Close off the html for the global function list
cat <<-	EOF >> function_list.html
		</ul>
	</body>
</html>
EOF

# Start the list of scripts
TITLE="Scripts"
[[ $PROJECT ]] && TITLE="$PROJECT Script Documentation"
cat <<- EOF > script_list.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		$HEADERS
		<title>Scripts of $PROJECT</title>
	</head>
	<body>
		<h1>$TITLE</h1>
		<hr />
		<dl>
EOF

# List all the sources + descriptions, sort by script dir/name
for i in *.name ; do
	name=${i%.name}
	echo "${name} $(cat "$i")"
done | sort | while read LINE realname; do
	echo "<dt><a href=\"${LINE}.html\">$realname</a></dt>"
	echo "<dd>"
	cat ${LINE}.desc 2>/dev/null || { [[ $QUIET -lt 2 ]] && echo "$LINE has no description." >&2; }
	echo "</dd>"
done >> script_list.html

# Close off the html for the global script list
cat <<-	EOF >> script_list.html
		</dl>
	</body>
</html>
EOF

# Create the index file for the whole shbang
cat <<- EOF > index.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		$HEADERS
		<title>BashDoc - $PROJECT</title>
	</head>
	<frameset cols="25%,*">
		<frame src="function_list.html" name="function_list" />
		<frame src="script_list.html" name="main" />
	</frameset>
</html>
EOF

# Remove the temporary .desc and .name files, leave the .func and .vars files, someone may want them later.
rm *.desc
rm *.name
popd >/dev/null

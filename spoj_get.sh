#!/bin/bash
# exit on error

c_reset="$(tput sgr0)"
crf_red=$(tput setaf 1)
crf_green=$(tput setaf 2)
crf_orange=$(tput setaf 3)

set -e

read -p "User: " _USER
read -s -p "Password: " _PASS

_COOKIES="cookies.txt"

###
_WGET="wget -q"
_WGET_WITH_COOKIES="${_WGET} --load-cookies=${_COOKIES} --keep-session-cookies"
## SPOJ pages
_SPOJ_MAIN=http://pl.spoj.com/
_SPOJ_LIST=http://pl.spoj.com/status/${_USER}/signedlist/

###
# $1=ID, $2=TARGET_FILE
###
function get_sources
{
  URL=http://pl.spoj.com/files/src/save/$1
  if [ -f $2 ]; then
    echo "File $2 exists. ${crf_orange}Skipping.$c_reset"
  else
    echo -n "Downloading to ${2}..."
    ${_WGET_WITH_COOKIES} -p ${URL} -O $2 > /dev/null
    if [ -f $2 ]; then
      echo "${crf_green}OK$c_reset"
    else
      echo "${cfr_red}FAILED!$c_reset"
      exit 1;
    fi
  fi
}

function resolve_extension
{
  case $1 in
    "C++") EXT="cpp" ;;
    "C") EXT="c" ;;
    "ADA") EXT="ada";;
    "BF") EXT="bf";;

    *) EXT=$1
  esac

  echo $EXT
}

echo "Getting cookies"
rm -f ${_COOKIES} 2> /dev/null
${_WGET} --save-cookies=${_COOKIES} --post-data="login_user=${_USER}&password=${_PASS}" --keep-session-cookies -O index.html ${_SPOJ_MAIN} > /dev/null

echo "Getting myaccount page"
rm -f myaccount.html 2> /dev/null
${_WGET_WITH_COOKIES} -p ${_SPOJ_LIST} -O list.txt > /dev/null

COUNT=0

awk -F'|' 'BEGIN{p = 0}{if(/\|---------\|---------------------\|-----------\|-----------\|-------\|--------\|-----\|/) {p = 1; next}; if(/\------------------------------------------------------------------------------\//){p = 0}; if(p){print $2 $4 $8}; }' list.txt | \
sed 's/ \+/ /g' | \
while read line; do
  set $line

  EXT=$(resolve_extension $3)
  echo -n "${COUNT}) ID: $1 DIR: $2 EXT: $3 ($EXT)    | "
  mkdir -p "$2"
  OUT_FILE=$2/$1.$EXT
  get_sources $1 ${OUT_FILE}

  COUNT=$(($COUNT+1))
done

echo "Done"

rm -f ${_COOKIES} index.html 2> /dev/null


#!/bin/bash

NODE=node22
PORT=22

function print_help { echo "For usage hints, check the following webpage: https://c3s.unito.it/index.php/super-computer/occam-reference" >&2 ; } 

if [ $# -lt 1 ]; then
	print_help; exit 2;
fi

VOLUMES=""
while getopts "n:p:v:c:s:ixdwh" flag;
do
    case $flag in
        n) NODE=$OPTARG;;
        p) PORT=$OPTARG;;
        s) SSIZE="__SSIZE $OPTARG";;
        i) INTERACTIVE="__INTERACTIVE";;
        x) XFORWARD="__XFORWARD";;
        d) ;; # ignored, only for backward compatibility
        w) QEMU="__QEMU";;
        v) VOLUMES="$VOLUMES __VOLUME $OPTARG";;
	?) print_help; exit 2;;
    esac
done 
shift $((OPTIND-1))

# Registry url cleanUp if needed
IMAGE=`echo $1 | sed s#https://gitlab.c3s.unito.it:5000/##`
shift

PARAMS=""
for var in "$@"; do
	PARAM=`echo $var| /usr/bin/openssl enc -a -A`
	PARAMS="$PARAMS $PARAM"
done

X=""
if [ "AA$XFORWARD" = "AA__XFORWARD" ]; then
	X="-X"
fi
T=""
if [ "AA$INTERACTIVE" = "AA__INTERACTIVE" ]; then
	T="-t"
fi

# RUN AGAINST NODE
ID=$(mktemp $PWD/idfile.XXXXXXXXXX)
ssh $T $X $USER@$NODE -p $PORT $SSIZE $XFORWARD $INTERACTIVE $QEMU __IDFILE $ID $PWD $VOLUMES $IMAGE $PARAMS 
# Wait for the pid saved to file
if [ $? -eq 0 ]; then
	if [ "AA#IDFILE" != "AA" ] && [ "AA$INTERACTIVE" = "AA" ]; then
        	while [ ! -f $ID ]; do
			#echo "waiting for $ID"
                	sleep 1
        	done
	fi
	echo "Waiting for $(cat $ID)"
	occam-wait $(cat $ID)
	mkdir -p logfiles
	mv *$(cat ${ID}).done *$(cat ${ID}).err *$(cat ${ID}).log logfiles
	rm $ID
	exit 0
fi


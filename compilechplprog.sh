#!/bin/bash

## Testing
#echo '$1 = ' $1
#echo '$2 = ' $2
#echo '$3 = ' $3

## Instructions
#echo "Note: You need to run this with args"
#echo "      <filename> <n> <m> <iterEnum> <dstRecordType>"
#echo ""


NVAR=$2
MVAR=$3


docker run --rm -v "$PWD":$PWD -w $PWD chapel/chapel chpl --static --fast --inline-iterators --inline-iterators-yield-limit=128 $1 --set N=$NVAR --set M=$MVAR --set iterChoice=$4 --set recChoice=$5 -o syr2kchpl


echo ""
echo "============"
echo "If there were no errors, we compiled the executable syr2kchpl"
echo "============"





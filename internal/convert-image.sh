#! /bin/bash

arg=${1:?need a pathname}
dir=${arg%/*}               # chop off everything from the last slash forward
fname_ext=${arg##*/}        # keep only what’s after the last slash
name=${fname_ext%%.*}       # drop the longest .extension

cwebp -af -mt $1 -o ${name}.webp
avifenc --speed 0 $1 ${name}.avif

sync

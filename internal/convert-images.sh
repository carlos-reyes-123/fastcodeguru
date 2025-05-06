#! /bin/bash

shopt -s nullglob nocaseglob
png_files=(*.png)
jpg_files=(*.jpg)

if (( ${#png_files[@]} )); then
    for i in *.png; do
	arg=${i:?need a pathname}
	dir=${arg%/*}               # chop off everything from the last slash forward
	fname_ext=${arg##*/}        # keep only what’s after the last slash
	name=${fname_ext%%.*}       # drop the longest .extension
	cwebp -af -mt $i -o ${name}.webp
    done

    for i in *.png; do
	arg=${i:?need a pathname}
	dir=${arg%/*}               # chop off everything from the last slash forward
	fname_ext=${arg##*/}        # keep only what’s after the last slash
	name=${fname_ext%%.*}       # drop the longest .extension
	avifenc --speed 0 $i ${name}.avif
    done
fi

if (( ${#jpg_files[@]} )); then
    for i in *.jpg; do
	arg=${i:?need a pathname}
	dir=${arg%/*}               # chop off everything from the last slash forward
	fname_ext=${arg##*/}        # keep only what’s after the last slash
	name=${fname_ext%%.*}       # drop the longest .extension
	cwebp -af -mt $i -o ${name}.webp
    done

    for i in *.jpg; do
	arg=${i:?need a pathname}
	dir=${arg%/*}               # chop off everything from the last slash forward
	fname_ext=${arg##*/}        # keep only what’s after the last slash
	name=${fname_ext%%.*}       # drop the longest .extension
	avifenc --speed 0 $i ${name}.avif
    done
fi

sync

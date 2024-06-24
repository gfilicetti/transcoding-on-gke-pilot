#!/bin/bash

usage() {
    echo "Usage: ${0} -i <input_file> -o <output_file> [-p <ffmpeg_parameters>]" 1>&2; exit 1
}

while getopts "i:o:p:" OPT; do
  case "${OPT}" in
    i) INPUT="${OPTARG}";;
    o) OUTPUT="${OPTARG}";;
    p) FFPARAMS="${OPTARG}";;
    *) usage;;
  esac
done

if [ -z "${INPUT}" ] || [ -z "${OUTPUT}" ]; then
    usage
fi

if [ ! -f "${INPUT}" ]; then
    echo "Input file '$INPUT' not found."
fi

if [ -z "${FFPARAMS}" ]; then
    FFPARAMS="-c:v libx264 -b:v 20M -vf scale=1280:720 -threads 0 -x264-params threads=auto"
fi


#TODO: parameterize this as one big thing
#FFPARAMS="-c:v libx264 -b:v 20M -vf scale=1280:720 -threads 0 -x264-params threads=auto"

ffmpeg -y -benchmark -hide_banner \
    -i "${INPUT}" \
    "${FFPARAMS}" \
    "${OUTPUT}" \ 
    2>&1 | grep 'bench: u' | awk '{print $4}' | cut -d= -f2
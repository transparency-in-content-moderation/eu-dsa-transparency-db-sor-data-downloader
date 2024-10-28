#!/bin/bash

function help() {
    cat >&2 <<EOF
$0 <target-directory> [<start-date> [<num-days>]]

Download EU DSA Transparency DB SoR daily submission archives

  <target-directory>  directory where to download the data
  <start-date>        archive date to start downloads from
                      data format: YYYY-mm-dd, e.g. 2024-09-30
                      (default: two days ago)
  <num-days>          number of days / archives to download
                      (default: 1)
EOF
}

while getopts "h?" opt; do
    case $opt in
        h | "?" )
            help
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

TARGET_DIRECTORY="$1"; shift || { help; exit 1; }
START="$1"
DAYS="${2:-1}"

BASE_URL="https://dsa-sor-data-dumps.s3.eu-central-1.amazonaws.com/"

MAX_RANDOM_WAIT=157


function LOG__() {
    echo $(date '+[%Y-%m-%d %H:%M:%S]') "$@"
}


LOG__ "Downloading EU DSA Transparency DB SoR daily archives..."
LOG__ "start = $START, days = $DAYS, target directory = $TARGET_DIRECTORY"

if [ -z "$START" ]; then
    # default: fetch data from two days ago, because yesterday's data may not be ready yet
    START=$(date --date="yesterday yesterday" '+%Y-%m-%d')
fi

DATE=$START
for i in $(seq 1 $DAYS); do

    if [ $i -gt 1 ]; then
        SLEEP=$(($RANDOM%$MAX_RANDOM_WAIT))
        LOG__ "Waiting $SLEEP seconds before downloading $DATE"
        sleep $SLEEP
    fi

    TARGET_LOC="$TARGET_DIRECTORY/year=$(date --date="$DATE" '+%Y')/month=$(date --date="$DATE" '+%m')/day=$(date --date="$DATE" '+%d')"
    LOG__ "Downloading $DATE to $TARGET_LOC"
    mkdir -p "$TARGET_LOC"

    cd "$TARGET_LOC"/
    wget --no-verbose --timestamping "$BASE_URL"sor-global-$DATE-full.zip
    wget --no-verbose --timestamping "$BASE_URL"sor-global-$DATE-full.zip.sha1
    sha1sum --check sor-global-$DATE-full.zip.sha1
    cd -

    DATE=$(date --date="$DATE next day" '+%Y-%m-%d')
done


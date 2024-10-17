#!/bin/bash

DUCKDB_SETTINGS="set threads = 1; set max_memory = '14GB';"

function help() {
    cat >&2 <<EOF
$0 <sor-archive>...

Convert the EU DSA Transparency DB SoR daily archives to Parquet

  <sor-archive>  one zipped SoR archive
                 with the name pattern: sor-global-YYYY-mm-dd-full.zip

Options:
  -D             delete source zip file after conversion
  -O             force overwrite existing Parquet files

EOF
}

OVERWRITE=false
CLEANUP_ZIP=false
while getopts "h?OD" opt; do
    case $opt in
        h | "?" )
            help
            exit 0
            ;;
        O )
            OVERWRITE=true
            ;;     
        D )
            CLEANUP_ZIP=true
            ;;     
    esac
done
shift $((OPTIND-1))

function LOG__() {
    echo $(date '+[%Y-%m-%d %H:%M:%S]') "$@"
}

BINDIR=$(readlink -f "$(dirname $0)")
ZIP2GZ=$BINDIR/../../zip2gz/zip2gz.py
if ! [ -e "$ZIP2GZ" ]; then
    ZIP2GZ=""
else
    LOG__ "Using $ZIP2GZ to efficiently uncompress zip files"
fi

set -e

for zip in "$@"; do

    name="$(basename $zip .zip)"

    if [ -e $(dirname $zip)/$name.parquet.zst ]; then
        if $OVERWRITE; then
            LOG__ "Parquet file $(dirname $zip)/$name.parquet.zst already exists, overwriting..."
        else
            LOG__ "Parquet file $(dirname $zip)/$name.parquet.zst already exists, skipping conversion"
            continue
        fi
    fi

    LOG__ "Processing $zip"
    mkdir -p "$name"
    unzip -d "$name" "$zip"
    cd "$name"
    for z in *.zip; do
        if [ -n "$ZIP2GZ" ]; then
            python3 "$ZIP2GZ" "$z"
        else
            unzip "$z"
            gzip *.csv
        fi
    done
    rm *.zip
    cd ..

    LOG__ "Converting CSV to Parquet: $name"
    if (echo "$DUCKDB_SETTINGS"; sed "s@__NAME__@$name@g" $BINDIR/../sql/convert_csv_parquet.sql) | duckdb; then
        : # ok, conversion succeeded
    else
        # conversion failed, try with "ignore_errors"
        LOG__ "Retrying failed conversion CSV to Parquet (ignore_errors = true): $name"
        (echo "$DUCKDB_SETTINGS"; sed "s@__NAME__@$name@g; s@--\\s*ignore_errors@ignore_errors@" $BINDIR/../sql/convert_csv_parquet.sql) | duckdb
    fi
    LOG__ "Parquet conversion finished: $name.parquet.zst"
    mv -v "$name/$name.parquet.zst" $(dirname $zip)/
    rm -r "$name/"

    if $CLEANUP_ZIP; then
        LOG__ "Removing source ZIP: $zip"
        rm "$zip"
    fi
done
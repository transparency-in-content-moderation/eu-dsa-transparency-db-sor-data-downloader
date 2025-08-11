#!/bin/bash

DUCKDB_SETTINGS="set threads = 1; set max_memory = '14GB';"

function help() {
    cat >&2 <<EOF
$0 [<options>] <sor-archive>...

Convert the EU DSA Transparency DB SoR daily archives to Parquet

  <sor-archive>  one zipped SoR archive
                 with the name pattern: sor-global-YYYY-mm-dd-full.zip

Options:
  -D             delete source zip file after conversion
  -O             force overwrite existing Parquet files
  -T <tempdir>   temporary directory used for conversion

EOF
}

OVERWRITE=false
CLEANUP_ZIP=false
TMP_DIR=.
while getopts "h?ODT:" opt; do
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
        T )
            TMP_DIR="$OPTARG"
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
    dt_day="${name#sor-global-}"
    dt_day="${dt_day%-full}"

    if [ -e $(dirname $zip)/$name.zstd.parquet ]; then
        if $OVERWRITE; then
            LOG__ "Parquet file $(dirname $zip)/$name.zstd.parquet already exists, overwriting..."
        else
            LOG__ "Parquet file $(dirname $zip)/$name.zstd.parquet already exists, skipping conversion"
            continue
        fi
    fi

    LOG__ "Processing $zip"
    mkdir -p "$TMP_DIR"/"$name"
    unzip -d "$TMP_DIR"/"$name" "$zip"
    cd "$TMP_DIR"/"$name"
    for z in *.zip; do
        if [ -n "$ZIP2GZ" ]; then
            python3 "$ZIP2GZ" "$z"
        else
            unzip "$z"
            gzip *.csv
        fi
        rm "$z"
    done

    FILTER=cat
    if [[ "$dt_day" < "2025-07-01" ]]; then
        FILTER='grep -v -e 2025-07-01'
    fi

    LOG__ "Converting CSV to Parquet: $name"
    if (echo "$DUCKDB_SETTINGS"; sed "s@__NAME__@$name@g" $BINDIR/../sql/convert_csv_parquet.sql | $FILTER) | duckdb; then
        : # ok, conversion succeeded
    else
        # conversion failed, try with "ignore_errors"
        LOG__ "Retrying failed conversion CSV to Parquet (ignore_errors = true): $name"
        (echo "$DUCKDB_SETTINGS"; sed "s@__NAME__@$name@g; s@--\\s*ignore_errors@ignore_errors@" $BINDIR/../sql/convert_csv_parquet.sql) | duckdb
    fi
    LOG__ "Parquet conversion finished: $name.zstd.parquet"

    cd -
    LOG__ "Moving Parquet file to final location:" $(dirname $zip)/
    mv -v "$TMP_DIR"/"$name"/"$name.zstd.parquet" $(dirname $zip)/
    rm -r "$TMP_DIR"/"$name"/

    if $CLEANUP_ZIP; then
        LOG__ "Removing source ZIP: $zip"
        rm "$zip"
    fi
done

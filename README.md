
# European Union DSA Transparency Database Statement of Reasons Data Downloader

Download the EU DSA Transparency DB SoR daily submission ZIP archives
and recompress the data to [Apache Parquet](https://parquet.apache.org/)
for efficient storage and querying.

References:
- https://transparency.dsa.ec.europa.eu/
- https://github.com/digital-services-act/transparency-database


## Requirements

- software
  - Linux, bash, sed, wget, unzip
  - [DuckDB](https://duckdb.org/)
  - (optional, included as Git submodule) [patrikaxelsson/zip2gz](https://github.com/patrikaxelsson/zip2gz)
- hardware
  - 16 GiB RAM
  - 1-2 CPU
  - disk storage
    - 20 GiB to hold temporary data
    - 200 MiB for daily data stored as Parquet
    - 2-5 GiB for daily data CSV archives (if not removed after conversion)


## Download Data

### Initial Download

Run the script [sor-download.sh](src/script/sor-download.sh), e.g.,

```sh
./src/script/sor-download.sh data/eu-dsa/sor-global 2023-09-25 7
```

For more details and options, please run `sor-download.sh -h`.


### Nightly Downloads

Without start date the script [sor-download.sh](src/script/sor-download.sh) downloads
the archive from two days ago. You might want to set up a cronjob for nightly downloads.
For example, the following line in the crontab file downloads the latest (two days ago)
SoR archive:

```crontab
46 4 * * * bash -c 'cd eu-dsa-transparency-db-sor-data-downloader; ./src/script/sor-download.sh data/eu-dsa/sor-global/ &>logs/sor-download-$(date +\%Y-\%m-\%d).log'
```


## Unzip and Convert to Parquet

Run the script [sor-convert.sh](src/script/sor-convert.sh) passing the
CSV files you want to convert as arguments. The Parquet file is placed
in the same folder than the corresponding CSV file.

```sh
./src/script/sor-convert.sh data/eu-dsa/sor-global/year\=2023/month\=09/day\=25/sor-global-2023-09-25-full.zip
```

For more details and options, please run `sor-convert.sh -h`.
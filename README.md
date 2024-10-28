
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
    - 20 GiB to hold temporary data (for some daily archives more is needed, up to 80 GiB)
    - 200 MiB for daily data stored as Parquet
    - 2 GiB per daily zipped CSV archive, if not removed after conversion (few archives are larger, up to 35 GiB)


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
46 4 * * * bash -c 'cd eu-dsa-transparency-db-sor-data-downloader; DT=$(date --date="yesterday yesterday" "+\%Y-\%m-\%d"); ./src/script/sor-download.sh data/eu-dsa/sor-global/ $DT &>>logs/sor-download-$DT.log; ./src/script/sor-convert.sh -T tmp -D data/eu-dsa/sor-global/year=*/month=*/day=*/sor-global-$DT-full.zip &>>logs/sor-convert-$DT.log'
```


## Unzip and Convert to Parquet

Run the script [sor-convert.sh](src/script/sor-convert.sh) passing the
CSV files you want to convert as arguments. The Parquet file is placed
in the same folder than the corresponding CSV file.

```sh
./src/script/sor-convert.sh data/eu-dsa/sor-global/year\=2023/month\=09/day\=25/sor-global-2023-09-25-full.zip
```

For more details and options, please run `sor-convert.sh -h`.


## Results and Metrics of the Conversion

Results and metrics of the conversion are shown on a separate page, [metrics/conversion_results.md](./metrics/conversion_results.md). Note that there is a small, but in absolute numbers non-trivial difference, between the number of SoRs indicated on the download table and as counted on the converted data.
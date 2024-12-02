
# European Union DSA Transparency Database Statement of Reasons Data Downloader

Download the EU DSA Transparency DB SoR daily submission ZIP archives
and recompress the data to [Apache Parquet](https://parquet.apache.org/)
for efficient storage and querying.

References:
- <https://transparency.dsa.ec.europa.eu/>
- <https://github.com/digital-services-act/transparency-database>
- related:
  - <https://code.europa.eu/dsa/transparency-database/dsa-tdb>


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
    - 2 GiB per daily zipped CSV archive, if not removed after conversion (few archives are larger, up to 35 GiB)
    - 200 MiB for daily data stored as Parquet. By end of November 2024, 70 GiB storage are sufficient to hold data of all days since September 2023, in total 22 billion rows.


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

The conversion is defined in [convert_csv_parquet.sql](src/sql/convert_csv_parquet.sql). The main objectives:
- drop the `UUID` and `PUID` columns which contain unique values (too much entropy)
- use an appropriate data type for the columns (boolean, timestamp, JSON)
- use a large context window (row group size) which allows Parquet to store repeating values very efficiently
- utilize [Zstandard](https://facebook.github.io/zstd/) compression with the highest compression level
- do not resort or aggregate the data – the incoming data is sorted by the `created_at` timestamp. Because this timestamp has a high precision (seconds), keeping it sorted allows to compress this column well.

In order to save storage space and computation during conversion, compression streams are directly copied out of the zip files using [patrikaxelsson/zip2gz](https://github.com/patrikaxelsson/zip2gz). DuckDb can directly read the gzip-compressed CSV.


## Results and Metrics of the Conversion

Results and metrics of the conversion are shown on a separate page, [metrics/conversion_results.md](./metrics/conversion_results.md). Note that there is a small, but in relative numbers trivial difference, between the number of SoRs indicated on the download table and as counted on the converted data.


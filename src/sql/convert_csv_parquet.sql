copy (
   select *
   exclude('uuid', 'platform_uid')
   from read_csv(
          '__NAME__/*.csv.gz',
          header = True,
          delim = ',',
          quote = '"',
          escape = '"',
          new_line = '\n',
          -- ignore_errors = True,
          types = {
             'end_date_visibility_restriction': 'TIMESTAMP_MS',
             'end_date_monetary_restriction': 'TIMESTAMP_MS',
             'end_date_service_restriction': 'TIMESTAMP_MS',
             'end_date_account_restriction': 'TIMESTAMP_MS',
             'content_date': 'TIMESTAMP_MS',
             'automated_detection': 'BOOLEAN',
             'incompatible_content_illegal': 'BOOLEAN',
             'application_date': 'TIMESTAMP_MS',
             'created_at': 'TIMESTAMP_MS',
             'decision_visibility': 'JSON',
             'category_addition': 'JSON',
             'category_specification': 'JSON',
             'content_type': 'JSON',
             'territorial_scope': 'JSON'
             } )
  ) to '__NAME__/__NAME__.parquet.zst' (
          format 'parquet',
          codec 'zstd',
          compression_level 19,
          row_group_size 3145728 )
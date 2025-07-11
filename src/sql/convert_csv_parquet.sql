copy (
   select *
   exclude('uuid', 'platform_uid')
   from read_csv(
          '*.csv.gz',
          header = True,
          delim = ',',
          quote = '"',
          escape = '"',
          new_line = '\n',
          -- ignore_errors = True,
          auto_detect = False,
          columns = {
            'uuid':                             'VARCHAR',
            'decision_visibility':              'JSON',
            'decision_visibility_other':        'VARCHAR',
            'end_date_visibility_restriction':  'TIMESTAMP_MS',
            'decision_monetary':                'VARCHAR',
            'decision_monetary_other':          'VARCHAR',
            'end_date_monetary_restriction':    'TIMESTAMP_MS',
            'decision_provision':               'VARCHAR',
            'end_date_service_restriction':     'TIMESTAMP_MS',
            'decision_account':                 'VARCHAR',
            'end_date_account_restriction':     'TIMESTAMP_MS',
            'account_type':                     'VARCHAR',
            'decision_ground':                  'VARCHAR',
            'decision_ground_reference_url':    'VARCHAR',
            'illegal_content_legal_ground':     'VARCHAR',
            'illegal_content_explanation':      'VARCHAR',
            'incompatible_content_ground':      'VARCHAR',
            'incompatible_content_explanation': 'VARCHAR',
            'incompatible_content_illegal':     'BOOLEAN',
            'category':                         'VARCHAR',
            'category_addition':                'JSON',
            'category_specification':           'JSON',
            'category_specification_other':     'VARCHAR',
            'content_type':                     'JSON',
            'content_type_other':               'VARCHAR',
            'content_language':                 'VARCHAR',
            'content_date':                     'TIMESTAMP_MS',
            'content_id_ean':                   'JSON', -- added 2025-07-01
            'territorial_scope':                'JSON',
            'application_date':                 'TIMESTAMP_MS',
            'decision_facts':                   'VARCHAR',
            'source_type':                      'VARCHAR',
            'source_identity':                  'VARCHAR',
            'automated_detection':              'BOOLEAN',
            'automated_decision':               'VARCHAR',
            'platform_name':                    'VARCHAR',
            'platform_uid':                     'VARCHAR',
            'created_at':                       'TIMESTAMP_MS'
          } )
  ) to '__NAME__.zstd.parquet' (
          format 'parquet',
          codec 'zstd',
          compression_level 19,
          row_group_size 3145728 )

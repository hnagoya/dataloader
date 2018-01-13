use_salesforce_dataloader.rb
==========

Force.com Apex Data Loader for Ruby/Linux - command line version

# Requirements

1. Java 8+

2. DataLoader JAR file from Windows or built from the open source project. 
The current name/version of the jar file is `dataloader-41.0.0-uber.jar`, which included in this repo.

# Usage (example)

## Install

1. `$ gem install use_salesforce_dataloader`

2. Put the `dataloader-41.0.0-uber.jar` file to somewhere.

## Setup

Ruby code are:
```ruby
require 'use_salesforce_dataloader'

jar = '/opt/dataloader-41.0.0-uber.jar'              # Depends on your local environment.
dataloader = UseSalesforceDataLoader.new(jar)
dataloader.endpoint = 'https://login.salesforce.com' # Depends on your salesforce environment. 
dataloader.username = 'foo@example.com'              # Depends on your salesforce environment.
dataloader.password = '123456789'                    # Depends on your salesforce environment.
dataloader.conf_dir = '/tmp/hoge'                    # Depends on your local environment.
dataloader.save_conf_key_file                        # Create /tmp/hoge/key.txt
```

## Extract

Extract to `/tmp/hoge/extract_Account.csv`.

Ruby code are:
```ruby
dataloader.bean_id = 'p02'
dataloader.bean_description = 'Do p02 extract'
dataloader.property_name = 'p02'
dataloader.overwrite_entries = {
  'process.name' => 'p02',
  'sfdc.entity' => 'Account',
  'process.operation' => 'extract',
  'sfdc.extractionSOQL' => 'select Id, Name, AccountNumber from Account',
  'dataAccess.name' => 'extract_Account.csv',
  'dataAccess.type' => 'csvWrite',
  'process.mappingFile' => nil,
  'process.enableExtractStatusOutput' => 'false',
  'sfdc.debugMessages' => 'false',
}
dataloader.save_conf_process_xml_file # Create /tmp/hoge/process-conf.xml
system dataloader.process_cmd('p02')  # Run dataloader
```

## Insert

Insert records from `insert.csv`.

`$ cat insert.csv`
```text
name,account_number,location
James T. Kirk,ac-000,SPACE
Spock Vulcan,ac-001,SPACE
Dr. Leonard McCoy,ac-002,SPACE
Montgomery Scott,ac-003,SPACE
Nyota Uhura,ac-004,SPACE
Hikaru Sulu,ac-005,SPACE
```

`$ cat map.sdl`
```text
name=Name
account_number=AccountNumber
location=BillingState
```

Ruby code are:
```ruby
dataloader.bean_id = 'p03'
dataloader.bean_description = 'Do p03 insert'
dataloader.property_name = 'p03'
dataloader.overwrite_entries = {
  'process.name' => 'p03',
  'sfdc.entity' => 'Account',
  'process.operation' => 'insert',
  'dataAccess.name' => './insert.csv',
  'dataAccess.type' => 'csvRead',
  'process.outputSuccess' => './insert_result.csv',
  'sfdc.debugMessages' => 'true',
}
dataloader.save_conf_process_xml_file # Create /tmp/hoge/process-conf.xml
system dataloader.process_cmd('p03')  # Run dataloader
```

## Upsert

Upsert records from `upsert.csv`.

`$ cat upsert.csv`
```text
id,update_name
0018000000OTQcyAAH,James T. Kirk
0018000000OTQcuAAH,Spock Vulcan
0018000000OTQd0AAH,Dr. Leonard McCoy
0018000000OTQcwAAH,Montgomery Scott
0018000000OTQcvAAH,Nyota Uhura
0018000000OTQd5AAH,Hikaru Sulu
```

`$ cat map.sdl`
```text
id=Id
update_name=Name
```

Ruby code are:
```ruby
dataloader.bean_id = 'p04'
dataloader.bean_description = 'Do p04 upsert'
dataloader.property_name = 'p04'
dataloader.overwrite_entries = {
  'process.name' => 'p04',
  'sfdc.entity' => 'Account',
  'sfdc.externalIdField' => 'Id',
  'process.operation' => 'upsert',
  'dataAccess.name' => './upsert.csv',
  'dataAccess.type' => 'csvRead',
  'process.outputSuccess' => './upsert_result.csv',
  'sfdc.debugMessages' => 'false',
}
dataloader.save_conf_process_xml_file # Create /tmp/hoge/process-conf.xml
system dataloader.process_cmd('p04')  # Run dataloader
```

### Delete

Delete records from `delete.csv`.

`$ cat delete.csv`
```text
id
0018000000OTQcyAAH
0018000000OTQcuAAH
0018000000OTQd0AAH
0018000000OTQcwAAH
0018000000OTQcvAAH
0018000000OTQd5AAH
```

`$ cat map.sdl`
```text
id=Id
```

Ruby code are:
```ruby
dataloader.bean_id = 'p05'
dataloader.bean_description = 'Do p05 delete'
dataloader.property_name = 'p05'
dataloader.overwrite_entries = {
  'process.name' => 'p05',
  'sfdc.entity' => 'Account',
  'process.operation' => 'delete',
  'dataAccess.name' => './delete.csv',
  'dataAccess.type' => 'csvRead',
  'sfdc.debugMessages' => 'true',
}
dataloader.save_conf_process_xml_file # Create /tmp/hoge/process-conf.xml
system dataloader.process_cmd('p05')  # Run dataloader
```

# Links

This project forked from: https://github.com/sthiyaga/dataloader

The open source version of dataloader is available from: https://github.com/forcedotcom/dataloader

The "Data Loader Guide" is available from: https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/data_loader.htm

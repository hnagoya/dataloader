use_salesforce_dataloader.rb
==========

Force.com Apex Data Loader for Ruby/Linux - command line version

This project forked from: https://github.com/sthiyaga/dataloader

The open source version of dataloader is available from: https://github.com/forcedotcom/dataloader

The "Data Loader Guide" is available from: https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/data_loader.htm

## Requirements: 

1. Java 8+

2. DataLoader JAR file from Windows or built from the open source project. 
(The current name/version of the jar file is: `dataloader-41.0.0-uber.jar`)

## Steps: 

1. Clone this project 
  ```
  $ git clone https://github.com/hnagoya/use_salesforce_dataloader
  ```

2. Copy the `use_salesforce_dataloader.rb` to somewhere.

3. Copy the `dataloader-41.0.0-uber.jar` file to somewhere.

4. Use your ruby script
  ```
  require './use_salesforce_dataloader'
  ```

5. Usecase samples are `Rakefile` into `./test` directory.

-hnagoya

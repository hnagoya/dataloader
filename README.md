use_sfdc_dataloader.rb
==========

Force.com Apex Data Loader for Ruby/Linux - command line version

This project forked from: https://github.com/sthiyaga/dataloader

The open source version of dataloader is available from: https://github.com/forcedotcom/dataloader

## Requirements: 

1. Java 8+, available in the PATH

2. DataLoader JAR file from Windows or built from the open source project. 
(The current name/version of the jar file is: dataloader-41.0.0-uber.jar)

## Steps: 

1. Clone this project 
  ```
  $ git clone https://github.com/hnagoya/use_sfdc_dataloader
  ```
2. Copy the `use_sfdc_dataloader.rb` to somewhere.
2. Copy the dataloader-41.0.0-uber.jar file to somewhere.
3. Use your ruby script
  ```
  require './use_sfdc_dataloader'
  ```
4. Usecase samples are `Rakefile` into `./test` directory.

-hnagoya


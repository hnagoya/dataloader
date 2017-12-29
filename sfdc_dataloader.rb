# -*- coding: utf-8 -*-

class SFDCDataLoader

  # file layout:
  # conf_dir/key.txt
  # conf_dir/process-conf.xml
  # conf_dir/map.sdl
  attr_reader :conf_dir
  attr_accessor :conf_key_file 
  attr_accessor :conf_process_xml_file
  attr_accessor :conf_map_file
  def conf_dir=(path)
    @conf_dir = path
    @conf_key_file = @conf_dir + '/key.txt'
    @conf_process_xml_file = @conf_dir + '/process-conf.xml'
    @conf_map_file = @conf_dir + '/map.sdl'
  end

  # see https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/loader_params.htm
  attr_accessor :bean_id
  attr_accessor :bean_description
  attr_accessor :property_name
  attr_accessor :entries
  attr_accessor :overwrite_entries

  # authentication data
  attr_accessor :sfdc_endpoint # ex. test.salesforce.com
  attr_accessor :sfdc_username # ex. foo@example.com
  attr_accessor :sfdc_password # ex. 0123456789

  # java command line of java runtime, ex. "/usr/bin/java -Dfile.encoding=UTF-8"
  # jar  path of dataloader-NN.N.N-uber.jar, ex. "/usr/lib/dataloader-41.0.0-uber.jar"
  def initialize(java, jar)
    j = "#{java} -cp #{jar}"
    @encrypt = "#{j} com.salesforce.dataloader.security.EncryptionUtil"
    @process = "#{j} -Dsalesforce.config.dir=%s com.salesforce.dataloader.process.ProcessRunner process.name=%s"
  end

  # Original: dataloader/bin/encrypt.sh
  # Usage: dataloader/bin/encrypt.sh
  # Utility to encrypt a string based on a static or a provided key
  # Options (mutually exclusive - use one at a time):
  #   -g <seed text>                                 Generate key based on seed
  #   -v <encrypted> <decrypted value> [Path to Key] Validate whether decryption of encrypted value matches the decrypted value, optionally provide key file
  #   -e <plain text> [Path to Key]                  Encrypt a plain text value, optionally provide key file (generate key using option -g)
  #
  def encrypt(args)
    cmd = "#{@encrypt} #{args} | sed 's/^.*) \- //g'"
    `#{cmd}`.chomp
  end

  # Original: dataloader/bin/process.sh
  # Usage: dataloader/bin/process.sh [conf-dir] <process-name>
  #
  def process_cmd(name, dir = @conf_dir)
    @process % [dir, name]
  end

  # Save encrypt key file
  def save_conf_key_file
    @conf_key_file.tap do |f|
      open(f, 'w:UTF-8') do |o|
        text_seed = rand(0xffff_ffff).to_s(16)
        o.print encrypt("-g #{text_seed}")
      end
    end
  end

  # Save conf xml file
  def save_conf_process_xml_file
    @conf_process_xml_file.tap do |f|
      open(f, 'w:UTF-8') do |o|
        o.print conf_process_xml
      end
    end
  end

  # Generate XML config
  def conf_process_xml
    encrypt_password = encrypt("-e '#{@sfdc_password}' '#{@conf_key_file}'")
    es = {
      'sfdc.endpoint' => @sfdc_endpoint,
      'sfdc.username' => @sfdc_username,
      'sfdc.password' => encrypt_password,
      'process.encryptionKeyFile' => @conf_key_file,
      'process.lastRunOutputDirectory' => @conf_dir,
      'process.statusOutputDirectory' => @conf_dir,
      'process.mappingFile' => @conf_map_file,
    }
    @entries = DEFAULT_ENTRIES.merge!(es)
    @entries.merge!(@overwrite_entries) if @overwrite_entries
    entries_xml = @entries
      .select{|k, v| v}
      .map{|k, v| '        <entry key="%s" value="%s"/>' % [k, v]}
      .join("\n")
    PROCESS_XML_TEMPLATE % [@bean_id,
                            @bean_descrption,
                            @property_name,
                            entries_xml]
  end

  PROCESS_XML_TEMPLATE = <<'XML'
<!DOCTYPE beans PUBLIC "-//SPRING//DTD BEAN//EN" "http://www.springframework.org/dtd/spring-beans.dtd">
<beans>
  <bean id="%s"
        class="com.salesforce.dataloader.process.ProcessRunner"
        singleton="false">
    <description>%s</description>
    <property name="name" value="%s"/>
    <property name="configOverrideMap">
      <map>
%s
      </map>
    </property>
  </bean>
</beans>
XML

  # see https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/loader_params.htm
  DEFAULT_ENTRIES = {
    'dataAccess.readUTF8'               => 'true',
    'dataAccess.writeUTF8'              => 'true',
    'dataAccess.name'                   => nil,
    'dataAccess.readBatchSize'          => nil,
    'dataAccess.type'                   => nil,
    'dataAccess.writeBatchSize'         => nil,
    'process.enableExtractStatusOutput' => 'false',
    'process.enableLastRunOutput'       => 'true',
    'process.encryptionKeyFile'         => nil,
    'process.initialLastRunDate'        => nil,
    'process.lastRunOutputDirectory'    => nil,
    'process.loadRowToStartAt'          => nil,
    'process.mappingFile'               => nil,
    'process.operation'                 => nil,
    'process.statusOutputDirectory'     => nil,
    'process.outputError'               => nil,
    'process.outputSuccess'             => nil,
    'process.useEuropeanDates'          => nil,
    'sfdc.assignmentRule'               => nil,
    'sfdc.bulkApiCheckStatusInterval'   => nil,
    'sfdc.bulkApiSerialMode'            => 'false',
    'sfdc.bulkApiZipContent'            => nil,
    'sfdc.connectionTimeoutSecs'        => nil,
    'sfdc.debugMessages'                => nil,
    'sfdc.debugMessagesFile'            => nil,
    'sfdc.enableRetries'                => nil,
    'sfdc.endpoint'                     => nil,
    'sfdc.entity'                       => nil,
    'sfdc.externalIdField'              => nil,
    'sfdc.extractionRequestSize'        => nil,
    'sfdc.extractionSOQL'               => nil,
    'sfdc.insertNulls'                  => nil,
    'sfdc.loadBatchSize'                => nil,
    'sfdc.maxRetries'                   => nil,
    'sfdc.minRetrySleepSecs'            => nil,
    'sfdc.noCompression'                => nil,
    'sfdc.password'                     => nil,
    'sfdc.proxyHost'                    => nil,
    'sfdc.proxyPassword'                => nil,
    'sfdc.proxyPort'                    => nil,
    'sfdc.proxyUsername'                => nil,
    'sfdc.resetUrlOnLogin'              => nil,
    'sfdc.timeoutSecs'                  => nil,
    'sfdc.timezone'                     => nil,
    'sfdc.truncateFields'               => 'false',
    'sfdc.useBulkApi'                   => nil,
    'sfdc.username'                     => nil,
  }
end

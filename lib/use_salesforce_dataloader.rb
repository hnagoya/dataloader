# -*- coding: utf-8 -*-
require 'open3'

# see https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/loader_params.htm
class UseSalesforceDataLoader

  # File layout:
  # conf_dir/key.txt
  # conf_dir/process-conf.xml
  # conf_dir/map.sdl
  attr_accessor :conf_dir
  attr_accessor :conf_key_file
  attr_accessor :conf_process_xml_file
  attr_accessor :conf_map_file
  def conf_dir=(path)
    @conf_dir = path
    @conf_key_file = @conf_dir + '/key.txt'
    @conf_process_xml_file = @conf_dir + '/process-conf.xml'
    @conf_map_file = @conf_dir + '/map.sdl'
  end

  # process-conf.xml
  attr_accessor :bean_id
  attr_accessor :bean_description
  attr_accessor :property_name
  attr_accessor :overwrite_entries

  # Salesforce.com authentication data
  attr_accessor :endpoint # ex. https://test.salesforce.com
  attr_accessor :username # ex. foo@example.com
  attr_accessor :password # ex. 0123456789

  # jar:      path of dataloader-NN.N.N-uber.jar, ex. "/usr/lib/dataloader-41.0.0-uber.jar"
  # java:     command line of java runtime, ex. "/usr/bin/java"
  # java_opt: ex.  "-Dfile.encoding=UTF-8"
  def initialize(jar, java = nil, java_opt = nil)
    java = exec_command('which java') unless java
    path_check(java)
    path_check(jar)
    j = [java, java_opt, '-cp', jar].compact.join(' ')
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
    exec_command(cmd)
  end

  # Original: dataloader/bin/process.sh
  # Usage: dataloader/bin/process.sh [conf-dir] <process-name>
  #
  def process_cmd(name)
    path_check(@conf_dir)
    path_check(@conf_process_xml_file)
    @process % [@conf_dir, name]
  end

  # Save encrypt key file
  def save_conf_key_file
    @conf_key_file.tap do |f|
      open(f, 'w:UTF-8') do |o|
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
    entries = BASE_ENTRIES.merge(default_overwrite_entries)
    entries.merge!(@overwrite_entries) if @overwrite_entries
    entries_xml = entries
      .select{|k, v| v}
      .map{|k, v| ENTRIES_XML_TEMPLATE % [k, v]}
      .join("\n")
    PROCESS_XML_TEMPLATE % [@bean_id,
                            @bean_descrption,
                            @property_name,
                            entries_xml]
  end

  private

  # internal use
  def default_overwrite_entries
    path_check(@conf_key_file)
    encrypt_password = encrypt("-e '#{@password}' '#{@conf_key_file}'")
    {
      'sfdc.endpoint' => @endpoint,
      'sfdc.username' => @username,
      'sfdc.password' => encrypt_password,
      'process.encryptionKeyFile' => @conf_key_file,
      'process.lastRunOutputDirectory' => @conf_dir,
      'process.statusOutputDirectory' => @conf_dir,
      'process.mappingFile' => @conf_map_file,
    }
  end

  # interal use
  def text_seed
    rand(0xffff_ffff).to_s(16)
  end

  # internal use
  def path_check(f)
    raise "Path not found: #{f}" unless File.exist?(f)
  end

  # internal use
  def exec_command(cmd)
    o, e, s = Open3.capture3(cmd)
    raise "Something wrong" unless e.empty? and s.success?
    o.chomp
  end

  PROCESS_XML_TEMPLATE = <<'PROCESS_XML'
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
PROCESS_XML

  ENTRIES_XML_TEMPLATE = <<'ENTRIES_XML'
        <entry key="%s" value="%s"/>
ENTRIES_XML
          
  BASE_ENTRIES = {
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

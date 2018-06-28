# -*- coding: utf-8 -*-
require 'open3'

# @see https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/loader_params.htm
# Standard file layout (allow different layout):
# - <tt>conf_dir/</tt>
#   - <tt>key.txt</tt>
#   - <tt>process-conf.xml</tt>
#   - <tt>map.sdl</tt>
#
class UseSalesforceDataLoader
  VERSION = '0.0.8'

  # Setter for <tt>@conf_dir</tt>, set values <tt>@conf_key_file</tt>, <tt>@conf_process_xml_file</tt> and <tt>@conf_map_file</tt> at the same time.
  def conf_dir=(path)
    @conf_dir = path
    @conf_key_file = @conf_dir + '/key.txt'
    @conf_map_file = @conf_dir + '/map.sdl'
    @conf_process_xml_file = @conf_dir + '/process-conf.xml'
    @conf_dir
  end

  # @return [String] path of conf_dir
  # @see #conf_dir=
  def conf_dir
    @conf_dir
  end

  # @return [String] path of conf_key_file.
  # @see #conf_dir=
  attr_accessor :conf_key_file

  # @return [String] path of conf_process_xml_file
  # @see #conf_dir=
  attr_accessor :conf_process_xml_file

  # @return [String] path of conf_map_file
  # @see #conf_dir=
  attr_accessor :conf_map_file

  # Set/get <tt>sfdc.endpoint</tt> in XML config.
  # @return [String] 
  # @example
  #   dataloader.endpoint = 'https://' + 'test.salesforce.com'
  attr_accessor :endpoint

  # Set/get <tt>sfdc.username</tt> in XML config.
  # @return [String] 
  # @example
  #   dataloader.usrname = 'foo@example.com'
  attr_accessor :username

  # Set/get <tt>sfdc.password</tt> in XML config.
  # @return [String] 
  # @example
  #   dataloader.password = '0123456789'
  attr_accessor :password

  # @return [String]
  # @see PROCESS_XML_TEMPLATE
  attr_accessor :bean_id

  # @return [String]
  # @see PROCESS_XML_TEMPLATE
  attr_accessor :bean_description

  # @return [String]
  # @see PROCESS_XML_TEMPLATE
  attr_accessor :property_name

  # @return [String]
  # @see BASE_ENTRIES
  attr_accessor :overwrite_entries

  # @param jar [String] path of dataloader-NN.N.N-uber.jar.
  # @param java [String] path of java runtime.
  # @param java_opt [String] command line option for java runtime.
  # @example
  #   UseSalesforceDataLoader.new('/usr/lib/dataloader-41.0.0-uber.jar', '/usr/bin/java', '-Dfile.encoding=UTF-8')
  #
  def initialize(jar, java = nil, java_opt = nil)
    java = exec_command('which java') unless java
    path_check(java)
    path_check(jar)
    j = [java, java_opt, '-cp', jar].compact.join(' ')
    @encrypt = "#{j} com.salesforce.dataloader.security.EncryptionUtil"
    @process = "#{j} -Dsalesforce.config.dir=%s com.salesforce.dataloader.process.ProcessRunner process.name=%s"
  end

  # @note
  #
  #   Original:
  #
  #   dataloader/bin/process.sh
  #
  #   Usage: dataloader/bin/process.sh [conf-dir] <process-name>
  #
  # Return command line string for execute dataloader by named process.
  # @param name [String]
  # @return [String] command line
  def process_cmd(name)
    path_check(@conf_dir)
    path_check(@conf_process_xml_file)
    @process % [@conf_dir, name]
  end

  # Save encrypt key file
  # @see #conf_key_file
  # @return [String] conf_key_file
  def save_conf_key_file
    @conf_key_file.tap do |f|
      open(f, 'w:UTF-8') do |o|
        o.print encrypt("-g #{text_seed}")
      end
    end
  end

  # Save conf xml file
  # @see #conf_process_xml
  # @return [String] conf_process_xml_file
  def save_conf_process_xml_file
    @conf_process_xml_file.tap do |f|
      open(f, 'w:UTF-8') do |o|
        o.print conf_process_xml
      end
    end
  end

  # Generate XML config
  # @return [String] xml config
  def conf_process_xml
    entries = BASE_ENTRIES.merge(default_overwrite_entries)
    entries.merge!(@overwrite_entries) if @overwrite_entries
    entries_xml = entries
      .select{|k, v| v}
      .map{|k, v| ENTRIES_XML_TEMPLATE % [k, v]}
      .join
      .chomp
    PROCESS_XML_TEMPLATE % [@bean_id,
                            @bean_description,
                            @property_name,
                            entries_xml]
  end

  # @note
  #
  #   Original:
  #
  #   dataloader/bin/encrypt.sh
  #
  #   Usage: dataloader/bin/encrypt.sh
  #
  #   Utility to encrypt a string based on a static or a provided key
  #
  #   Options (mutually exclusive - use one at a time):
  #
  #   -g <seed text> Generate key based on seed
  #
  #   -v <encrypted> <decrypted value> [Path to Key] Validate whether decryption of encrypted value matches the decrypted value, optionally provide key file
  #
  #   -e <plain text> [Path to Key]                  Encrypt a plain text value, optionally provide key file (generate key using option -g)
  #
  # internal use
  # @param [String] options
  # @return [String]
  def encrypt(options)
    cmd = "#{@encrypt} #{options} | sed 's/^.*) \- //g'"
    exec_command(cmd)
  end

  # internal use
  # @see #conf_process_xml
  # @return [Hash]
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
  # @return [String] random seed
  private def text_seed
    rand(0xffff_ffff).to_s(16)
  end

  # internal use
  # @return [true, false]
  private def path_check(f)
    raise "Path not found: #{f}" unless File.exist?(f)
  end

  # internal use
  # @param [String] cmd
  # @return [String] stdout of cmd
  private def exec_command(cmd)
    o, e, s = Open3.capture3(cmd)
    raise "Something wrong" unless e.empty? and s.success?
    o.chomp
  end

  # @note internal use
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

  # @note internal use
  ENTRIES_XML_TEMPLATE = <<'ENTRIES_XML'
        <entry key="%s" value="%s"/>
ENTRIES_XML
          
  # @note internal use
  BASE_ENTRIES = {
    'dataAccess.readUTF8'               => 'true',
    'dataAccess.writeUTF8'              => 'true',
    'dataAccess.name'                   => nil,
    'dataAccess.readBatchSize'          => nil,
    'dataAccess.type'                   => nil,
    'dataAccess.writeBatchSize'         => nil,
    'process.enableExtractStatusOutput' => 'false',
    'process.enableLastRunOutput'       => 'true',
    'process.encryptionKeyFile'         => nil, # see also #conf_dir
    'process.initialLastRunDate'        => nil,
    'process.lastRunOutputDirectory'    => nil, # see also #conf_dir
    'process.loadRowToStartAt'          => nil,
    'process.mappingFile'               => nil, # see also #conf_dir
    'process.operation'                 => nil,
    'process.statusOutputDirectory'     => nil, # see also #conf_dir
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
    'sfdc.endpoint'                     => nil, # see also #endpoint
    'sfdc.entity'                       => nil,
    'sfdc.externalIdField'              => nil,
    'sfdc.extractionRequestSize'        => nil,
    'sfdc.extractionSOQL'               => nil,
    'sfdc.insertNulls'                  => 'true',
    'sfdc.loadBatchSize'                => nil, # recommended value? -> 200(Not Bulk API) / 2000(Bulk API)
    'sfdc.maxRetries'                   => nil,
    'sfdc.minRetrySleepSecs'            => nil,
    'sfdc.noCompression'                => nil,
    'sfdc.password'                     => nil, # see also #password
    'sfdc.proxyHost'                    => nil,
    'sfdc.proxyPassword'                => nil,
    'sfdc.proxyPort'                    => nil,
    'sfdc.proxyUsername'                => nil,
    'sfdc.resetUrlOnLogin'              => nil,
    'sfdc.timeoutSecs'                  => nil,
    'sfdc.timezone'                     => nil,
    'sfdc.truncateFields'               => 'false',
    'sfdc.useBulkApi'                   => nil,
    'sfdc.username'                     => nil, # see also #username
  }
end

=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
# Parse command line arguments, set options and initialize +Context+
# accordingly.
class Options
  # Gateway IP address.
  attr_accessor :gateway
  # Network interface.
  attr_accessor :iface
  # Name of the spoofer to use.
  attr_accessor :spoofer
  # If true half duplex mode is enabled.
  attr_accessor :half_duplex
  # Comma separated list of targets.
  attr_accessor :target
  # Log file name.
  attr_accessor :logfile
  # If true will suppress every log message which is not an error or a warning.
  attr_accessor :silent
  # If true will enable debug messages.
  attr_accessor :debug
  # If true will disable active network discovery, the program will just use
  # the current ARP cache.
  attr_accessor :arpcache
  # Comma separated list of ip addresses to ignore.
  attr_accessor :ignore
  # If true the BetterCap::Sniffer will be enabled.
  attr_accessor :sniffer
  # PCAP file name to save captured packets to.
  attr_accessor :sniffer_pcap
  # BPF filter to apply to sniffed packets.
  attr_accessor :sniffer_filter
  # Input PCAP file, if specified the BetterCap::Sniffer will read packets
  # from it instead of the network.
  attr_accessor :sniffer_src
  # Comma separated list of BetterCap::Parsers to enable.
  attr_accessor :parsers
  # Regular expression to use with the BetterCap::Parsers::Custom parser.
  attr_accessor :custom_parser
  # If true, bettercap will sniff packets from the local interface as well.
  attr_accessor :local
  # If true, HTTP transparent proxy will be enabled.
  attr_accessor :proxy
  # If true, HTTPS transparent proxy will be enabled.
  attr_accessor :proxy_https
  # HTTP proxy port.
  attr_accessor :proxy_port
  # HTTPS proxy port.
  attr_accessor :proxy_https_port
  # File name of the PEM certificate to use for the HTTPS proxy.
  attr_accessor :proxy_pem_file
  # File name of the transparent proxy module to load.
  attr_accessor :proxy_module
  # Custom HTTP transparent proxy address.
  attr_accessor :custom_proxy
  # Custom HTTP transparent proxy port.
  attr_accessor :custom_proxy_port
  # Custom HTTPS transparent proxy address.
  attr_accessor :custom_https_proxy
  # Custom HTTPS transparent proxy port.
  attr_accessor :custom_https_proxy_port
  # If true, BetterCap::HTTPD::Server will be enabled.
  attr_accessor :httpd
  # The port to bind BetterCap::HTTPD::Server to.
  attr_accessor :httpd_port
  # Web root of the BetterCap::HTTPD::Server.
  attr_accessor :httpd_path
  # If true, bettercap will check for updates then exit.
  attr_accessor :check_updates
  # If true, targets NBNS hostname resolution won't be performed.
  attr_accessor :no_target_nbns
  # If true, bettercap won't forward packets for any target, causing
  # connections to be killed.
  attr_accessor :kill
  # If different than 0, this time will be used as a delay while sending packets.
  attr_accessor :packet_throttle

  # Create a BetterCap::Options class instance using the specified network interface.
  def initialize( iface )
    @gateway = nil
    @iface = iface
    @spoofer = 'ARP'
    @half_duplex = false
    @target = nil
    @logfile = nil
    @silent = false
    @debug = false
    @arpcache = false
    @no_target_nbns = false
    @kill = false
    @packet_throttle = 0.0

    @ignore = nil

    @sniffer = false
    @sniffer_pcap = nil
    @sniffer_filter = nil
    @sniffer_src = nil
    @parsers = ['*']
    @custom_parser = nil
    @local = false

    @proxy = false
    @proxy_https = false
    @proxy_port = 8080
    @proxy_https_port = 8083
    @proxy_pem_file = nil
    @proxy_module = nil

    @custom_proxy = nil
    @custom_proxy_port = 8080

    @custom_https_proxy = nil
    @custom_https_proxy_port = 8083

    @httpd = false
    @httpd_port = 8081
    @httpd_path = './'

    @check_updates = false
  end

  # Initialize the BetterCap::Context, parse command line arguments and update program
  # state accordingly.
  # Will rise a BetterCap::Error if errors occurred.
  def self.parse!
    ctx = Context.get

    OptionParser.new do |opts|
      opts.version = BetterCap::VERSION
      opts.banner = "Usage: bettercap [options]"
      opts.separator ""
      opts.separator "Specific options:"
      opts.separator ""

      opts.on( '-G', '--gateway ADDRESS', 'Manually specify the gateway address, if not specified the current gateway will be retrieved and used. ' ) do |v|
        ctx.options.gateway = v
      end

      opts.on( '-I', '--interface IFACE', 'Network interface name - default: ' + ctx.options.iface.to_s ) do |v|
        ctx.options.iface = v
      end

      opts.on( '-S', '--spoofer NAME', 'Spoofer module to use, available: ' + Factories::Spoofer.available.join(', ') + ' - default: ' + ctx.options.spoofer ) do |v|
        ctx.options.spoofer = v
      end

      opts.on( '-T', '--target ADDRESS1,ADDRESS2', 'Target IP addresses, if not specified the whole subnet will be targeted.' ) do |v|
        ctx.options.target = v
      end

      opts.on( '--ignore ADDRESS1,ADDRESS2', 'Ignore these addresses if found while searching for targets.' ) do |v|
        ctx.options.ignore = v
      end

      opts.on( '-O', '--log LOG_FILE', 'Log all messages into a file, if not specified the log messages will be only print into the shell.' ) do |v|
        ctx.options.logfile = v
      end

      opts.on( '-D', '--debug', 'Enable debug logging.' ) do
        ctx.options.debug = true
      end

      opts.on( '-L', '--local', 'Parse packets coming from/to the address of this computer ( NOTE: Will set -X to true ), default to false.' ) do
        ctx.options.local = true
        ctx.options.sniffer = true
      end

      opts.on( '-X', '--sniffer', 'Enable sniffer.' ) do
        ctx.options.sniffer = true
      end

      opts.on( '--sniffer-source FILE', 'Load packets from the specified PCAP file instead of the interface ( will enable sniffer ).' ) do |v|
        ctx.options.sniffer = true
        ctx.options.sniffer_src = File.expand_path v
      end

      opts.on( '--sniffer-pcap FILE', 'Save all packets to the specified PCAP file ( will enable sniffer ).' ) do |v|
        ctx.options.sniffer = true
        ctx.options.sniffer_pcap = File.expand_path v
      end

      opts.on( '--sniffer-filter EXPRESSION', 'Configure the sniffer to use this BPF filter ( will enable sniffer ).' ) do |v|
        ctx.options.sniffer = true
        ctx.options.sniffer_filter = v
      end

      opts.on( '-P', '--parsers PARSERS', 'Comma separated list of packet parsers to enable, "*" for all ( NOTE: Will set -X to true ), available: ' + Factories::Parser.available.join(', ') + ' - default: *' ) do |v|
        ctx.options.sniffer = true
        ctx.options.parsers = Factories::Parser.from_cmdline(v)
      end

      opts.on( '--custom-parser EXPRESSION', 'Use a custom regular expression in order to capture and show sniffed data ( NOTE: Will set -X to true ).' ) do |v|
        ctx.options.sniffer       = true
        ctx.options.parsers       = ['CUSTOM']
        ctx.options.custom_parser = Regexp.new(v)
      end

      opts.on( '--silent', 'Suppress every message which is not an error or a warning, default to false.' ) do
        ctx.options.silent = true
      end

      opts.on( '--no-discovery', 'Do not actively search for hosts, just use the current ARP cache, default to false.' ) do
        ctx.options.arpcache = true
      end

      opts.on( '--no-spoofing', 'Disable spoofing, alias for --spoofer NONE.' ) do
        ctx.options.spoofer = 'NONE'
      end

      opts.on( '--no-target-nbns', 'Disable target NBNS hostname resolution.' ) do
        ctx.options.no_target_nbns = true
      end

      opts.on( '--half-duplex', 'Enable half-duplex MITM, this will make bettercap work in those cases when the router is not vulnerable.' ) do
        ctx.options.half_duplex = true
      end

      opts.on( '--proxy', 'Enable HTTP proxy and redirects all HTTP requests to it, default to false.' ) do
        ctx.options.proxy = true
      end

      opts.on( '--proxy-https', 'Enable HTTPS proxy and redirects all HTTPS requests to it, default to false.' ) do
        ctx.options.proxy = true
        ctx.options.proxy_https = true
      end

      opts.on( '--proxy-port PORT', 'Set HTTP proxy port, default to ' + ctx.options.proxy_port.to_s + ' .' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_port = v.to_i
      end

      opts.on( '--proxy-https-port PORT', 'Set HTTPS proxy port, default to ' + ctx.options.proxy_https_port.to_s + ' .' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_https = true
        ctx.options.proxy_https_port = v.to_i
      end

      opts.on( '--proxy-pem FILE', 'Use a custom PEM certificate file for the HTTPS proxy.' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_https = true
        ctx.options.proxy_pem_file = File.expand_path v
      end

      opts.on( '--proxy-module MODULE', 'Ruby proxy module to load.' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_module = File.expand_path v

        require ctx.options.proxy_module

        Proxy::Module.register_options(opts)
      end

      opts.on( '--custom-proxy ADDRESS', 'Use a custom HTTP upstream proxy instead of the builtin one.' ) do |v|
        ctx.options.custom_proxy = v
      end

      opts.on( '--custom-proxy-port PORT', 'Specify a port for the custom HTTP upstream proxy, default to ' + ctx.options.custom_proxy_port.to_s + ' .' ) do |v|
        ctx.options.custom_proxy_port = v.to_i
      end

      opts.on( '--custom-https-proxy ADDRESS', 'Use a custom HTTPS upstream proxy instead of the builtin one.' ) do |v|
        ctx.options.custom_https_proxy = v
      end

      opts.on( '--custom-https-proxy-port PORT', 'Specify a port for the custom HTTPS upstream proxy, default to ' + ctx.options.custom_https_proxy_port.to_s + ' .' ) do |v|
        ctx.options.custom_https_proxy_port = v.to_i
      end

      opts.on( '--httpd', 'Enable HTTP server, default to false.' ) do
        ctx.options.httpd = true
      end

      opts.on( '--httpd-port PORT', 'Set HTTP server port, default to ' + ctx.options.httpd_port.to_s +  '.' ) do |v|
        ctx.options.httpd = true
        ctx.options.httpd_port = v.to_i
      end

      opts.on( '--httpd-path PATH', 'Set HTTP server path, default to ' + ctx.options.httpd_path +  '.' ) do |v|
        ctx.options.httpd = true
        ctx.options.httpd_path = v
      end

      opts.on( '--kill', 'Instead of forwarding packets, this switch will make targets connections to be killed.' ) do
        ctx.options.kill = true
      end

      opts.on( '--packet-throttle NUMBER', 'Number of seconds ( can be a decimal number ) to wait between each packet to be sent.' ) do |v|
        ctx.options.packet_throttle = v.to_f
        raise BetterCap::Error, "Invalid packet throttle value specified." if ctx.options.packet_throttle <= 0.0
      end

      opts.on( '--check-updates', 'Will check if any update is available and then exit.' ) do
        ctx.options.check_updates = true
      end

      opts.on('-h', '--help', 'Display the available options.') do
        puts opts
        puts "\nFor examples & docs please visit " + "http://bettercap.org/docs/".bold
        exit
      end
    end.parse!

    Logger.init( ctx.options.debug, ctx.options.logfile, ctx.options.silent )

    Logger.warn "You are running an unstable/beta version of this software, please" \
                " update to a stable one if available." if BetterCap::VERSION =~ /[\d\.+]b/

    if ctx.options.check_updates
      UpdateChecker.check
      exit
    end

    raise BetterCap::Error, 'This software must run as root.' unless Process.uid == 0
    raise BetterCap::Error, 'No default interface found, please specify one with the -I argument.' if ctx.options.iface.nil?

    unless ctx.options.gateway.nil?
      raise BetterCap::Error, "The specified gateway '#{ctx.options.gateway}' is not a valid IPv4 address." unless Network.is_ip?(ctx.options.gateway)
      ctx.gateway = ctx.options.gateway
      Logger.debug("Targetting manually specified gateway #{ctx.gateway}")
    end

    unless ctx.options.target.nil?
      ctx.targets = ctx.options.to_targets
    end

    # Load firewall instance, network interface informations and detect the
    # gateway address.
    ctx.update!

    # Spoofers need the context network data to be initialized.
    ctx.spoofer = ctx.options.to_spoofers

    ctx
  end

  # Return true if active host discovery is enabled, otherwise false.
  def should_discover_hosts?
    !@arpcache
  end

  # Return true if a proxy module was specified, otherwise false.
  def has_proxy_module?
    !@proxy_module.nil?
  end

  # Return true if a spoofer module was specified, otherwise false.
  def has_spoofer?
    @spoofer != 'NONE' and @spoofer != 'none'
  end

  # Return true if the BetterCap::Parsers::URL is enabled, otherwise false.
  def has_http_sniffer_enabled?
    @sniffer and ( @parsers.include?'*' or @parsers.include?'URL' )
  end

  # Return true if the +ip+ address needs to be ignored, otherwise false.
  def ignore_ip?(ip)
    !@ignore.nil? and @ignore.include?(ip)
  end

  # Setter for the #ignore attribute, will raise a BetterCap::Error if one
  # or more invalid IP addresses are specified.
  def ignore=(value)
    @ignore = value.split(",")
    valid = @ignore.select { |target| Network.is_ip?(target) }

    raise BetterCap::Error, "Invalid ignore addresses specified." if valid.empty?

    invalid = @ignore - valid
    invalid.each do |target|
      Logger.warn "Not a valid address: #{target}"
    end

    @ignore = valid

    Logger.warn "Ignoring #{valid.join(", ")} ."
  end

  # Setter for the #custom_proxy attribute, will raise a BetterCap::Error if
  # +value+ is not a valid IP address.
  def custom_proxy=(value)
    @custom_proxy = value
    raise BetterCap::Error, 'Invalid custom HTTP upstream proxy address specified.' unless Network.is_ip? @custom_proxy
  end

  # Setter for the #custom_https_proxy attribute, will raise a BetterCap::Error if
  # +value+ is not a valid IP address.
  def custom_https_proxy=(value)
    @custom_https_proxy = value
    raise BetterCap::Error, 'Invalid custom HTTPS upstream proxy address specified.' unless Network.is_ip? @custom_https_proxy
  end

  # Split specified targets and parse them ( either as IP or MAC ), will raise a
  # BetterCap::Error if one or more invalid addresses are specified.
  def to_targets
    targets = @target.split(",")
    valid_targets = targets.select { |target| Network.is_ip?(target) or Network.is_mac?(target) }

    raise BetterCap::Error, "Invalid target specified." if valid_targets.empty?

    invalid_targets = targets - valid_targets
    invalid_targets.each do |target|
      Logger.warn "Invalid target specified: #{target}"
    end

    valid_targets.map { |target| Network::Target.new(target) }
  end

  # Parse spoofers and return a list of BetterCap::Spoofers objects. Raise a
  # BetterCap::Error if an invalid spoofer name was specified.
  def to_spoofers
    spoofers = []
    spoofer_modules_names = @spoofer.split(",")
    spoofer_modules_names.each do |module_name|
      spoofers << Factories::Spoofer.get_by_name( module_name )
    end
    spoofers
  end

  # Create a list of BetterCap::Firewalls::Redirection objects which are needed
  # given the specified command line arguments.
  def to_redirections ifconfig
    redirections = []

    if @proxy
      redirections << Firewalls::Redirection.new( @iface,
                                       'TCP',
                                       80,
                                       ifconfig[:ip_saddr],
                                       @proxy_port )
    end

    if @proxy_https
      redirections << Firewalls::Redirection.new( @iface,
                                       'TCP',
                                       443,
                                       ifconfig[:ip_saddr],
                                       @proxy_https_port )
    end

    if @custom_proxy
      redirections << Firewalls::Redirection.new( @iface,
                                       'TCP',
                                       80,
                                       @custom_proxy,
                                       @custom_proxy_port )
    end

    if @custom_https_proxy
      redirections << Firewalls::Redirection.new( @iface,
                                       'TCP',
                                       443,
                                       @custom_https_proxy,
                                       @custom_https_proxy_port )
    end

    redirections
  end
end
end

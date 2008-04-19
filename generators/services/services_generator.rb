class ServicesGenerator < Rails::Generator::NamedBase
  default_options :ip => "127.0.0.1", :environment => "production", :number => 5
  attr_accessor :number, :service_name, :ip, :port, :environment, :document_root, :virtualhost, :sub_dir

  def initialize(runtime_args, runtime_options = {})
    super
    @service_name = runtime_args.shift
    @number  = options[:number].to_i
    raise "Too many listeners, are you psycho?! Must be between 0 and 100" unless @number >= 0 and @number <= 100
    @sub_dir = options[:sub_dir] || false
    @virtualhost = options[:virtual_host] || @service_name
    @document_root = options[:document_root] || File.join(RAILS_ROOT, "public")
    @environment = options[:environment]
    @ip = options[:ip]
    @port = options[:port_prefix] || 123
    raise "Invalid Port! Must be between 102 and 654" unless @port.to_i > 102 and @port.to_i < 655
  end

  def manifest
    recorded_session = record do |m|
      m.directory "service"

      m.directory File.join("config", "lighttpd")
      if sub_dir
        m.template File.join("conf-available", "15-application-subdir.conf.erb"), File.join("config", "lighttpd", "15-#{service_name}.conf")
      else
        m.template File.join("conf-available", "15-application-virtualhost.conf.erb"), File.join("config", "lighttpd", "15-#{service_name}.conf")
      end
      
      
      if @number == 0
        @number = 1
        make_service(m, "generic")
      else
        @number.times do |num|
          make_service m, "#{service_name}-#{num}"
        end
      end

      #TODO: show a readme/usage/how to get this thing running statement
    end
  end

  protected

  def make_service(mm, name_num)
    mm.directory File.join("service", name_num)
    mm.directory File.join("service", name_num, "env")
    mm.directory File.join("service", name_num, "log")

    mm.file File.join("generic", "run"), File.join("service", name_num, "run"), :chmod => 0755
    mm.file File.join("generic", "log", "run"), File.join("service", name_num, "log", "run"), :chmod => 0755
    mm.template File.join("generic", "env", "RAILS_ROOT"), File.join("service", name_num, "env", "RAILS_ROOT")
    mm.template File.join("generic", "env", "RAILS_ENV"), File.join("service", name_num, "env", "RAILS_ENV")
    mm.template File.join("generic", "env", "IP"), File.join("service", name_num, "env", "IP")
    mm.template File.join("generic", "env", "PORT"), File.join("service", name_num, "env", "PORT")
  end

  def has_rspec?
    options[:rspec] || (File.exist?('spec') && File.directory?('spec'))
  end

  def banner
    "Usage: #{$0} services NAME [options]
      NAME will be the service name of your application (used for starting, restarting, /subdir naming)"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--virtual-host VHOST","The virtual host to use for lighttpd config (Defaults to NAME)") { |v| options[:virtual_host] = v }
    opt.on("--ip IP","IP to bind to (Defaults to localhost)") { |v| options[:ip] = v }
    # TODO: allow for subdir + virtual hosting
    opt.on("--sub-directory","Run this application as http://yourhost/subdir (where subdir is your service's NAME). NOTE: Enabling this option disables virtualhosting") { options[:sub_dir] = true }
    opt.on("--environment ENVIRONMENT","Choose environment (Defaults to production)") { |v| options[:environment] = v }
    opt.on("--number NUMBER","The number of listeners to create (Default is 5). Use 0 to generate a 'generic' run directory (good for customization)") { |v| options[:number] = v }
    opt.on("--port-prefix", "PORT_PREFIX (103-654) will be the base of the listening ports, a prefix of 103 would lead to listeners on 1030, 1031, 1032, 1034, and 1035") { |v| options[:port_prefix] = v }
  end

end

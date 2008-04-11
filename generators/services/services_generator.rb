class ServicesGenerator < Rails::Generator::NamedBase
  default_options :ip => "127.0.0.1", :environment => "production", :number => 5
  #required_options :port_prefix
  attr_accessor :number, :service_name, :ip, :port, :environment

  def initialize(runtime_args, runtime_options = {})
    super
    @port = runtime_args.shift.to_i
    raise "Invalid Port! Must be between 102 and 654" unless @port.to_i > 102 and @port.to_i < 655
    @number  = options[:number].to_i
    raise "Too many listeners, are you psycho?! Must be between 0 and 100" unless @number >= 0 and @number <= 100
    @service_name = options[:service_name] || File.basename(RAILS_ROOT)
    @environment = options[:environment]
    @ip = options[:ip]
  end

  def manifest
    recorded_session = record do |m|
      m.directory "service"
      
      make_service(m, "generic") if @number == 0
      
      @number.times do |num|
        make_service m, "#{service_name}-#{num}"
      end

    end
  end

  protected

  def make_service(mm, name_num)
    mm.directory File.join("service", name_num)
    mm.directory File.join("service", name_num, "env")
    mm.directory File.join("service", name_num, "log")

    mm.file 'generic/run', File.join("service", name_num, "run"), :chmod => 0755
    mm.file 'generic/log/run', File.join("service", name_num, "log", "run"), :chmod => 0755
    mm.template 'generic/env/RAILS_ROOT', File.join("service", name_num, "env", "RAILS_ROOT")
    #mm.template 'generic/env/RAILS_ENV', File.join("service", name_num, "env", "RAILS_ENV")
    mm.template 'generic/env/IP', File.join("service", name_num, "env", "IP")
    mm.template 'generic/env/PORT', File.join("service", name_num, "env", "PORT")

  end

  def has_rspec?
    options[:rspec] || (File.exist?('spec') && File.directory?('spec'))
  end

  def banner
    "Usage: #{$0} services PORT_PREFIX
       PORT_PREFIX (103-654) will be the base of the listening ports, a prefix of 103 would lead to listeners on 1030, 1031, 1032, 1034, and 1035"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("-nNAME", "--name NAME","Name of this service (Defaults to basename of RAILS_ROOT)") { |v| options[:ip] = v }
    opt.on("-iIP", "--ip IP","IP to bind to (Defaults to localhost)") { |v| options[:ip] = v }
    opt.on("-eENVIRONMENT", "--environment ENVIRONMENT","Choose environment (Defaults to production)") { |v| options[:environment] = v }
    opt.on("--number NUMBER","The number of listeners to create (Default is 5). Use 0 to generate a 'generic' run directory (good for customization)") { |v| options[:number] = v }
  end

end

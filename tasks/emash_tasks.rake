require "open-uri"
require "fileutils"
namespace :emash do
  desc "Install runit supervision system"
  task :runit_install do
    tarball = download_runit 
    runit_dir = extract_runit(tarball)
    compile_runit(runit_dir)
    install_runit
    usage
  end

  def download_runit
    install_html = open("http://smarden.org/runit/install.html").read
    download_file = install_html.match(/Download\s+<a href="(.*?)">/)[1]
    open("http://smarden.org/runit/" + download_file)
  end

  def extract_runit(tarball)
    minitar = false
    begin
      require "zlib"
      require "archive/tar/minitar"
      minitar = true
    rescue LoadError
      nil
    end
    FileUtils.mkpath(package_path = File.join((ENV["REAL_HOME"] || ENV["HOME"]), "package"))
    Dir.chdir(package_path)
    if minitar
      tgz = Zlib::GzipReader.new(File.open(tarball.path, 'rb'))
      Archive::Tar::Minitar.unpack(tgz, ".")
    else
      puts %x{gzip -dc #{tarball.path} | tar xvf -}
    end
    Dir["admin/runit*"].last
  end

  def compile_runit(dir)
    Dir.chdir(dir)

    if(%x{uname} == "Darwin\n")
      compile_runit_os_x
    else
      puts %x{./package/compile}
    end
  end

  def compile_runit_os_x
    # Mac OS X can't build static binaries
    # http://developer.apple.com/qa/qa2001/qa1118.html
    # Don't compile runit and runit-init
    compile_data = File.read('package/compile')
    File.open('package/compile', 'w') { |f| f.puts compile_data.sub(/^(sh [^']+)'cd compile; exec make'/, '\1"cd compile; exec make $*"') }
    commands_data = File.read('package/commands')
    File.open('package/commands', 'w') { |f| f.puts commands_data.gsub(/^runit.*$\n/, '') }
    conf_ld_data = File.read('src/conf-ld')
    File.open('src/conf-ld', 'w') { |f| f.puts conf_ld_data.sub(/gcc -s/, 'gcc ') }

    puts %x{./package/compile IT="unix.a byte.a chpst runsv runsvchdir runsvdir sv svlogd utmpset"}
  end

  def install_runit
    FileUtils.mkpath(bin_dir = File.join((ENV["REAL_HOME"] || ENV["HOME"]), "bin"))
    Dir["command/*"].each do |command|
      link_target = File.expand_path(File.join(bin_dir, File.basename(command)))
      File.unlink(link_target) if(File.exists?(link_target))
      FileUtils.symlink(File.expand_path(command), link_target)
    end
  end

  def usage
    puts "Runit Successfully Installed"
  end
end

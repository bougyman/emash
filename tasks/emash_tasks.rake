require "open-uri"
require "fileutils"
namespace :emash do
  desc "Install runit supervision system"
  task :runit_install do
    tarball = download_runit 
    runit_dir = extract_runit(tarball)
    compile_runit(runit_dir)
  end

  def download_runit
    install_html = open("http://smarden.org/runit/install.html").read
    download_file = install_html.match(/Download\s+<a href="(.*?)">/)[1]
    downloaded = open("http://smarden.org/runit/" + download_file)
  end

  def extract_runit(tarball)
    minitar = false
    begin
      require "zlib"
      require "archive/tar/minitar"
      minitar = true
    rescue
      nil
    end
    FileUtils.mkpath(package_path = File.join((ENV["REAL_HOME"] || ENV["HOME"]), "package"))
    Dir.chdir(package_path)
    if minitar
      tgz = Zlib::GzipReader.new(File.open(tarball.path, 'rb'))
      Archive::Tar::Minitar.unpack(tgz, ".")
    else
      puts %x{tar zxvf #{tarball.path}}
    end
    Dir["admin/runit*"].last
  end

  def compile_runit(dir)
    Dir.chdir(dir)
    puts %x{./package/install}
  end
end

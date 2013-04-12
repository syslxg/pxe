require 'erb'
require 'yaml'

class PXEcfg_updater

  def initialize (env, servers )

    @env = env
    @servers=servers
  end

  def update_pxelinuxcfg_files

    erb=ERB.new File.read "templates/pxelinuxcfg.erb"
    @servers.each do |server, properties|
      hostname=properties["hostname"] || server
      os=properties["os"]
      mac=properties["mac"].to_s.downcase
      bootcfg=@env["bootcfg"]

      filename=File.join @env["tftproot"], "pxelinux.cfg", "01-#{mac}"

      File.open(filename, "w") { |f| f.puts erb.result(binding) }

    end

  end

  def update_boot_cfg_files

    @servers.each do |server, properties|

      os=properties["os"]
      ks_host=@env["ks_host"]
      bootcfg=@env["bootcfg"]
      erb=ERB.new File.read "templates/bootcfg_#{os}.erb"
      filename=File.join @env["tftproot"], bootcfg, "boot_#{server}.cfg"

      File.open(filename, "w") { |f| f.puts erb.result(binding) }
    end

  end

  def update_ks_files
    erb=ERB.new File.read "templates/ks.erb"
    @servers.each do |server, properties|
      hostname=properties["hostname"] || server
      ip=properties["ip"]
      ks=@env["ks"]
      esxi_pw= @env["esxi_pw"]
      esxi_gw= @env["esxi_gw"]
      dns=     @env["dns"]
      esxi_netmask=@env["esxi_netmask"]

      filename=File.join @env["tftproot"], ks, "#{server}.ks"

      File.open(filename, "w") { |f| f.puts erb.result(binding) }

    end
  end



  def update
    update_pxelinuxcfg_files
    update_boot_cfg_files
    update_ks_files
  end

end


settings= YAML.load_file 'settings.yml'
unless settings && settings["servers"]
  puts("settings not found or not servers defined in settings")
  exit 1
end

updater=PXEcfg_updater.new settings["env"], settings["servers"]
updater.update

module IptablesWeb
  module Model
    class Node < Base
      self.element_name = 'node'
      self.include_root_in_json = true

      def self.handshake
        node = find('current')
        node.ips = []
        ::System.get_ifaddrs.each do |interface, config|
          next if interface.to_s.include?('lo')
          node.ips.push({
            interface: interface,
            ip: config[:inet_addr],
            netmask: config[:netmask]
          })
        end
        node.hostname = `hostname -f`
        if node.save && block_given?
          yield
        end
      end
    end
  end
end

# *filter
# :INPUT ACCEPT [217626552:31573175391]
# :FORWARD ACCEPT [0:0]
# :OUTPUT ACCEPT [1334268962:861811554534]
# -A INPUT -s 88.150.233.48/29 -p tcp -m tcp --dport 9200 -j ACCEPT
# -A INPUT -s 88.150.213.250/32 -p tcp -m tcp --dport 9200 -j ACCEPT
# -A INPUT -s 127.0.0.1/32 -p tcp -m tcp --dport 9200 -j ACCEPT
# -A INPUT -s 37.220.8.122/32 -p tcp -m tcp --dport 9200 -j ACCEPT
# -A INPUT -p tcp -m tcp --dport 9200 -j DROP
# -A INPUT -s 88.150.233.48/29 -p tcp -m tcp --dport 9300 -j ACCEPT
# -A INPUT -s 88.150.213.250/32 -p tcp -m tcp --dport 9300 -j ACCEPT
# -A INPUT -p tcp -m tcp --dport 9300 -j DROP
# -A INPUT -s 193.105.70.192/29 -p tcp -m tcp --dport 22 -j ACCEPT
# -A INPUT -s 92.60.190.109/32 -p tcp -m tcp --dport 22 -j ACCEPT
# -A INPUT -p tcp -m tcp --dport 22 -j DROP
# COMMIT

require 'shellwords'
module IptablesWeb
  module Model
    class AccessRule < Base
      self.element_name = 'access_rule'
      SUPPORTED_PROTOCOLS = %w(tcp udp)

      def make
        protocols = protocol.to_s.downcase == 'all' ? SUPPORTED_PROTOCOLS : [protocol]
        protocols.map do |protocol|
          self.resolved_ips.map do |ip|
            command = %w(-A INPUT)
            self.attributes.each do |name, value|
              case name.to_sym
                when :port
                  next if value.to_s.empty? || !value
                  if value.match(/(:|,)/)
                    command << '-m'
                    command << 'multiport'
                    command << '--dports'
                    command << value
                  else
                    command << '--dport'
                    command << value
                  end
                when :protocol
                  next unless protocol
                  command << '-p'
                  command << protocol
                when :description
                  if value && !value.empty?
                    command << '-m'
                    command << 'comment'
                    command << '--comment'
                    command << "\"#{description.strip.gsub('"', '\"')}\""
                  end

                else
                  #skip
              end
            end
            command << '-s'
            command << ip
            command << '-j'
            command << 'ACCEPT'
            command.join(' ')
          end
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

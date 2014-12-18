require 'tempfile'
module IptablesWeb
  class Iptables
    include IptablesWeb::Mixin::Sudo

    def restore(access_rules)
      temp_file = Tempfile.new('rules')
      temp_file.write render(access_rules)
      temp_file.rewind
      execute("iptables-restore -c < #{temp_file.path}")
    ensure
      if temp_file
        temp_file.close
        temp_file.unlink
      end
    end

    def save
      execute('iptables-save').split("\n")
    end

    def static_rules
      IptablesWeb::Configuration.static_rules
    end

    def render(rules, name = 'filter')
      lines = []
      lines << "*#{name}"
      lines << ':INPUT DROP [0:0]'
      lines << ':FORWARD ACCEPT [0:0]'
      lines << ':OUTPUT ACCEPT [0:0]'
      lines << static_rules
      lines << Array(rules).map(&:to_s).join("\n")
      lines << 'COMMIT'
      lines << '#end'
      lines.join("\n")
    end
  end
end

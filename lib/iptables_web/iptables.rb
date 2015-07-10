require 'tempfile'
module IptablesWeb
  class Iptables
    include IptablesWeb::Mixin::Sudo

    def restore(access_rules)
      temp_file = Tempfile.new('rules')
      temp_file.write render(access_rules)
      temp_file.rewind
      execute("/sbin/iptables-restore -c #{temp_file.path}")
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

    def render(rules)
      static_rules = self.static_rules
      static_filter = static_rules.delete('filter')
      lines = []
      lines << '*filter'
      lines << ':INPUT DROP [0:0]'
      lines << ':FORWARD ACCEPT [0:0]'
      lines << ':OUTPUT ACCEPT [0:0]'
      lines << static_filter.join("\n").strip if static_filter
      lines << "\n"
      lines << Array(rules).map(&:to_s).join("\n").strip
      lines << "COMMIT\n"
      static_rules.each do |chain, sub_rules|
        lines << "*#{chain}"
        lines << sub_rules.join("\n").strip
        lines << "COMMIT\n"
      end
      lines.join("\n")
    end
  end
end

require 'tempfile'
module IptablesWeb
  class Iptables
    include IptablesWeb::Mixin::Sudo

    def restore(access_rules)
      lines = combine(access_rules)
      if lines.size == 0
        logged_say('Skip restore because no rules found')
        return
      end

      temp_file = Tempfile.new('rules')
      logged_say("Save rules to file #{temp_file.path}")
      temp_file.write lines.join("\n")
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
      IptablesWeb.static_rules
    end

    def combine(rules)
      static_rules = self.static_rules
      static_filter = static_rules.delete('filter')

      filter_rules =[]
      filter_rules = filter_rules | Array(static_filter)
      filter_rules = filter_rules | Array(rules).map(&:to_s)
      filter_rules.reject! { |r| r.strip.empty? }
      lines = []
      if filter_rules.size > 0
        lines << '*filter'
        lines << ':INPUT DROP [0:0]'
        lines << ':FORWARD ACCEPT [0:0]'
        lines << ':OUTPUT ACCEPT [0:0]'
        lines = lines | filter_rules
        lines << "COMMIT\n"
      end

      static_rules.each do |chain, sub_rules|
        lines << "*#{chain}"
        lines << sub_rules.join("\n").strip
        lines << "COMMIT\n"
      end
      lines
    end

    def render(rules)
      combine(rules).join("\n")
    end
  end
end

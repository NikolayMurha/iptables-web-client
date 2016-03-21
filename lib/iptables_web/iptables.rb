require 'tempfile'
module IptablesWeb
  class Iptables
    LABEL = '[iptables-web]'

    IPTABLES_COMMAND = '/sbin/iptables'
    IPTABLES_SAVE_COMMAND = '/sbin/iptables-save'
    IPTABLES_RESTORE_COMMAND = '/sbin/iptables-restore'

    include IptablesWeb::Mixin::Sudo
    include IptablesWeb::Mixin::ConfigParser

    def update(access_rules)
      bash_file = Tempfile.new('rules')
      bash_file.write "#!/bin/bash\n"
      bash_file.write "set -e\n"

      lines = combine_new_rules(access_rules)
      current_rules = parse_rules(`#{sudo(IPTABLES_SAVE_COMMAND)}`)
      bash_file.write sudo("#{sudo(IPTABLES_COMMAND)} -P INPUT ACCEPT")
      bash_file.write "\n"
      current_rules.each do |table, rules|
        rules.each do |rule|
          next unless rule.include?(LABEL)
          bash_file.write sudo("#{IPTABLES_COMMAND} -t #{table} #{rule.gsub('-A', '-D')}")
          bash_file.write "\n"
        end
      end
      bash_file.write "# Create rules\n"
      bash_file.write lines.map { |l| sudo(l) }.join("\n")
      bash_file.write "\n"
      if lines.size > 0
        bash_file.write sudo("#{IPTABLES_COMMAND} -P INPUT DROP")
        bash_file.write "\n"
      end
      bash_file.rewind
      backup
      res = `bash #{bash_file.path} 2>&1`
      unless $? == 0
        logger_log('Failed to import settings. Restore previous configuration. See log for more details.', ::Logger::ERROR)
        restore
        raise res
      end
    ensure
      if bash_file
        bash_file.close
        bash_file.unlink
      end
    end

    def save
      `#{sudo(IPTABLES_SAVE_COMMAND)}`.split("\n")
    end

    def static_rules
      IptablesWeb.static_rules
    end

    def combine_new_rules(rules)
      all_rules = self.static_rules
      static_filter = all_rules.delete('filter')
      all_rules['filter'] = Array(static_filter) | Array(rules).map(&:make).flatten
      all_rules.each_with_object([]) do |(table, sub_rules), arr|
        sub_rules.reject! { |s| s.strip.empty? }
        sub_rules.each do |rule|
          arr << "#{IPTABLES_COMMAND} -t #{table} #{add_label(rule)}"
        end
      end
    end

    def add_label(rule)
      m = rule.match("^(.*?--comment)(\s+)\"(.*?)\"(.*?)$")
      if m
        return rule if m[3].include?(LABEL)
        comment = "#{LABEL} #{m[3]}"
        "#{m[1]} \"#{comment.strip}\"#{m[4]}"
      else
        "#{rule} -m comment --comment \"#{LABEL}\""
      end
    end

    def render(rules)
      combine_new_rules(rules).join("\n")
    end

    def diff
      if @backup
        @after = Tempfile.new('iptables-after')
        `#{sudo(IPTABLES_SAVE_COMMAND)} > #{@after.path}`
        `diff -c #{@backup.path} #{@after.path}`
      end
    end

    def backup
      @backup ||= Tempfile.new('iptables-before')
      logger_log("Create backup #{@backup.path}\n", ::Logger::DEBUG)
      `#{sudo(IPTABLES_SAVE_COMMAND)} > #{@backup.path}`
      @backup.rewind
    end

    def restore
      if @backup && File.exist?(@backup.path)
        `#{sudo(IPTABLES_RESTORE_COMMAND)} -c #{@backup.path}`
      end
    end
  end
end

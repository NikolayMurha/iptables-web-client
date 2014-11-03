require 'tempfile'
module IptablesWeb
  class Crontab
    include IptablesWeb::Mixin::Sudo

    def jobs
      execute('crontab -l 2> /dev/null').split("\n").reject { |l| l.empty? || l.include?('no crontab for') || l[0] == '#' }
    end

    def save(jobs)
      lines = ["##{Time.now}"]
      jobs.each do |job|
        lines << job
        lines << ''
      end
      file = Tempfile.new('crontab')
      file.write lines.join("\n")
      file.rewind
      execute "crontab #{file.path}"
    ensure
      if file
        file.close
        file.unlink
      end
    end

    def execute(command)
      if is_root?
        `sudo #{command}`
      else
        `#{command}`
      end
    end

    def is_root?
      Process.uid == 0
    end
  end
end

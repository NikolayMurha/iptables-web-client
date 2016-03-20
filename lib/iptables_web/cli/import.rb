require 'highline'
require 'forwardable'

$terminal = IptablesWeb::Cli::LoggedOutput.new
module Kernel
  extend Forwardable
  def_delegators :$terminal, :agree, :ask, :choose, :say, :logger_log, :logger_log
end

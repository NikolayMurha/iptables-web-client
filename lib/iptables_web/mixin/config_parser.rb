module IptablesWeb
  module Mixin
    module ConfigParser
      def parse_rules(rules)
        chains = rules.scan(/\*(filter|nat|mangle)(.*?)COMMIT/m)
        if chains && chains.size > 0
          chains.each_with_object({}) do |r, obj|
            chain = r[0]
            obj[chain] ||= []
            obj[chain] = obj[chain] + reject_comments(r[1].split("\n"))
          end
        else
          { 'filter' => reject_comments(rules.split("\n")) }
        end
      end

      def reject_comments(rules)
        rules.reject { |l| l[0]=='#' }
      end
    end
  end
end

# frozen_string_literal: true

Dir.glob("#{File.dirname(File.absolute_path(__FILE__))}/abt/*.rb").sort.each do |file|
  require file
end

# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/providers/*.rb").sort.each do |file|
  require file
end

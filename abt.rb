# frozen_string_literal: true

module Abt
  ROOT = File.dirname(File.absolute_path(__FILE__))

  def self.root
    ROOT
  end

  module Providers; end

  require_relative 'cli/cli.rb'

  Dir.glob("#{ROOT}/lib/*.rb").sort.each do |file|
    require file
  end

  Dir.glob("#{ROOT}/providers/*.rb").sort.each do |file|
    require file
  end
end

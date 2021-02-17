# frozen_string_literal: true

module Abt
  class Ari
    attr_reader :scheme, :path, :flags

    def initialize(scheme:, path: nil, flags: [])
      @scheme = scheme
      @path = path
      @flags = flags
    end

    def to_s
      str = scheme
      str += ":#{path}" if path

      [str, *flags].join(' ')
    end
  end
end

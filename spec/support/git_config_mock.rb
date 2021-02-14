# frozen_string_literal: true

class GitConfigMock < Hash
  extend Forwardable

  def_delegators(:@store, :[], :[]=, :keys)

  def initialize(data: {}, available: true)
    @store = data.dup
    @available = available
  end

  def available?
    @available
  end
end

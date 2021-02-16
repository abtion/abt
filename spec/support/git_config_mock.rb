# frozen_string_literal: true

class GitConfigMock
  extend Forwardable

  def_delegators(:@store, :[], :[]=, :empty?, :keys)

  def initialize(data: {}, available: true)
    @store = data.dup
    @available = available
  end

  def clear(**)
    @store.clear
  end

  def available?
    @available
  end
end

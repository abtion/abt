# frozen_string_literal: true

class GitConfigMock < Hash
  extend Forwardable

  def_delegators(:@store, :[], :[]=, :keys)

  def initialize(initial = {})
    @store = initial.dup
  end

  def available?
    true
  end
end

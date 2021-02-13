# frozen_string_literal: true

module NullStream
  def null_stream
    StringIO.new
  end
end

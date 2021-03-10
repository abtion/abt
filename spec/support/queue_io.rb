# frozen_string_literal: true

class QueueIO < Queue
  def history
    @history ||= +""
  end

  def puts(str)
    print("#{str}\n")
  end

  def print(str)
    history << str
    self.<< str
  end

  def isatty
    true
  end

  def gets
    pop
  end

  def to_s
    history
  end
end

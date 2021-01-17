# frozen_string_literal: true

module Abt
  class GitConfig
    attr_reader :namespace, :scope

    def self.local_available?
      @local_available ||= begin
        status = nil
        Open3.popen3('git config --local -l', chdir: '/') do |_i, _o, _e, thread|
          status = thread.value
        end
        status.success?
      end
    end

    def initialize(namespace: '', scope: 'local')
      @namespace = namespace

      unless %w[local global].include? scope
        raise ArgumentError, 'scope must be "local" or "global"'
      end

      @scope = scope
    end

    def [](key)
      get(key)
    end

    def []=(key, value)
      set(key, value)
    end

    def local
      @local ||= begin
        if scope == 'local'
          self
        else
          self.class.new(namespace: namespace, scope: 'local')
        end
      end
    end

    def global
      @global ||= begin
        if scope == 'global'
          self
        else
          self.class.new(namespace: namespace, scope: 'global')
        end
      end
    end

    private

    def key_with_namespace(key)
      namespace.empty? ? key : "#{namespace}.#{key}"
    end

    def get(key)
      if scope == 'local' && !self.class.local_available?
        raise StandardError, 'Local configuration is not available outside a git repository'
      end

      git_value = `git config --#{scope} --get #{key_with_namespace(key).inspect}`.strip
      git_value.empty? ? nil : git_value
    end

    def set(key, value)
      if scope == 'local' && !self.class.local_available?
        raise StandardError, 'Local configuration is not available outside a git repository'
      end

      if value.nil? || value.empty?
        `git config --#{scope} --unset #{key_with_namespace(key).inspect}`
        nil
      else
        `git config --#{scope} --replace-all #{key_with_namespace(key).inspect} #{value.inspect}`
        value
      end
    end
  end
end

# frozen_string_literal: true

module Abt
  class GitConfig
    attr_reader :namespace, :scope

    LOCAL_CONFIG_AVAILABLE_CHECK_COMMAND = 'git config --local -l'

    def self.local_available?
      return @local_available if instance_variables.include?(:@local_available)

      @local_available = begin
        success = false
        Open3.popen3(LOCAL_CONFIG_AVAILABLE_CHECK_COMMAND) do |_i, _o, _e, thread|
          success = thread.value.success?
        end
        success
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

    def keys
      offset = namespace.length + 1
      full_keys.map { |key| key[offset..-1] }
    end

    def full_keys
      ensure_scope_available!

      `git config --#{scope} --get-regexp --name-only ^#{namespace}`.lines.map(&:strip)
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

    def clear(output: nil)
      if namespace.empty?
        output&.puts('Keys can only be cleared within a namespace')
        return
      end

      keys.each do |key|
        output&.puts "Clearing #{scope}: #{key_with_namespace(key)}"
        self[key] = nil
      end
    end

    private

    def ensure_scope_available!
      return if scope != 'local' || self.class.local_available?

      raise StandardError, 'Local configuration is not available outside a git repository'
    end

    def key_with_namespace(key)
      namespace.empty? ? key : "#{namespace}.#{key}"
    end

    def get(key)
      ensure_scope_available!

      git_value = `git config --#{scope} --get #{key_with_namespace(key).inspect}`.strip
      git_value.empty? ? nil : git_value
    end

    def set(key, value)
      ensure_scope_available!

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

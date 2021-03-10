# frozen_string_literal: true

module Abt
  class GitConfig
    attr_reader :namespace, :scope

    class UnsafeNamespaceError < StandardError; end

    def initialize(scope = "local", namespace = "")
      @namespace = namespace

      raise ArgumentError, 'scope must be "local" or "global"' unless %w[local global].include?(scope)

      @scope = scope
    end

    def available?
      unless instance_variables.include?(:available)
        @available = begin
          success = false
          Open3.popen3(availability_check_call) do |_i, _o, _e, thread|
            success = thread.value.success?
          end
          success
        end
      end

      @available
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

    def clear(output: nil)
      raise UnsafeNamespaceError, "Keys can only be cleared within a namespace" if namespace.empty?

      keys.each do |key|
        output&.puts "Clearing #{scope}: #{key_with_namespace(key)}"
        self[key] = nil
      end
    end

    private

    def availability_check_call
      "git config --#{scope} -l"
    end

    def ensure_scope_available!
      return if available?

      raise StandardError, "Local configuration is not available outside a git repository"
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

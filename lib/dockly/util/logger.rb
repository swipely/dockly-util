class Dockly::Util::Logger
  attr_accessor :prefix, :print_method, :output
  alias_method :print_method?, :print_method

  LEVELS = [:debug, :info, :warn, :error, :fatal, :unknown].freeze

  def initialize(prefix = "", output = Dockly::Util::Logger.output, print_method = Dockly::Util::Logger.print_method)
    @prefix = prefix
    @print_method = print_method
    @output = output
  end

  def log(level, message)
    output.puts(format_message(level, message)) if self.class.enabled?
  end

  LEVELS.each do |level|
    define_method(level) { |message| log(level, message) }
  end

  def format_message(level, message)
    [
      format_level(level),
      Time.now.iso8601,
      Process.pid.to_s,
      Thread.current.object_id.to_s,
      Thread.current[:rake_task].to_s,
      prefix,
      get_last_method,
      message
    ].compact.reject(&:empty?).join(' ')
  end

  def format_level(level)
    (char = level.to_s[0]) ? char.upcase : nil
  end

  def get_last_method
    if print_method?
      file_and_method = caller.reject { |trace| trace =~ /dockly\/util\/logger\.rb|block \(\d+ levels\)/ }.first
      file_and_method.match(/:in `(.+)'$/)[1]
    end
  end

  def with_prefix(new_prefix = "", output = nil, print_method = nil)
    output ||= self.output
    print_method ||= self.print_method
    yield(self.class.new([prefix, new_prefix].compact.reject(&:empty?).join(' '), output, print_method))
  end

  module Mixin
    extend Dockly::Util::Delegate

    def self.included(base)
      base.extend(ClassMethods)
    end

    def logger
      @logger ||= Dockly::Util::Logger.new(self.class.logger_prefix)
    end

    delegate(*(LEVELS + [:log, :with_prefix]), :to => :logger)

    module ClassMethods
      def logger_prefix(val = nil)
        val.nil? ? (@logger_prefix ||= self.name) : (@logger_prefix = val)
      end
    end
  end


  class << self
    include Mixin

    alias_method :default, :logger
    attr_writer :print_method, :output

    def disable!
      @logger_enabled = false
    end

    def enable!
      @logger_enabled = true
    end

    def enabled?
      enable! if @logger_enabled.nil?
      @logger_enabled
    end

    def print_method
      (@print_method == false) ? false : true
    end

    def output
      @output ||= STDOUT
    end
  end
end

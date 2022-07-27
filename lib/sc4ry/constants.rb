# frozen_string_literal: true

# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry::Constants module
  # @note namespace
  module Constants
    # notifiers available in Sc4ry natively
    CURRENT_NOTIFIERS = %i[prometheus mattermost]

    # the Sc4ry default config entries and values
    DEFAULT_CONFIG = {
      max_failure_count: 5,
      timeout_value: 20,
      timeout: false,
      max_timeout_count: 5,
      max_time: 10,
      max_overtime_count: 3,
      check_delay: 30,
      notifiers: [],
      forward_unknown_exceptions: true,
      raise_on_opening: false,
      exceptions: [StandardError, RuntimeError]
    }

    # Default config supported entries with format and Proc checker for {Sc4ry::Config::Validator}
    DEFAULT_CONFIG_FORMATS = {
      max_failure_count: { proc: proc { |item| item.instance_of?(Integer) }, desc: 'must be an Integer' },
      timeout_value: { proc: proc { |item| item.instance_of?(Integer) }, desc: 'must be an Integer' },
      timeout: { proc: proc { |item| [true, false].include? item }, desc: 'must be a Boolean' },
      max_timeout_count: { proc: proc { |item| item.instance_of?(Integer) }, desc: 'must be an Integer' },
      max_time: { proc: proc { |item| item.instance_of?(Integer) }, desc: 'must be an Integer' },
      max_overtime_count: { proc: proc { |item| item.instance_of?(Integer) }, desc: 'must be an Integer' },
      check_delay: { proc: proc { |item| item.instance_of?(Integer) }, desc: 'must be an Integer' },
      notifiers: {
        proc: proc do |item|
                item.instance_of?(Array) and item.select { |val| val.instance_of?(Symbol) }.size == item.size
              end,
        desc: 'must be an Array of Symbol',
        list: CURRENT_NOTIFIERS
      },
      forward_unknown_exceptions: { proc: proc { |item| [true, false].include? item }, desc: 'must be a Boolean' },
      raise_on_opening: { proc: proc { |item| [true, false].include? item }, desc: 'must be a Boolean' },
      exceptions: {
        proc: proc do |item|
                item.instance_of?(Array) and item.select do |val|
                  [Class, String].include? val.class
                end.size == item.size
              end,
        desc: 'must be an Array of Exception(Class) or String'
      }
    }
  end
end

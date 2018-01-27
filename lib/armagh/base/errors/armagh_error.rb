# Copyright 2018 Noragh Analytics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

Dir[File.join(__dir__, "notifiers", "*.rb")].each { |file| require file }

class ArmaghError < StandardError
  class NotifierNotFoundError < StandardError; end
  class InvalidArgument       < StandardError; end

  NOTIFIER_SUFFIX = "Notifier"

  attr_reader :notifiers

  def initialize(msg = nil)
    super(msg)

    @notifiers = [class_notifiers + superclass_notifiers].flatten.uniq
  end

  def notify(calling_action = nil)
    notifiers.each { |n| n.new.notify(calling_action, self) }
  end

  # allows objects to properly respond to methods like
  # #notify_dev, #notify_ops, etc
  # so that we can selectively notify endpoints
  # even if multiple notifiers are defined
  def method_missing(meth, *args)
    notifier_name  = meth.to_s.split("_").last.capitalize + NOTIFIER_SUFFIX
    if defined_notifier?(notifier_name)
      notifier = Object.const_get(notifier_name)
      calling_action = args.first
      notifier.new.notify(calling_action, self)
    else
      super
    end
  end

  private def defined_notifier?(name)
    defined_notifiers_list = self.class.defined_notifiers.map(&:to_s)
    defined_notifiers_list.include?(name)
  end

  private def class_notifiers
    self.class.notifiers
  end

  private def superclass_notifiers
    if self.class.superclass <= ArmaghError && self.class != ArmaghError
      self.class.superclass.notifiers
    else
      []
    end
  end

  class << self

    def notifiers
      @notifiers ||= []
    end

    def notifies(*args)
      raise InvalidArgument.new("Arguments to .notifies method should be symbols") unless args.all? { |arg| arg.is_a?(Symbol)}

      if args == [:none]
        remove_notifiers
      else
        add_notifiers_from_args(args)
      end

      notifiers
    end

    # KN: could find defined notifiers this way,
    # or by looking for files in a certain directory,
    # which might be better
    def defined_notifiers
      Module.constants.select {|c| c.match /\w+Notifier/ }.map { |c| Object.const_get(c) }
    end

    private

    def remove_notifiers
      @notifiers = []
    end

    def add_notifiers_from_args(args)
      args.each do |sym|
        begin
          notifier = Object.const_get(sym.to_s.capitalize + ArmaghError::NOTIFIER_SUFFIX)
          add_notifier(notifier)
        rescue NameError => e
          raise NotifierNotFoundError
        end
      end
    end

    def add_notifier(notifier)
      return nil unless defined_notifiers.include?(notifier)

      notifiers << notifier unless notifiers.include?(notifier)
    end

  end
end

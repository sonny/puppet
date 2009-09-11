require 'puppet/indirector'

# Provide status information.  Currently acts as a ping.
class Puppet::Status
  extend Puppet::Indirector

  indirects :status, :terminus_class => :processor

  def not_on_fire?
    true
  end

  module Puppet::Indirector
    module ClassMethods
      # override the included find to allow calling
      # with no args
      def find(*args)
        args = ["status"] unless args.length > 0
        indirection.find(*args)
      end
    end
  end
end

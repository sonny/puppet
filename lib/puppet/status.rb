require 'puppet/indirector'

# Provide status information.  Currently acts as a ping.
class Puppet::Status
  extend Puppet::Indirector

  indirects :status, :terminus_class => :processor

  def alive?
    true
  end

  def to_json
    {:alive => alive?}.to_json
  end

  # wrap included Puppet::Indirectory#find to allow 
  # calling with no args
  class << self
    alias_method :indirected_find, :find
    def find(*args)
      args = ["status"] unless args.length > 0
      indirected_find(*args)
    end
  end
end

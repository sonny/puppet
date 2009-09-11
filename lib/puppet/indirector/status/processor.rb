require 'puppet/indirector/code'
require 'puppet/status'

# Return the server status
class Puppet::Status::Processor < Puppet::Indirector::Code
    desc "Return the server status"

    def find(request)
      indirection.model.new
    end

end

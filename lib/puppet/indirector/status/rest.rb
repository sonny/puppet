require 'puppet/status'
require 'puppet/indirector/rest'

class Puppet::Status::Rest < Puppet::Indirector::REST
    desc "Find the server Status over HTTP via REST."
end

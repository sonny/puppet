#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

require 'puppet/status'

describe Puppet::Status do
    before do
        @class = Puppet::Status
    end

    it "should be extended with the Indirector module" do
        @class.metaclass.should be_include(Puppet::Indirector)
    end

    it "should indirect status" do 
        @class.indirection.name.should == :status
    end

    it "should not be on fire" do
       @class.new.not_on_fire?.should == true
    end
end

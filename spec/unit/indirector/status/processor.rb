#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/indirector/status/processor'

describe Puppet::Status::Processor do
    before do
      @searcher = Puppet::Status::Processor.new
    end
    describe "Find a status object" do
        before do
            @result = @searcher.find("thunk")
        end

        it "should return a status object" do
            @result.class.should == Puppet::Status
        end

        it "should not be on fire" do
            @result.not_on_fire?.should be_true
        end
    end
end

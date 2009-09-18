#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

describe "puppetmasterd" do
    before (:all) do
        @serial_t = Tempfile.open("puppetmaster_integration_testing_serial")
        @serial = @serial_t.path
        @serial_t << ("%04X" % rand(1000000))
        @serial_t.close
    end
  
    after (:all) do
        @serial_t.delete
    end

    before do
        # Get a safe temporary file
        file = Tempfile.new("puppetmaster_integration_testing")
        @dir = file.path
        file.delete

        Dir.mkdir(@dir)

        Puppet.settings[:confdir] = @dir
        Puppet.settings[:vardir] = @dir
        Puppet[:certdnsnames] = "localhost"
        Puppet[:serial] = @serial
        @@port = 12345

        @orig_masterport = Puppet[:masterport]
        @orig_server = Puppet[:server]
    end

    after {
        stop
        Puppet[:masterport] = @orig_masterport
        Puppet[:server] = @orig_server

        Puppet::SSL::Host.ca_location = :none

        system("rm -rf %s" % @dir)
        Puppet.settings.clear
    }

    def arguments
        rundir = File.join(Puppet[:vardir], "run")
        @pidfile = File.join(rundir, "testing.pid")
        args = ""
        args += " --confdir %s" % Puppet[:confdir]
        args += " --rundir %s" % rundir
        args += " --pidfile %s" % @pidfile
        args += " --vardir %s" % Puppet[:vardir]
        args += " --certdnsnames %s" % Puppet[:certdnsnames]
        args += " --masterport %s" % @@port
        args += " --user %s" % Puppet::Util::SUIDManager.uid
        args += " --group %s" % Puppet::Util::SUIDManager.gid
        args += " --autosign true"
        args += " --serial %s" % @serial
    end

    def start(addl_args = "")
        Puppet.settings.mkdir(:manifestdir)
        Puppet.settings.write(:manifest) do |f|
            f.puts { "notify { testing: }" }
        end

        args = arguments + addl_args

        bin = File.join(File.dirname(__FILE__), "..", "..", "..", "sbin", "puppetmasterd")
        output = %x{#{bin} #{args}}.chomp
    end

    def stop
        if @pidfile and FileTest.exist?(@pidfile)
            pid = File.read(@pidfile).chomp.to_i
            Process.kill(:TERM, pid)
        end
    end

    it "should create a PID file" do
        start

        FileTest.exist?(@pidfile).should be_true
    end

    it "should be serving status information over REST" do
      start
      sleep 5
      
      Puppet[:masterport] = @@port 
      Puppet[:server] = "localhost"

      FileUtils.mkdir_p(File.dirname(Puppet.settings[:rest_authconfig]))
      File.open(Puppet.settings[:rest_authconfig], "w") { |f|
        f.puts "path /\nallow *\n"
      }

      Puppet::Status.terminus_class = :rest
      result = Puppet::Status.find
      result.not_on_fire?.should be_true
    end

    it "should be serving status information over xmlrpc" do
        start

        sleep 5

        client = Puppet::Network::Client.status.new(:Server => "localhost", :Port => @@port)

        FileUtils.mkdir_p(File.dirname(Puppet[:autosign]))
        File.open(Puppet[:autosign], "w") { |f|
            f.puts Puppet[:certname]
        }

        client.cert
        retval = client.status

        retval.should == 1
    end

    it "should exit with return code 0 after parsing if --parseonly is set and there are no errors" do
        start(" --parseonly > /dev/null")
        sleep(1)

        ps = Facter["ps"].value || "ps -ef"
        pid = nil
        %x{#{ps}}.chomp.split(/\n/).each { |line|
            next if line =~ /^puppet/ # skip normal master procs
            if line =~ /puppetmasterd.+--manifest/
                ary = line.split(" ")
                pid = ary[1].to_i
            end
        }

        $?.should == 0

        pid.should be_nil
    end

    it "should exit with return code 1 after parsing if --parseonly is set and there are errors"
end

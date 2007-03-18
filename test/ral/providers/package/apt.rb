#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../lib/puppettest'

require 'mocha'

class AptPackageProviderTest < PuppetTest::TestCase
    confine "Apt package provider missing" =>
        Puppet::Type.type(:package).provider(:apt).suitable?

	def setup
        super
		@type = Puppet::Type.type(:package)
	end
	
	def test_install
		pkg = @type.create :name => 'faff',
		                   :provider => :apt,
		                   :ensure => :present,
		                   :source => "/tmp/faff.deb"

		pkg.provider.expects(
		                 :dpkgquery
					  ).with(
							  '-W',
							  '--showformat',
							  '${Status} ${Package} ${Version}\n',
							  'faff'
					  ).returns(
					        "deinstall ok config-files faff 1.2.3-1\n"
					  )

		pkg.provider.expects(
		                 :aptget
		           ).with(
		                 '-q',
		                 '-y',
		                 '-o',
		                 'DPkg::Options::=--force-confold',
		                 'install',
		                 'faff'
					  ).returns(0)
		
		pkg.evaluate.each { |state| state.transaction = self; state.forward }
	end
	
	def test_purge
		pkg = @type.create :name => 'faff', :provider => :apt, :ensure => :purged

		pkg.provider.expects(
		                 :dpkgquery
					  ).with(
					        '-W',
					        '--showformat',
					        '${Status} ${Package} ${Version}\n',
					        'faff'
					  ).returns(
					        "install ok installed faff 1.2.3-1\n"
					  )
		pkg.provider.expects(
		                 :aptget
					  ).with(
					        '-y',
					        '-q',
					        'remove',
					        '--purge',
					        'faff'
					  ).returns(0)
		
		pkg.evaluate.each { |state| state.transaction = self; state.forward }
	end
end
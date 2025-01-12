# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

module Cucumber
  module Cli
    describe ProfileLoader do
      let(:loader) { ProfileLoader.new }

      def given_cucumber_yml_defined_as(hash_or_string)
        allow(Dir).to receive(:glob).with('{,.config/,config/}cucumber{.yml,.yaml}') { ['cucumber.yml'] }
        allow(File).to receive(:exist?) { true }
        cucumber_yml = hash_or_string.is_a?(Hash) ? hash_or_string.to_yaml : hash_or_string
        allow(IO).to receive(:read).with('cucumber.yml') { cucumber_yml }
      end

      context 'when on a Windows OS' do
        before { skip('Only run these tests on non-Windows') unless Cucumber::WINDOWS }

        it 'treats backslashes as literals in rerun.txt when on Windows (JRuby or MRI)' do
          given_cucumber_yml_defined_as('default' => '--format "pretty" features\sync_imap_mailbox.feature:16:22')

          expect(loader.args_from('default')).to eq(['--format', 'pretty', 'features\sync_imap_mailbox.feature:16:22'])
        end

        it 'treats forward slashes as literals' do
          given_cucumber_yml_defined_as('default' => '--format "ugly" features/sync_imap_mailbox.feature:16:22')

          expect(loader.args_from('default')).to eq ['--format', 'ugly', 'features/sync_imap_mailbox.feature:16:22']
        end

        it 'treats percent sign as ERB code block after YAML directive' do
          yml = <<~HERE
          ---
          % x = '--format "pretty" features/sync_imap_mailbox.feature:16:22'
          default: <%= x %>
        HERE
          given_cucumber_yml_defined_as yml
          expect(loader.args_from('default')).to eq ['--format', 'pretty', 'features/sync_imap_mailbox.feature:16:22']
        end

        it 'correctly parses a profile that uses tag expressions (with double quotes)' do
          given_cucumber_yml_defined_as('default' => '--format "pretty" features\sync_imap_mailbox.feature:16:22 --tags "not @jruby"')

          expect(loader.args_from('default')).to eq ['--format', 'pretty', 'features\sync_imap_mailbox.feature:16:22', '--tags', 'not @jruby']
        end

        it 'correctly parses a profile that uses tag expressions (with single quotes)' do
          given_cucumber_yml_defined_as('default' => "--format 'pretty' features\\sync_imap_mailbox.feature:16:22 --tags 'not @jruby'")

          expect(loader.args_from('default')).to eq ['--format', 'pretty', 'features\sync_imap_mailbox.feature:16:22', '--tags', 'not @jruby']
        end
      end

      context 'when on non-Windows OS' do
        before { skip('Only run these tests on non-Windows') if Cucumber::WINDOWS }

        it 'treats backslashes as literals in rerun.txt when on Windows (JRuby or MRI)' do
          given_cucumber_yml_defined_as('default' => '--format "pretty" features\sync_imap_mailbox.feature:16:22')

          expect(loader.args_from('default')).to eq(['--format', 'pretty', 'featuressync_imap_mailbox.feature:16:22'])
        end

        it 'treats forward slashes as literals' do
          given_cucumber_yml_defined_as('default' => '--format "ugly" features/sync_imap_mailbox.feature:16:22')

          expect(loader.args_from('default')).to eq ['--format', 'ugly', 'features/sync_imap_mailbox.feature:16:22']
        end

        it 'treats percent sign as ERB code block after YAML directive' do
          yml = <<~HERE
          ---
          % x = '--format "pretty" features/sync_imap_mailbox.feature:16:22'
          default: <%= x %>
        HERE
          given_cucumber_yml_defined_as yml
          expect(loader.args_from('default')).to eq ['--format', 'pretty', 'features/sync_imap_mailbox.feature:16:22']
        end

        it 'correctly parses a profile that uses tag expressions (with double quotes)' do
          given_cucumber_yml_defined_as('default' => '--format "pretty" features\sync_imap_mailbox.feature:16:22 --tags "not @jruby"')

          expect(loader.args_from('default')).to eq ['--format', 'pretty', 'featuressync_imap_mailbox.feature:16:22', '--tags', 'not @jruby']
        end

        it 'correctly parses a profile that uses tag expressions (with single quotes)' do
          given_cucumber_yml_defined_as('default' => "--format 'pretty' features\\sync_imap_mailbox.feature:16:22 --tags 'not @jruby'")

          expect(loader.args_from('default')).to eq ['--format', 'pretty', 'featuressync_imap_mailbox.feature:16:22', '--tags', 'not @jruby']
        end
      end
    end
  end
end

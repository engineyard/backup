# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)
#require 'ey-core'

module Backup
  describe Storage::EngineYard do
    before do
      Ey::Core::Client.reset!
      Ey::Core::Client.mock!
    end

    let(:model) { Model.new(:test_trigger, 'test label') }
    let(:storage) { Storage::EngineYard.new(model) }
    let(:s) { sequence '' }

    let(:core_api_url) { "http://api-backup.engineyard.localdev.com" }
    let(:token) { Ey::Core::Client::Mock.for(:server).token }

    # There are no specs here because the existing storage specs
    # mock everything including the S3 interactions.
    # We've tested the Engine Yard storage backend manually.
    it_behaves_like 'a subclass of Storage::Base' do
      let(:cycling_supported) { true }
    end

    around(:each) do |example|
      begin
        files = model.package.filenames.map { |f| File.write(File.join(Config.tmp_path, f), "!515") }
        example.run
      ensure
        files.each { |f| FileUtils.remove_entry_secure(f) }
      end
    end

    describe '#connection' do
      let(:connection)   { mock }

      before do
        storage.instance_token = token
        storage.core_api_url = core_api_url
      end

      it 'yields a connection to the remote server' do
        Ey::Core::Client.expects(:new).with(
          :token  => token,
          :url    => core_api_url,
          :logger => nil,
        ).yields(connection)

        storage.send(:connection) do |ey|
          expect( ey ).to be connection
        end
      end

      it 'does not blow up when not mocked' do
        expect {
          storage.send(:connection)
        }.not_to raise_error
      end
    end # describe '#connection'

    describe '#transfer!' do
      before do
        storage.instance_token = token
      end

      it 'transfers the package files' do
        expect {
          storage.send(:transfer!)
        }.not_to raise_error
      end
    end # describe '#transfer!'
  end
end


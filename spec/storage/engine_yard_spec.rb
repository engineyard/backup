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

    # There are no specs here because the existing storage specs
    # mock everything including the S3 interactions.
    # We've tested the Engine Yard storage backend manually.
    it_behaves_like 'a class that includes Configuration::Helpers'
    it_behaves_like 'a subclass of Storage::Base' do
      let(:cycling_supported) { true }
    end

    describe '#connection' do
      let(:connection) { mock }

      before do
        storage.instance_token = 'my_token'
        storage.core_api_url = 'my_url'
      end

      it 'yields a connection to the remote server' do
        Ey::Core::Client.expects(:new).with(
          :token  => 'my_token',
          :url    => 'my_url',
          :logger    => nil,
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
        storage.instance_token = "0942fee6-6f3d-4d15-bb6f-30672b9de576"
      end

      it 'transfers the package files' do
        pending "need core work"
        expect {
          storage.send(:transfer!)
        }.not_to raise_error
      end
    end # describe '#transfer!'
  end
end


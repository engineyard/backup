# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)
#require 'ey-core'

module Backup
  describe Storage::EngineYard do
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
        storage.send(:connection)
      end
    end # describe '#connection'
  end
end


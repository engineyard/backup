# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)
require 'ey-core'

module Backup
  describe Storage::EngineYard do
    let(:model) { Model.new(:test_trigger, 'test label') }
    let(:storage) { Storage::EngineYard.new(model) }
    let(:s) { sequence '' }

    it_behaves_like 'a class that includes Configuration::Helpers'
    it_behaves_like 'a subclass of Storage::Base' do
      let(:cycling_supported) { true }
    end
  end
end


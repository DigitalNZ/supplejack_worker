# frozen_string_literal: true
require 'rails_helper'

describe Snippet do
  let(:snippet) { Snippet.new(name: 'Copyright') }

  describe '.find_by_name' do
    it 'finds the snippet' do
      allow(Snippet).to receive(:find) { snippet }
      Snippet.find_by_name('Copyright', :staging).should eq snippet
    end

    it 'returns nil when a error is raised' do
      Snippet.stub(:find).and_raise(ArgumentError)
      Snippet.find_by_name('dsfsd', :staging).should be_nil
    end
  end
end

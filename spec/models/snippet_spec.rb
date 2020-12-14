# frozen_string_literal: true

require 'rails_helper'

describe Snippet do
  let(:snippet) { Snippet.new(name: 'Copyright') }

  describe '.find_by_name' do
    it 'finds the snippet' do
      allow(Snippet).to receive(:find) { snippet }
      expect(Snippet.find_by_name('Copyright', :staging)).to eq snippet
    end

    it 'returns nil when a error is raised' do
      allow(Snippet).to receive(:find).and_raise(ArgumentError)
      expect(Snippet.find_by_name('dsfsd', :staging)).to be_nil
    end
  end
end

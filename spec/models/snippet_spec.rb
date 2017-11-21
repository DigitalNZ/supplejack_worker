# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe Snippet do
  let(:snippet) { Snippet.new(name: 'Copyright') }

  describe '.find_by_name' do
    it 'finds the snippet' do
      Snippet.should_receive(:find).with(:one, from: :current_version, params: { name: 'Copyright', environment: :staging }) { snippet }
      Snippet.find_by_name('Copyright', :staging).should eq snippet
    end

    it 'returns nil when a error is raised' do
      Snippet.stub(:find).and_raise(ArgumentError)
      Snippet.find_by_name('dsfsd', :staging).should be_nil
    end
  end
end

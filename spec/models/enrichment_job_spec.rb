# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe EnrichmentJob do

  let(:job) { FactoryBot.create(:harvest_job, parser_id: '12345', version_id: '666', user_id: '1', environment: 'staging') }

  context 'validations' do
    it 'should not be possible to have 2 active jobs for the same enrichment/parser/environment' do
      job1 = FactoryBot.create(:enrichment_job, enrichment: 'duplicate_enrichment', parser_id: '333', environment: 'staging', status: 'active')
      job2 = FactoryBot.build(:enrichment_job, enrichment: 'duplicate_enrichment', parser_id: '333', environment: 'staging', status: 'active')
      job2.should_not be_valid
    end

    it 'should be possible to have 2 finished jobs for the same enrichment/parser/environment' do
      job1 = FactoryBot.create(:enrichment_job, enrichment: 'duplicate_relationships', parser_id: '333', environment: 'staging', status: 'finished')
      job2 = FactoryBot.build(:enrichment_job, enrichment: 'duplicate_relationships', parser_id: '333', environment: 'staging', status: 'finished')
      job2.should be_valid
    end

    it 'should be possible to have 2 active jobs with the same parser/environment' do
      job1 = FactoryBot.create(:enrichment_job, enrichment: 'duplicate_relationships', parser_id: '333', environment: 'staging', status: 'active')
      job2 = FactoryBot.build(:enrichment_job, enrichment: 'duplicate_denormalization', parser_id: '333', environment: 'staging', status: 'active')
      job2.should be_valid
    end
  end

  describe '.create_from_harvest_job' do

    subject { EnrichmentJob.create_from_harvest_job(job, :ndha_rights) }

    it 'inherits values from harvest job' do
      expect(subject.parser_id).to eq '12345'
      expect(subject.version_id).to eq '666'
      expect(subject.user_id).to eq '1'
      expect(subject.environment).to eq 'staging'
      expect(subject.harvest_job_id).to eq job.id
      expect(subject.enrichment).to eq 'ndha_rights'
    end
  end

  describe '#enqueue' do
    it 'should enqueue a EnrichmentWorker' do
      EnrichmentWorker.should_receive(:perform_async)
      EnrichmentJob.create_from_harvest_job(job, :ndha_rights)
    end
  end

  context 'preview environment' do

    before {job.environment = 'preview'}

    it 'does not enque a job after create' do
      EnrichmentWorker.should_not_receive(:perform_async)
      EnrichmentJob.create_from_harvest_job(job, :ndha_rights)
    end
  end
end

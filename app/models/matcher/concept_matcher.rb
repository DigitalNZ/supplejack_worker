# frozen_string_literal: true

# app/models/matcher/
module Matcher
  # :nodoc:
  module ConceptMatcher
    def create_concept?(args = {})
      Sidekiq.logger.info "Inside create_concept? with #{args.inspect}"
      if args[:givenName].blank? || args[:familyName].blank? ||
         args[:dateOfBirth].blank? || args[:dateOfDeath].blank? ||
         args[:internal_identifier].blank? || args[:match_concepts].blank? || args[:source_id].blank?

        Sidekiq.logger.warn "ConceptMatcher didn't receieve required attributes, not performing matching or creating concept"
        Sidekiq.logger.info "ConceptMatcher attributes receieved: #{args.inspect}"
        return false
      end

      multi_value_fields = %i[name isRelatedTo hasMet sameAs]
      args = args.dup
      args = args.each do |arg, value|
        unless multi_value_fields.include?(arg.to_sym)
          args[arg] = Array(value).first
        end
      end

      case args[:match_concepts]
      when :create_or_match
        return !lookup(args)
      when :create
        return true
      when :match
        lookup(args)
        return false
      end
    end

    private

    def lookup(args)
      query = SupplejackApi::Concept
              .where('fragments.givenName' => args[:givenName])
              .where('fragments.familyName' => args[:familyName])
              .where(:'fragments.dateOfBirth'.gte => args[:dateOfBirth].beginning_of_year)
              .where(:'fragments.dateOfBirth'.lt => args[:dateOfBirth].end_of_year)
              .where(:'fragments.dateOfDeath'.gte => args[:dateOfDeath].beginning_of_year)
              .where(:'fragments.dateOfDeath'.lt => args[:dateOfDeath].end_of_year)

      if (concept = query.first)
        if concept.primary.source_id != args[:source_id]
          Sidekiq.logger.info "ConceptMatcher found match for #{args[:givenName]} #{args[:familyName]}"

          post_attributes = {
            internal_identifier: concept.internal_identifier,
            source_id: args[:source_id],
            sameAs: args[:sameAs],
            match_status: 'strong'
          }

          ApiUpdateWorker.perform_async('/harvester/concepts.json', { concept: post_attributes }, args[:job_id])
          return true
        end
      end
    end
  end
end

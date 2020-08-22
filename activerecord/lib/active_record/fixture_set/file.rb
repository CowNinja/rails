# frozen_string_literal: true

require "active_support/configuration_file"

module ActiveRecord
  class FixtureSet
    class File # :nodoc:
      attr_reader :rows, :model_class

      class << self
        def load_from(directory)
          loadable_paths_from(directory).map { |path| new(path) }
        end

        private
          def loadable_paths_from(directory)
            Dir["#{directory}/{**,*}/*.yml"].select { |f| ::File.file?(f) } | [ "#{directory}.yml" ]
          end
      end

      def initialize(file)
        rows = parse_rows_from(file)
        @model_class, ignored_fixtures = rows.delete("_fixture")&.values_at("model_class", "ignore")
        @rows = rows.except "DEFAULTS", *ignored_fixtures
      end

      private
        def parse_rows_from(file)
          ActiveSupport::ConfigurationFile.parse(file, context: new_render_context, row_type: Hash)
        rescue ActiveSupport::ConfigurationFile::FormatError
          raise Fixture::FormatError, $!
        end

        def new_render_context
          ActiveRecord::FixtureSet::RenderContext.create_subclass.new.get_binding
        end
    end
  end
end

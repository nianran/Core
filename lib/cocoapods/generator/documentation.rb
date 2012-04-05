
module Pod
  module Generator

    class Documentation
      include Config::Mixin
      extend Executable

      executable :appledoc
      attr_reader :pod, :specification, :target_path, :options

      def initialize(pod)
        @pod = pod
        @specification = pod.specification
        @target_path = pod.sandbox.root + 'Documentation' + pod.name
        @options = pod.specification.documentation || {}
      end

      def name
        @specification.name + ' ' + @specification.version.to_s
      end

      def company
        if @specification.authors
          @specification.authors.keys.sort.join(', ')
        else
          'no-company'
        end
      end

      def copyright
        company
      end

      def description
        @specification.description || 'Generated by CocoaPods.'
      end

      def docs_id
        'org.cocoapods'
      end

      def files
        @pod.absolute_source_files.map(&:to_s)
      end

      def index_file
        @pod.chdir do
          Dir.glob('README*', File::FNM_CASEFOLD).first
        end
      end

      def spec_appledoc_options
        @options[:appledoc] || []
      end

      def appledoc_options
        options = ['--project-name', name,
                   '--docset-desc', description,
                   '--project-company', company,
                   '--docset-copyright', copyright,
                   '--company-id', docs_id,
                   '--ignore', '.m',
                   '--keep-undocumented-objects',
                   '--keep-undocumented-members']
        index = index_file
        options += ['--index-desc', index] if index
        options += spec_appledoc_options
        options += ['--output', @target_path.to_s]
        options += ['--keep-intermediate-files']
      end

      def generate(install = false)
        options = appledoc_options
        options += install ? ['--create-docset'] : ['--no-create-docset']
        options += files
        options.map!{|s| s !~ /--.*|".*"/ ? %Q["#{s}"] : s }
        @target_path.mkpath
        @pod.chdir do
          appledoc options.join(' ')
        end
      rescue Exception => e
        if e.is_a?(Informative)
          puts "[!] Skipping documentation generation because appledoc can't be found." if config.verbose?
        else
          throw e
        end
      end
    end
  end
end
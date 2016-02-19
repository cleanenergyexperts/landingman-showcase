# Require core library
require 'middleman-core'
require 'pathname'

module Landingman
  class ShowcaseExtension < ::Middleman::Extension
    EXTENSION_TEMPLATES_DIR = File.expand_path(File.join('..', '..', 'templates'), __FILE__)
    option :template_path, 'templates/**/*.html.*', 'A String or Array of String glob-able paths to templates.'
    option :template_locals, {}, 'Hash of locals to provide templates, serves as a set of defaults'
    option :showcase_path, 'showcase/', 'URL Path for the showcase'
    expose_to_template :template_resources

    def initialize(app, options_hash={}, &block)
      super
    end

    def after_configuration
      self.register_extension_templates
    end

    def template_resources
      @template_resources ||= self.relative_template_paths.map do |template_path|
        build_resource(template_path)
      end
    end

    def manipulate_resource_list(resources)
      tresources = self.template_resources
      iresource  = self.showcase_index_resource(tresources)
      resources + tresources + [iresource]
    end

    protected

      def showcase_index_resource(resources)
        source_file = template('showcase.html.erb')
        ::Middleman::Sitemap::Resource.new(app.sitemap, "#{showcase_path}/index.html", source_file).tap do |resource|
          resource.add_metadata(options: { layout: false }, locals: {})
        end
      end

      def template(path)
        full_path = File.join(EXTENSION_TEMPLATES_DIR, path)
        raise "Template #{full_path} not found" if !File.exist?(full_path)
        full_path
      end

      def build_resource(template_path)
        locals = options.template_locals || {}
        locals[:template_name] = self.build_template_name(template_path)

        tpath = self.build_template_path(template_path)
        url_path = self.build_template_url(template_path)
        ::Middleman::Sitemap::ProxyResource.new(app.sitemap, url_path, tpath).tap do |page|
          page.add_metadata locals: locals
        end
      end

      def showcase_path
        options.showcase_path.chomp('/')
      end

      def build_template_path(template_path)
        ext = File.extname(template_path)
        if ext.nil? || ext.empty? || ext.downcase == '.html' then
          template_path
        else
          template_path.chomp(ext)
        end
      end

      def build_template_url(template_path)
        # strip extensions
        # prefix with /showcase/
        # postfix with /index.html
        # tag with git commit
        raw_path = template_path.chomp(File.extname(template_path)).chomp('.html')
        "#{showcase_path}/#{raw_path}/index.html"
      end

      def build_template_name(template_path)
        template_path.chomp(File.extname(template_path)).chomp('.html')
      end

      def git_ref
        @git_ref ||= `git rev-list --max-count=1 HEAD`
      end

      def source_relative_path(path)
        Pathname.new(path).relative_path_from(app.source_dir)
      end

      def relative_template_paths
        template_paths = []
        if options.template_path.is_a? String then
          template_paths << options.template_path
        else
          template_paths += options.template_path
        end

        source_dir = app.source_dir
        template_paths.map do |template_path|
          Dir.glob(File.expand_path(File.join(source_dir, template_path))).map do |template_file|
            template_pathname = Pathname.new(template_file)
            template_pathname.relative_path_from(source_dir).to_s
          end
        end.flatten.compact.uniq
      end

      def register_extension_templates
        # We call reload_path to register the templates directory with Middleman.
        # The path given to app.files must be relative to the Middleman site's root.
        templates_dir_relative_from_root = Pathname(EXTENSION_TEMPLATES_DIR).relative_path_from(Pathname(app.root)).to_s
        # type: source or file
        if !templates_dir_relative_from_root.nil? && Dir.exists?(templates_dir_relative_from_root) then
          app.files.watch(:source, { path: templates_dir_relative_from_root })
        end
      end

  end
end
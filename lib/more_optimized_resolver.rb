require "more_optimized_resolver/version"
require 'action_view'
require 'action_view/template/resolver'

module MoreOptimizedResolver
  module Methods
    def initialize(*)
      super
      @filenames_cache = []
    end

    def find_template_paths(queries)
      query, query2 = queries
      return super(query) if @path.nil? || (!File.directory?(@path)) || (@path == '/') || !query2

      if @filenames_cache.empty?
        @filenames_cache = Dir[@path + '/**/*.*'].reject {|fn| File.directory? fn}
      end

      #NOTE this doesn't support case-insensitive file systems.
      path, exts = query2

      exts_pattern = exts.map {|ext| "(#{ext.map {|e| "(#{Regexp.escape(e)})"}.join('|')})?"}.join

      pattern = Regexp.new("#{path}#{exts_pattern}$")
      filenames = @filenames_cache.grep(pattern)
      filenames.sort_by! do |fn|
        exts.map do |e|
          e.index {|ext| fn.include? ext} || e.size
        end
      end
    end

    def build_query(path, details)
      query1 = super

      query = escape_entry(File.join(@path, path))
      exts2 = ActionView::PathResolver::EXTENSIONS.map do |ext, prefix|
        details[ext].compact.uniq.map {|e| "#{prefix}#{e}"}
      end

      [query1, [query, exts2]]
    end
  end
end

::ActionView::OptimizedFileSystemResolver.prepend MoreOptimizedResolver::Methods

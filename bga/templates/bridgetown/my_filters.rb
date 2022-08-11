class Builders::MyFilters < SiteBuilder
  def build
    liquid_filter :css_relative_path do |url|
      els = url.split( '/')
      els = (els.size > 1) ? els[1..-1] : []
      els.collect {'../'}.join( '') + 'index.css'
    end
  end
end
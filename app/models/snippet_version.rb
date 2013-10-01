class SnippetVersion < ActiveResource::Base

  self.site = ENV['MANAGER_HOST'] + "/snippets/:snippet_id/"
  self.user = ENV['MANAGER_API_KEY']
  self.element_name = "version"

  def snippet_id
    @attributes[:snippet_id] || @prefix_options[:snippet_id]
  end

end

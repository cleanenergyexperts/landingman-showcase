require "middleman-core"

Middleman::Extensions.register :landingman_showcase do
  require "landingman-showcase/extension"
  ::Landingman::ShowcaseExtension
end

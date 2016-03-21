require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]

opts = {
  path: '/douglas-county-property-owner',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.douglas.co.us/resource/e5ba-n74c?'+Rack::Utils.build_query({
    '$limit' => 1000
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    latlng = item['location'].gsub(/[()]/, '').split(/\s*,\s*/)
    title = <<-TITLE
      #{item['owner_name']}
    TITLE

    {
      'id' => item['account_no'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          latlng[1].to_f,
          latlng[0].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end


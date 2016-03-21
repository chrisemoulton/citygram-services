require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]

opts = {
  path: '/douglas-county-senior-and-community-resources',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.douglas.co.us/resource/t3ja-9fqv?'+Rack::Utils.build_query({
    '$limit' => 15000,
    '$order' => 'organization_name DESC',
    '$where' => <<-WHERE.oneline
      web_page_address IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE
      #{item['organization_name']}
      #{item['category']}
      #{item['telephone']}
      #{item['web_page_address']['url']}
    TITLE

    {
      'id' => item['telephone'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['location_1']['longitude'].to_f,
          item['location_1']['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end


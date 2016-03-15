require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]

opts = {
  path: '/douglas-county-senior-and-community-resources',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.douglas.co.us/resource/t3ja-9fqv?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'organization_name DESC'
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    puts item.inspect
    title = <<-TITLE.oneline
      Line 1: #{item['organization_name']}
      Line 2: #{item['category']}
      Line 3: #{item['telephone']}
      Line 4: #{item['web_page_address']}
    TITLE

    {
      'id' => item['telephone'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['location_1.longitude'].to_f,
          item['location_1.latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end


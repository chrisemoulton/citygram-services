require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]

opts = {
  path: '/douglas-county-property-values',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.douglas.co.us/resource/drva-83eq?'+Rack::Utils.build_query({
    '$limit' => 100
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE
      Actual Value: $#{item['actual_value'].to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(",").reverse}
      Assessed Value: $#{item['assessed_value'].to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(",").reverse}
    TITLE

    {
      'id' => item['account_no'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['location']['longitude'].to_f,
          item['location']['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end


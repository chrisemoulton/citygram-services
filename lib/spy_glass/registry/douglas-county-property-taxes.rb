require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]

opts = {
  path: '/douglas-county-property-taxes',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.douglas.co.us/resource/4zp7-9tjq.json?'+Rack::Utils.build_query({
    '$limit' => 15000
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|

    case item['location_1']
    when nil
    else 
      longitude = item['location_1']['longitude'].to_f
      latitude = item['location_1']['latitude'].to_f
    end

    title =
      case item['full_street_name']
      when nil
        case item['exemption_code']
        when nil
          "The #{item['tax_year']} valuation for this property is $#{item['total_actual']}, with an assessed value of $#{item['total_assessed']}. Tax for this property is $#{item['taxes']}."
        else 
          "The #{item['tax_year']} valuation for this property is $#{item['total_actual']}, with an assessed value of $#{item['total_assessed']}. Tax for this property is $#{item['taxes']}. This property has an exemption, reducing the tax amount to $#{item['tax_bill_amount']}"
        end
      else
        case item['exemption_code']
        when nil
          "The #{item['tax_year']} valuation for #{item['full_street_name']} is $#{item['total_actual']}, with an assessed value of $#{item['total_assessed']}. Tax for this property is $#{item['taxes']}."
        else
           "The #{item['tax_year']} valuation for #{item['full_street_name']} is $#{item['total_actual']}, with an assessed value of $#{item['total_assessed']}. Tax for this property is $#{item['taxes']}. This property has an exemption, reducing the tax amount to $#{item['tax_bill_amount']}"
        end
      end

    {
      'id' => item['account_number'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          longitude,
          latitude
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end


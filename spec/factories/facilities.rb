# spec/factories/facilities.rb
FactoryBot.define do
  factory :facility do
    sequence(:osm_id) { |n| n + 1000000 }
    name { Faker::Company.name }
    facility_type { %w[hospital clinic pharmacy dentist doctors].sample }
    street { Faker::Address.street_name }
    house_number { Faker::Address.building_number }
    city { "Vilnius" }
    postcode { Faker::Address.postcode }
    opening_hours { "Mo-Fr 08:00-18:00" }
    phone { Faker::PhoneNumber.phone_number }
    wheelchair_accessible { Faker::Boolean.boolean }
    has_emergency { Faker::Boolean.boolean(true_ratio: 0.3) }
    specialization { Faker::Lorem.word }
    website { [ Faker::Internet.url, nil ].sample }
    email { [ Faker::Internet.email, nil ].sample }

    location do
      lon = Faker::Address.longitude
      lat = Faker::Address.latitude
      RGeo::Geographic.spherical_factory(srid: 4326).point(lon, lat)
    end

    trait :with_details do
      after(:create) do |facility|
        create(:facility_detail, facility: facility)
      end
    end

    trait :with_osm_metadata do
      after(:create) do |facility|
        create(:osm_metadata, facility: facility)
      end
    end

    trait :with_specialties do
      transient do
        specialty_count { 2 }
      end

      after(:create) do |facility, evaluator|
        create_list(:specialty, evaluator.specialty_count).each do |spec|
          create(:facility_specialty, facility: facility, specialty: spec)
        end
        facility.reload
      end
    end

    trait :with_complaints do
      transient do
        complaint_count { 1 }
      end

      after(:create) do |facility, evaluator|
        create_list(:complaint, evaluator.complaint_count, facility: facility)
        facility.reload
      end
    end
  end
end
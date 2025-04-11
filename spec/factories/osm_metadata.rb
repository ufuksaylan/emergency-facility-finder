FactoryBot.define do
  factory :osm_metadata do
    association :facility
    changeset_id { Faker::Number.number(digits: 9) }
    changeset_version { Faker::Number.number(digits: 2) }
    changeset_timestamp { Faker::Time.backward(days: 90) }
    changeset_user { Faker::Internet.username }
  end
end
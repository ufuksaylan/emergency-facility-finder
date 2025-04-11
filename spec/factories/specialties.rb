FactoryBot.define do
  factory :specialty do
    sequence(:name) { |n| "#{Faker::Lorem.unique.word}_#{n}" }
    label { name.humanize }
  end
end

FactoryBot.define do
  factory :facility_specialty do
    association :facility
    association :specialty
  end
end
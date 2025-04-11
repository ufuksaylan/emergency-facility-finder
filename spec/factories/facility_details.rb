FactoryBot.define do
  factory :facility_detail do
    association :facility
    dispensing { Faker::Boolean.boolean }
    trauma_level { [nil, 1, 2, 3, 4, 5].sample }
    appointment_required { Faker::Boolean.boolean }
    completeness_score { Faker::Number.between(from: 0.0, to: 100.0).round(2) }
    last_updated { Faker::Time.backward(days: 30) }
  end
end
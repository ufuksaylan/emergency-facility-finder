FactoryBot.define do
  factory :complaint do
    association :facility
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    status { Complaint::STATUSES.sample }

    trait :submitted do
      status { 'submitted' }
    end

    trait :under_review do
      status { 'under_review' }
    end

    trait :resolved do
      status { 'resolved' }
      resolution_notes { Faker::Lorem.sentence }
      resolved_at { Faker::Time.backward(days: 5) }
    end

    trait :rejected do
      status { 'rejected' }
      resolution_notes { Faker::Lorem.sentence }
      resolved_at { Faker::Time.backward(days: 7) }
    end
  end
end
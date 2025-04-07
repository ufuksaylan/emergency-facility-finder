class FacilitySpecialty < ApplicationRecord
  belongs_to :facility
  belongs_to :specialty

  validates :facility_id, uniqueness: { scope: :specialty_id, message: "already associated with this specialty" }
end

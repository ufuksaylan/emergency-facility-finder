class Facility < ApplicationRecord
  has_one :facility_detail, dependent: :destroy
  has_one :osm_metadata, dependent: :destroy

  validates :osm_id, presence: true, uniqueness: true

  # Basic scopes
  scope :of_type, ->(type) { where(facility_type: type) }
  scope :with_emergency, -> { where(has_emergency: true) }

end

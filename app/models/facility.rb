class Facility < ApplicationRecord
  has_one :facility_detail, dependent: :destroy
  has_one :osm_metadata, dependent: :destroy

  has_many :facility_specialties, dependent: :destroy
  has_many :specialties, through: :facility_specialties
  has_many :complaints, dependent: :destroy

  validates :osm_id, presence: true, uniqueness: true

  scope :of_type, ->(type) { where(facility_type: type) }
  scope :with_emergency, -> { where(has_emergency: true) }

  scope :within_distance, ->(lat, lng, distance_in_meters = 5000) {
    point = "POINT(#{lng} #{lat})"
    where("ST_DWithin(location::geography, ST_SetSRID(ST_GeomFromText('#{point}'), 4326)::geography, #{distance_in_meters})")
  }
end

class Specialty < ApplicationRecord
  has_many :facility_specialties, dependent: :destroy
  has_many :facilities, through: :facility_specialties

  validates :name, presence: true, uniqueness: true
end

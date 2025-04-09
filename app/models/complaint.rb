# app/models/complaint.rb
class Complaint < ApplicationRecord
  belongs_to :facility

  STATUSES = %w[submitted under_review resolved rejected].freeze

  validates :facility_id, presence: true
  validates :description, presence: true, length: { minimum: 10 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :open, -> { where(status: %w[submitted under_review]) }
  scope :closed, -> { where(status: %w[resolved rejected]) }
end

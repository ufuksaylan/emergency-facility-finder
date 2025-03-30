# app/views/facilities/_facility.json.jbuilder

# This file defines the JSON for ONE facility.
# The 'facility' variable is automatically passed in by Jbuilder.

json.extract! facility,
              :id,
              :osm_id,
              :name,
              :facility_type,
              :street,
              :house_number,
              :city,
              :postcode,
              :opening_hours,
              :phone,
              :wheelchair_accessible,
              :has_emergency,
              :specialization,
              :created_at,
              :updated_at

# Handle location safely
if facility.location
  json.location do
    json.latitude facility.location.latitude
    json.longitude facility.location.longitude
  end
else
  json.location nil # Explicitly output null if location is missing
end

# --- Optional: Include associated data ---
# You can keep this logic here too if needed
# if facility.facility_detail
#   json.details do
#     json.extract! facility.facility_detail, :dispensing, :trauma_level, :appointment_required, :completeness_score, :last_updated
#   end
# else
#   json.details nil
# end
# # ... and so on for osm_metadata ...
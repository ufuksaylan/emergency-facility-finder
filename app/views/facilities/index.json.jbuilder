# app/views/facilities/index.json.jbuilder

# This tells Jbuilder to render the partial located at 'facilities/facility'
# for each item in the @facilities collection.
# It automatically passes each item as the local variable 'facility' to the partial.
json.array! @facilities, partial: 'facilities/facility', as: :facility

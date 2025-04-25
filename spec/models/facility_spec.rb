require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe 'scopes' do
    let!(:hospital) { create(:facility, facility_type: 'hospital') }
    let!(:pharmacy) { create(:facility, facility_type: 'pharmacy') }
    let!(:emergency_hospital) { create(:facility, facility_type: 'hospital', has_emergency: true) }
    let!(:non_emergency_hospital) { create(:facility, facility_type: 'hospital', has_emergency: false) }

    describe '.of_type' do
      it 'returns facilities of the given type' do
        expect(Facility.of_type('hospital')).to contain_exactly(hospital, emergency_hospital, non_emergency_hospital)
      end
    end

    describe '.within_distance' do
      let!(:city_center) { create(:facility, location: RGeo::Geographic.spherical_factory(srid: 4326).point(25.2797, 54.6872)) }
      let!(:nearby) { create(:facility, location: RGeo::Geographic.spherical_factory(srid: 4326).point(25.2897, 54.6972)) }
      let!(:far_away) { create(:facility, location: RGeo::Geographic.spherical_factory(srid: 4326).point(26.2797, 55.6872)) }

      it 'returns facilities within the specified distance' do
        results = Facility.within_distance(54.6872, 25.2797, 5000)
        expect(results).to include(city_center, nearby)
        expect(results).not_to include(far_away)
      end
    end
  end
end

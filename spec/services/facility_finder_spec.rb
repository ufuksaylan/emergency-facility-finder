require 'rails_helper'

def create_point(lon, lat)
  RGeo::Geographic.spherical_factory(srid: 4326).point(lon, lat)
end

RSpec.describe FacilityFinder do

  let(:params) { {} }
  let(:service) { described_class.new(params) }


  let(:ref_lat) { 54.6872 }
  let(:ref_lng) { 25.2797 }

  context "when no filters are provided" do
    let!(:facility1) { create(:facility) }
    let!(:facility2) { create(:facility) }

    it "returns all facilities" do
      expect(service.call).to contain_exactly(facility1, facility2)
    end
  end

  context "when standard filters are applied" do
    let!(:facility1) { create(:facility, city: "Testville", wheelchair_accessible: true, postcode: "111") }
    let!(:facility2) { create(:facility, city: "OtherCity", wheelchair_accessible: true, postcode: "222") }
    let!(:facility3) { create(:facility, city: "Testville", wheelchair_accessible: false, postcode: "333") }
    let!(:facility4) { create(:facility, city: "Testville", wheelchair_accessible: true, postcode: "444") }

    context "with city and wheelchair accessibility" do
      let(:params) { { city: "Testville", wheelchair_accessible: "true" } }

      it "returns only facilities matching all filters" do
        expect(service.call).to contain_exactly(facility1, facility4)
      end
    end

    context "with a blank filter value" do
      let(:params) { { city: "Testville", postcode: "" } } # Postcode is blank

      it "ignores the blank filter and filters by others" do
        expect(service.call).to contain_exactly(facility1, facility3, facility4) # All in Testville
      end
    end
  end

  context "when only specialization filter is applied" do
    let!(:specialty1) { create(:specialty, name: "Cardiology") }
    let!(:specialty2) { create(:specialty, name: "Neurology") }
    let!(:specialty3) { create(:specialty, name: "Pediatrics") }

    let!(:facility1) { create(:facility) }
    let!(:facility2) { create(:facility) }
    let!(:facility3) { create(:facility) }

    before do
      # Associate facilities with specialties
      create(:facility_specialty, facility: facility1, specialty: specialty1)
      create(:facility_specialty, facility: facility1, specialty: specialty2)
      create(:facility_specialty, facility: facility2, specialty: specialty2)
      create(:facility_specialty, facility: facility3, specialty: specialty3)
    end

    context "with valid specialization IDs" do
      # Use .id to get the actual IDs after creation
      let(:params) { { specializations: "#{specialty1.id}, #{specialty2.id}" } }

      it "returns facilities having ANY of the specified specialties" do
        # Facility 1 has 1 & 2, Facility 2 has 2. Distinct should be applied by the service.
        expect(service.call).to contain_exactly(facility1, facility2)
      end
    end

    context "with only one specialization ID" do
      let(:params) { { specializations: specialty3.id.to_s } }

      it "returns only facilities with that specific specialty" do
        expect(service.call).to contain_exactly(facility3)
      end
    end

    context "with invalid/non-existent specialization values" do
      let(:params) { { specializations: "abc, 0, 99999" } } # 99999 likely doesn't exist

      it "returns no facilities if only invalid IDs are passed" do
        # The service rejects non-numeric and zero IDs
        expect(service.call).to be_empty
      end
    end

    context "with a mix of valid and invalid specialization values" do
      let(:params) { { specializations: "abc, #{specialty1.id}, xyz" } }

      it "returns facilities matching the valid IDs" do
        expect(service.call).to contain_exactly(facility1)
      end
    end
  end

  context "when only distance ordering is applied" do
    let!(:facility_close) { create(:facility, location: create_point(ref_lng + 0.01, ref_lat)) } # Approx 1km East
    let!(:facility_medium) { create(:facility, location: create_point(ref_lng - 0.05, ref_lat)) } # Approx 5km West
    let!(:facility_far) { create(:facility, location: create_point(ref_lng, ref_lat + 0.1)) }   # Approx 11km North

    context "with valid latitude/longitude" do
      let(:params) { { latitude: ref_lat.to_s, longitude: ref_lng.to_s } }

      it "returns facilities ordered by distance (closest first)" do
        expect(service.call).to eq([facility_close, facility_medium, facility_far])
      end
    end

    context "with invalid latitude/longitude" do
      let(:params) { { latitude: "invalid", longitude: ref_lng.to_s } }

      it "does not apply distance ordering and returns facilities in default order" do
        expect(service.call).to contain_exactly(facility_close, facility_medium, facility_far)
        expect(service.call.first).not_to eq(facility_close) if facility_close.id > facility_medium.id && facility_close.id > facility_far.id
      end
    end
  end

  context "when specializations and distance are applied" do
    let!(:specialty_a) { create(:specialty, name: "Ortho") }
    let!(:specialty_b) { create(:specialty, name: "Gastro") }

    let!(:facility_a_close) { create(:facility, location: create_point(ref_lng + 0.01, ref_lat)) } # Has A
    let!(:facility_b_medium) { create(:facility, location: create_point(ref_lng - 0.05, ref_lat)) } # Has B
    let!(:facility_a_far) { create(:facility, location: create_point(ref_lng, ref_lat + 0.1)) }   # Has A

    before do
      create(:facility_specialty, facility: facility_a_close, specialty: specialty_a)
      create(:facility_specialty, facility: facility_b_medium, specialty: specialty_b)
      create(:facility_specialty, facility: facility_a_far, specialty: specialty_a)
    end

    let(:params) do
      {
        specializations: specialty_a.id.to_s,
        latitude: ref_lat.to_s,
        longitude: ref_lng.to_s
      }
    end

    it "returns only facilities with the specialty, ordered by distance" do
      expect(service.call).to eq([facility_a_close, facility_a_far])
    end
  end

  context "when standard filters, specializations, and distance are applied" do
    let!(:specialty_x) { create(:specialty, name: "X-Ray") }
    let!(:specialty_y) { create(:specialty, name: "Y-Therapy") }

    let!(:f1) { create(:facility, city: "TargetCity", wheelchair_accessible: true, location: create_point(ref_lng + 0.02, ref_lat)) } # Has X
    let!(:f2) { create(:facility, city: "TargetCity", wheelchair_accessible: false, location: create_point(ref_lng - 0.03, ref_lat)) } # Has Y
    let!(:f3) { create(:facility, city: "TargetCity", wheelchair_accessible: true, location: create_point(ref_lng + 0.08, ref_lat)) } # Has X
    let!(:f4) { create(:facility, city: "OtherCity", wheelchair_accessible: true, location: create_point(ref_lng + 0.01, ref_lat)) } # Has X

    before do
      create(:facility_specialty, facility: f1, specialty: specialty_x)
      create(:facility_specialty, facility: f2, specialty: specialty_y)
      create(:facility_specialty, facility: f3, specialty: specialty_x)
      create(:facility_specialty, facility: f4, specialty: specialty_x)
    end

    let(:params) do
      {
        city: "TargetCity",
        wheelchair_accessible: "true",
        specializations: specialty_x.id.to_s,
        latitude: ref_lat.to_s,
        longitude: ref_lng.to_s
      }
    end

    it "returns facilities matching all criteria, ordered by distance" do

      expect(service.call).to eq([f1, f3])
    end
  end
end

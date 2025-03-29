# This file should ensure the existence of records required to run the application in every environment.
# The data can be loaded with bin/rails db:seed (or created alongside the database with db:setup).

require 'uri'
require 'net/http'
require 'json'
require 'logger'

logger = Logger.new($stdout)
logger.level = Logger::INFO

API_CONFIG = {
  key: ENV.fetch('HEALTHSITES_API_KEY') { raise 'HEALTHSITES_API_KEY environment variable is required' },
  base_url: 'https://healthsites.io/api/v3/facilities',
  country: 'lithuania',
  extent: '25.0245351,54.5689058,25.4814574,54.8323200'
}.freeze

FACILITY_TYPES = {
  pharmacy: [{ amenity: 'pharmacy', healthcare: 'pharmacy' }],
  dentist: [{ amenity: 'dentist' }, { healthcare: 'dentist' }],
  clinic: [{ amenity: 'clinic' }, { healthcare: 'clinic' }],
  hospital: [{ amenity: 'hospital' }, { healthcare: 'hospital' }]
}.freeze

class HealthsitesImporter
  def initialize(config, logger)
    @config = config
    @logger = logger
    @page = 1
    @total_processed = 0
  end

  def import
    @logger.info('Starting seed data import...')

    loop do
      @logger.info("Fetching page #{@page}...")
      facilities = fetch_facilities

      break if facilities.empty?

      import_facilities(facilities)
      @page += 1

      # Add a delay to avoid overwhelming the API
      @logger.info("Waiting 1 second before next request...")
      sleep(1)
    end

    @logger.info("Seed data import completed. Processed #{@total_processed} facilities.")
  end

  private

  def fetch_facilities
    # Let's use a simpler approach with Ruby's OpenURI which handles redirects automatically
    require 'open-uri'

    uri = URI(@config[:base_url])
    uri.query = URI.encode_www_form(
      'api-key' => @config[:key],
      'page' => @page,
      'country' => @config[:country],
      'extent' => @config[:extent],
      'from' => @config[:from_date]
    )

    @logger.info("Requesting: #{uri}")

    begin
      # This will automatically follow redirects
      response = URI.open(uri, 'User-Agent' => 'Ruby/Rails Healthsites Importer')
      JSON.parse(response.read)
    rescue OpenURI::HTTPError => e
      @logger.error("API request failed: #{e.message}")
      []
    rescue JSON::ParserError => e
      @logger.error("Failed to parse JSON response: #{e.message}")
      []
    rescue => e
      @logger.error("Unexpected error: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
      []
    end
  end

  def import_facilities(facilities)
    facilities.each do |facility_data|
      process_facility(facility_data)
      @total_processed += 1
    end

    @logger.info("Processed #{facilities.size} facilities from page #{@page}")
  end

  def process_facility(facility_data)
    return if facility_data['osm_id'].nil?
    return if Facility.exists?(osm_id: facility_data['osm_id'])

    attributes = facility_data['attributes']
    coordinates = facility_data['centroid']['coordinates']

    ActiveRecord::Base.transaction do
      facility = create_facility(facility_data, attributes, coordinates)
      create_facility_detail(facility, facility_data, attributes)
      create_osm_metadata(facility, attributes)

      @logger.info("Created facility: #{facility.name} (#{facility.facility_type})")
    end
  rescue => e
    @logger.error("Error processing facility: #{e.message}")
    @logger.error(e.backtrace.join("\n"))
  end

  def create_facility(facility_data, attributes, coordinates)
    Facility.create!(
      osm_id: facility_data['osm_id'],
      name: attributes['name'],
      facility_type: determine_facility_type(attributes),
      location: "POINT(#{coordinates[1]} #{coordinates[0]})",
      street: attributes['addr_street'],
      house_number: attributes['addr_housenumber'],
      city: attributes['addr_city'] || 'Vilnius',
      postcode: attributes['addr_postcode'],
      opening_hours: attributes['opening_hours'],
      phone: attributes['phone'],
      wheelchair_accessible: wheelchair_accessible?(attributes),
      has_emergency: determine_emergency_capability(attributes),
      )
  end

  def determine_emergency_capability(attributes)
    # If emergency attribute is missing, default based on facility type
    if attributes['emergency'].nil?
      return attributes['facility_type'] == 'hospital' # Default hospitals to true
    end

    # Anything other than explicit "no" is considered to have emergency capability
    attributes['emergency'] != 'no'
  end

  def create_facility_detail(facility, facility_data, attributes)
    FacilityDetail.create!(
      facility: facility,
      completeness_score: facility_data['completeness'].to_f / 100,
      last_updated: parse_timestamp(attributes['changeset_timestamp'])
    )
  end

  def create_osm_metadata(facility, attributes)
    return unless attributes['changeset_id'].present?

    OsmMetadata.create!(
      facility: facility,
      changeset_id: attributes['changeset_id'],
      changeset_version: attributes['changeset_version'],
      changeset_timestamp: parse_timestamp(attributes['changeset_timestamp']),
      changeset_user: attributes['changeset_user']
    )
  end

  def determine_facility_type(attributes)
    FACILITY_TYPES.each do |type, conditions|
      return type.to_s if conditions.any? do |condition|
        condition.all? { |key, value| attributes[key.to_s] == value }
      end
    end

    # Default to the amenity value if it exists, otherwise use healthcare value
    attributes['amenity'] || attributes['healthcare'] || 'unknown'
  end

  def wheelchair_accessible?(attributes)
    wheelchair = attributes['wheelchair']
    wheelchair&.downcase == 'yes'
  end

  def parse_timestamp(timestamp_str)
    DateTime.parse(timestamp_str) if timestamp_str.present?
  end
end

HealthsitesImporter.new(API_CONFIG, logger).import

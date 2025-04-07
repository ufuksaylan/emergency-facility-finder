# app/controllers/osrm_proxy_controller.rb
require "net/http"
require "uri"

class OsrmProxyController < ApplicationController
  OSRM_CONFIG = {
    host: ENV.fetch("OSRM_HOST", "localhost"),
    timeout: ENV.fetch("OSRM_TIMEOUT", 10).to_i,
    ports: {
      "driving" => ENV.fetch("OSRM_DRIVING_PORT", 5000).to_i,
      "foot"    => ENV.fetch("OSRM_FOOT_PORT", 5001).to_i
    }.freeze
  }.freeze

  # Define custom error classes
  class OsrmProxyError < StandardError; end
  class OsrmTimeoutError < OsrmProxyError; end
  class OsrmConnectionError < OsrmProxyError; end
  class OsrmBadGatewayError < OsrmProxyError; end

  # Map specific network errors to custom errors
  rescue_from Net::ReadTimeout, Net::OpenTimeout, with: :handle_timeout
  rescue_from Errno::ECONNREFUSED, with: :handle_connection_refused
  # Handle custom errors with specific responses
  rescue_from OsrmTimeoutError, with: :render_gateway_timeout
  rescue_from OsrmConnectionError, OsrmBadGatewayError, with: :render_bad_gateway
  rescue_from StandardError, with: :render_internal_server_error # Fallback

  def route
    profile = params.require(:profile)
    osrm_path_segment = params.require(:osrm_path)
    target_port = OSRM_CONFIG.dig(:ports, profile)

    unless target_port
      render json: { error: "Invalid profile: #{profile}" }, status: :bad_request
      return
    end

    target_uri = build_osrm_uri(target_port, profile, osrm_path_segment, request.query_string)
    Rails.logger.info { "Proxying OSRM request to: #{target_uri}" }

    response = perform_osrm_request(target_uri)

    render_osrm_response(response)
  end

  private

  def build_osrm_uri(port, profile, path, query)
    URI::HTTP.build(
      host: OSRM_CONFIG[:host],
      port: port,
      path: "/route/v1/#{profile}/#{path}",
      query: query.presence
    )
  rescue URI::InvalidURIError => e
    raise OsrmBadGatewayError, "Invalid URI generated for OSRM request: #{e.message}"
  end

  def perform_osrm_request(uri)
    Net::HTTP.start(uri.host, uri.port, read_timeout: OSRM_CONFIG[:timeout], open_timeout: OSRM_CONFIG[:timeout]) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request)
    end
  end

  def render_osrm_response(response)
    content_type = response.content_type || "application/json"
    render body: response.body, status: response.code.to_i, content_type: content_type
  end

  # Error handling methods
  def handle_timeout(exception)
    raise OsrmTimeoutError, exception.message
  end

  def handle_connection_refused(exception)
    raise OsrmConnectionError, exception.message
  end

  def render_gateway_timeout(exception)
    Rails.logger.error "OSRM Timeout: #{exception.message}"
    render json: { error: "Routing service timed out" }, status: :gateway_timeout
  end

  def render_bad_gateway(exception)
    Rails.logger.error "OSRM Connection/Bad Gateway: #{exception.message}"
    render json: { error: "Routing service unavailable or encountered an error" }, status: :bad_gateway
  end

  def render_internal_server_error(exception)
    # Log unexpected errors
    Rails.logger.error "Unexpected OSRM Proxy Error: #{exception.class} - #{exception.message}\n#{exception.backtrace.first(5).join("\n")}"
    render json: { error: "Internal server error while proxying route request" }, status: :internal_server_error
  end
end

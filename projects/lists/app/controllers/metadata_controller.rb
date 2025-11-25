class MetadataController < ApplicationController
  before_action :authenticate_user!

  def fetch
    url = params[:url]

    unless url.present?
      render json: { error: "URL is required" }, status: :bad_request
      return
    end

    begin
      html = fetch_url(url)

      title = html[/<title>(.*?)<\/title>/mi, 1]
      title = title&.strip

      description = html[/<meta\s+name=["']description["']\s+content=["'](.*?)["']/mi, 1]
      description ||= html[/<meta\s+content=["'](.*?)["']\s+name=["']description["']/mi, 1]
      description = description&.strip

      render json: { title: title, description: description }
    rescue => e
      render json: { error: "Failed to fetch metadata: #{e.message}" }, status: :unprocessable_entity
    end
  end

  private

  def fetch_url(url)
    require "net/http"
    require "uri"

    pp url
    uri = URI.parse(url)
    pp uri
    response = Net::HTTP.get_response(uri)
    # pp response
    while response.is_a?(Net::HTTPRedirection)
      pp response
      uri = URI.parse(response["location"])
      response = Net::HTTP.get_response(uri)
    end

    if response.is_a?(Net::HTTPSuccess)
      response.body
    else
      throw "Failed to fetch #{uri}"
    end
  end
end

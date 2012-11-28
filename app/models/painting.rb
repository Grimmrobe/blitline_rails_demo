require 'plugins/filename_sanitizer'

class Painting < ActiveRecord::Base

  # Sanitizing filename should be done at js level, not here... help? Otherwise
  # Amazon adds some characters of their own to the filename in S3 if
  # they contain some weird characters. Eg: 'hello%20world' => 'hello%2520world'
  # This will fail the blitline_job method as it can't find the original image.
  include FilenameSanitizer

  attr_accessible :image_url, :name

  before_save :run_blitline_job

  private

    def run_blitline_job
      filename = File.basename(image_url, '.*')
      self.name ||= sanitize_filename(filename).titleize # set default name based on filename

      filename_with_ext = sanitize_filename(File.basename(image_url))
      key = "uploads/thumbnails/#{SecureRandom.hex}/#{filename_with_ext}"

      bucket = ENV["AWS_S3_BUCKET"]

      images = blitline_job(image_url, bucket, key)
      self.image_url = images['results'][0]['images'][0]['s3_url'] # extracts s3_url from blitline's ruby hashes
    end

    def blitline_job(original_image, bucket, key)
      blitline_service = Blitline.new
      blitline_service.add_job_via_hash({ # New add job method in Blitline gem 2.0.1. Messy.
        "application_id" => ENV['BLITLINE_APPLICATION_ID'],
        "src" => original_image,
        "functions" => [{
            "name"   => "watermark", # watermark the image
            "params" => { "text" => "oh hai" },
            "functions" => [{
                "name"   => "resize_to_fill", # resize after watermark
                "params" => { "width" => 200, "height" => 200 },
                "save"   => {
                    "image_identifier" => "MY_CLIENT_ID", # Not sure what this is for
                    "s3_destination"   => { "key" => key, "bucket" => bucket } # push to your S3 bucket
                }
            }]
        }]
      })
      return blitline_service.post_jobs
    end
end

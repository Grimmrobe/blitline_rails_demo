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
      job = Blitline::Job.new(original_image) # Source file to manipulate
      job.application_id = ENV['BLITLINE_APPLICATION_ID']
      watermark_function = job.add_function("watermark", { :text => "oh hai" }) # Add a watermark
      crop_large_function = watermark_function.add_function("resize_to_fill", { :width => 200, :height => 200 }) # Crop & resize image
      crop_large_function.add_save("my_large_thumbnail", key, bucket)

      blitline_service = Blitline.new
      blitline_service.jobs << job # Push job into service
      res = blitline_service.post_jobs
      return res
    end
end

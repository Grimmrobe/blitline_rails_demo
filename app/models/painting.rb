require 'plugins/filename_sanitizer'

class Painting < ActiveRecord::Base

  # Sanitizing filename should be done at js level, not here... help? Otherwise
  # Amazon adds some characters of their own to the filename in S3 if
  # they contain some weird characters. Eg: 'hello%20world' => 'hello%2520world'
  # This will fail the blitline_job method as it can't find the original image.
  include FilenameSanitizer

  attr_accessible :img_ori, :name

  before_save :run_blitline_job

  private

    def run_blitline_job
      filename = File.basename(img_ori, '.*')
      self.name ||= sanitize_filename(filename).titleize # set default name based on filename

      filename_with_ext = sanitize_filename(File.basename(img_ori))
      key = "uploads/large/#{SecureRandom.hex}/#{filename_with_ext}"
      key2 = "uploads/thumb/#{SecureRandom.hex}/#{filename_with_ext}"

      bucket = ENV["AWS_S3_BUCKET"]

      images = blitline_job(img_ori, bucket, key, key2)
      self.img_large = images['results'][0]['images'][0]['s3_url'] # extracts s3_url from blitline's ruby hashes
      self.img_thumb = images['results'][0]['images'][1]['s3_url']
    end

    def blitline_job(original_image, bucket, key, key2)
      blitline_service = Blitline.new
      blitline_service.add_job_via_hash({ # New add job method in Blitline gem 2.0.1. Messy.
        "application_id" => ENV['BLITLINE_APPLICATION_ID'],
        "src" => original_image,
        "functions" => [
          {
            "name"   => "resize_to_fit", # large version
            "params" => { "width"=>550,
                          "only_shrink_larger"=>true }, # don't upsize image if width smaller than 550px

            "functions" => [{
                "name"   => "pad",
                "params" => { "size"=>25, "color"=>"#ffffff", "gravity"=>"SouthGravity" },

                "functions" => [{
                    "name"   => "annotate",
                    "params" => { "x"=>5, "y"=>5, "point_size"=>"14",
                                  "text"=>"Find us at example.com",
                                  "color"=>"#8a8a8a", "gravity"=>"SouthEastGravity" },
                    "save"   => {
                        "image_identifier" => "MY_CLIENT_ID", # Not sure what this is for
                        "s3_destination"   => { "key" => key, "bucket" => bucket } # push to your S3 bucket
                    }
                }]
            }]
          },
          {
              "name"   => "resize_to_fill", # thumbnail version
              "params" => { "width"=>144, "height"=>216 },
              "save"   => {
                  "image_identifier" => "MY_CLIENT_ID",
                  "s3_destination"   => { "key" => key2, "bucket" => bucket }
              }
          }
        ]
      })
      return blitline_service.post_jobs
    end
end

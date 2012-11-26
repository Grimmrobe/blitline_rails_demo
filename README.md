## Rails multi-upload to S3 with jQuery File Upload & Blitline


This is a Rails 3.2 demo that shows how to multi-upload images to S3 and send them to [Blitline](http://www.blitline.com/) to process them into watermarked thumbnails. The processed images will be pushed back to your S3 bucket.

Most of the code here comes from [gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload) (which [Ryan Bates](http://github.com/rbates) wrote for [Railscast#383](http://railscasts.com/episodes/383-uploading-to-amazon-s3)) and [Blitquick](https://github.com/blitline-dev/blitquick), the official Rails demo for the [Blitline gem](https://github.com/blitline-dev/blitline).

Multiple file upload capability is provided by [jQuery-File-Upload](https://github.com/blueimp/jQuery-File-Upload).

### Let's do this

```
# Install the gems
bundle install
```

### Amazon S3 and Blitline credentials

Get an [Amazon S3 account](http://aws.amazon.com/s3/) if you don't have it.

Go to your AWS S3 web console. Create a bucket, right-click on your bucket & choose `Properties`. You should find a button: `Add CORS Configuration`. Add the configurations below and click `Save`.

```
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <CORSRule>
        <AllowedOrigin>http://localhost:3000</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```

You might notice that `<AllowedOrigin>` points to `localhost:3000` for development purpose. If you want to point to your own server, edit appropriately.

Next, sign up with [Blitline](http://www.blitline.com/) to get your `Application ID`. You also need to [give Blitline permission](http://www.blitline.com/docs/s3_permissions) to your S3 bucket:

1. Go to your AWS S3 web console.
2. Right click on the bucket you wish to give Blitline permission to write to.
3. Click `Properties`.
4. In the `Properties` panel, click the button `Edit Bucket Policy`.
5. Paste the following policy (replace `YOUR_BUCKET_NAME` with your bucket's name) and click `Save`.

```
{
    "Version": "2008-10-17",
    "Statement": [
       {
           "Sid": "AddCannedAcl",
           "Effect": "Allow",
           "Principal": { "CanonicalUser": "dd81f2e5f9fd34f0fca01d29c62e6ae6cafd33079d99d14ad22fbbea41f36d9a"},
           "Action": [
               "s3:PutObjectAcl",
               "s3:PutObject"
           ],
           "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
       }
   ]
}
```

Lastly, generate `config/application.yml` with [Figaro gem](https://github.com/laserlemon/figaro)
(included in the gemfile) to store your S3 & Blitline credentials in your app:

```
rails generate figaro:install
```
Note: This command will automatically put `config/application.yml` in `.gitignore`.

An example of `config/application.yml`:

```
AWS_ACCESS_KEY_ID: 7e94262e33e621817d1a6e714545a5fd
AWS_SECRET_ACCESS_KEY: e89d086d520b97aea0ceda9a3f8c38a4
AWS_S3_BUCKET: your_bucket_name
BLITLINE_APPLICATION_ID: 329747094b8257c6cd4fb381f7b6df7d
```

### Run the demo

```
rake db:setup
rails s
```

### Gotchas

When the uploads finished, you might see broken image link in the browser. It takes time (half a second or two) for Blitline to process the images but the demo app instantly load the images without waiting for Blitline to finish. To see the images, please refresh your browser.

The [Blitline gem](https://github.com/blitline-dev/blitline) does provide a way to notify the demo app that it has finished processing but I don't know how to code it… any help will be appreciated.

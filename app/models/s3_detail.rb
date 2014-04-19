class S3Detail
  attr_accessor :key

  def initialize(key)
    @key = key
  end

  def encrypt
    aes = OpenSSL::Cipher.new('AES-128-CBC')
    aes.encrypt
    aes.key = digested_key
    final = aes.update(s3_details) + aes.final
    Base64.encode64(final).gsub("\n","")
  end

  private

  def s3_details
    ActiveSupport::JSON.encode({
      aws_key: ENV['AWS_KEY'],
      aws_secret_key: ENV['AWS_SECRET'],
      bucket: ENV['AWS_BUCKET_NAME']
    })
  end

  def digested_key
    Digest::MD5.digest(key) if(key.kind_of?(String) && 16 != key.bytesize)
  end
end

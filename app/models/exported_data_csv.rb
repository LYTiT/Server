class ExportedDataCsv < ActiveRecord::Base

  has_attached_file :csv_file, :storage => :s3, :s3_credentials => Proc.new{|a| a.instance.s3_credentials }

  do_not_validate_attachment_file_type :csv_file

  def s3_credentials
    {:bucket => "lytit-dev", :access_key_id => "AKIAIZ7KRTHZI3ZI4VJQ", :secret_access_key => "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"}
  end

  acts_as_singleton

  def write_csv
    file = Tempfile.new([self.filename, '.csv'])
    begin
      file.write self.data_string
      self.csv_file = file
      self.save
    ensure
      file.close
      file.unlink # deletes the temp file
    end
  end

  protected

  # Kevin says: override me in subclasses ...
  def filename
    'exported_data_csv_'
  end

  def data_string
    ''
  end
end
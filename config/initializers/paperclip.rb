#Paperclip::Attachment.default_options[:url] = ':s3_domain_url'
#Paperclip::Attachment.default_options[:path] = '/:class/:attachment/:id_partition/:style/:filename'
if Rails.env != "development" and Rails.env != "test"
  Paperclip::Attachment.default_options.merge!(
    url:                  ':s3_domain_url',
    path:                 ':class/:attachment/:id/:style/:filename',
    storage:              :s3,
    s3_credentials:       {
      :bucket => "smartrent.hy.ly",
      :access_key_id => "AKIAIODQWXO6X6CB5TQQ",
      :secret_access_key => "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"
    },
    #s3_permissions:       :private,
    s3_protocol:          'http'
  )
end

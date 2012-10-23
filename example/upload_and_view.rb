require 'crocodoc'

# Set up crocodoc
Crocodoc.api_token = "yourapitoken"

# Upload a document from a file.
my_document = Crocodoc::Document.upload_file('/path/to/document.docx')

# Wait for the document to become viewable. The reason we sleep for four 
# seconds is that Document.status_update_threshold is, by default, four seconds. 
# Document.status_update_threshold provides a time-based rate limiting 
# mechanism. 
while !my_document.viewable?
  sleep(4)
end

# Create a viewing session with default settings, and activate it for the user.
session = my_document.viewing_session.activate_for_user(1000, 'Ken Keiter')

# Given a session, get a viewing URL for the document.
viewing_url = my_document.get_viewing_url(session)

puts "You can now view the document at: #{viewing_url}"
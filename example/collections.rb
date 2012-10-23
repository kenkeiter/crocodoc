require 'crocodoc'

# DocumentCollections provide a way to perform operations on sets of documents. 
# A DocumentCollection provides the +Enumerable+ interface, so you can map 
# across its items, etc -- but it also allows you to perform a single status 
# update for multiple Documents in one request, reducing traffic significantly.
#
# In this example, we'll upload an entire directory of documents, and then get 
# all of their statuses.

# Set up crocodoc.
Crocodoc.api_token = "yourapitoken"

# Create a new collection
collection = Crocodoc::DocumentCollection.new

# Find all the files ending in .docx in a directory
Dir.glob('/path/to/my/documents/*.docx').each do |path|
  collection.add_document Crocodoc::Document.upload_file(path)
end

# Give the documents some time to process.
sleep 30

# Update the statuses of all documents in the collection in one request. 
# The statuses will be valid on each item for only 
# Document.status_update_threshold seconds.
collection.update_statuses

# Print out a checklist of all the documents that are viewable.
collection.each do |uuid, doc|
  puts "[#{doc.viewable? ? 'X' : ' '}] #{uuid}"
end
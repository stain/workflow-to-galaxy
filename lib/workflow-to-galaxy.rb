require 'workflow-to-galaxy/galaxy'
require 'workflow-to-galaxy/constants'


module WorkflowToGalaxy  # TODO rename to WorkflowWrappers?
    
end

# Add methods to the String class to operate on file paths.
class String

  # :call-seq:
  #   str.to_filename -> string
  #
  # Returns a new String with spaces substituted by underscores and
  # removes all special characters.
  def to_filename
    self.gsub(/ /, '_').gsub(/[^A-Za-z0-9_]/, '')
  end

end

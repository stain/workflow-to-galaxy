#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'myexperiment-rest'
require 'generator'

include MyExperimentREST
include Generator


# Set up and parse arguments
out_file = ""
t2_server = ""
opts = OptionParser.new do |opt|
  opt.banner = "Usage: workflow_to_galaxy [options] <myExperiement-workflow>"
  opt.separator ""
  opt.separator "Generates a Galaxy tool (a UI xml definition plus a script) for the "
  opt.separator "specified Taverna2 workflow, where <myExperiment-workflow> is "
  opt.separator "the full URL of the workflow in the myExperiment website. Available "
  opt.separator "options are:"

  opt.on("-o OUTPUT", "--output=OUTPUT", "The file name(s) of the generated tool. " +
    "If it is not specified then the workflow's name will be used.") do |val|
    out_file = val if val != nil
  end

  opt.on("-s SERVER", "--server=SERVER", "The taverna server that the script will request execution from. " +
    "If it is not specified then 'http://localhost:8980/taverna-server' will be used.") do |val|
    t2_server = val if val != nil
  end
end

opts.parse!

# Read and check workflow URL
url = ARGV.shift
if url == nil
  puts opts
  exit 1
end

# Get workflow data from myexperiment
me_rest = ReadWorkflow.new(url)

# Set output files
if out_file != ""
  xml_file = "#{out_file}.xml"
  script_file = "#{out_file}.rb"
else
  xml_file = "#{me_rest.workflow.title}".gsub(/\W/, '') + ".xml"
  script_file = "#{me_rest.workflow.title}".gsub(/\W/, '') + ".rb"
end

# Set taverna server
if t2_server == ""
  t2_server = "http://localhost:8980/taverna-server"
end



generate_xml(me_rest, xml_file)
generate_script(me_rest, t2_server, script_file)



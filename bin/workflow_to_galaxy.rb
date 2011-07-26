#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 't2flow/model.rb'
require 't2flow/parser.rb'
require 'cgi'
require 'myexperiment-rest'
require 'workflow-to-galaxy'

include MyExperimentREST
include Generator


# Populates and returns a _TavernaWorkflow_ object (same as in
# myexperiment-rest) from a local t2flow file.
def populate_taverna_workflow_from_t2flow(t2flow)
  t2flow_file = File.new(t2flow, "r")
  parsed_t2flow = T2Flow::Parser.new.parse(t2flow_file)

  wkf_title = parsed_t2flow.name
  wkf_descr = parsed_t2flow.main.annotations.descriptions[0]    # gets only the first
  wkf_sources = []
  parsed_t2flow.main.sources.each do |s|
    wkf_sources << TavernaIOData.new(s.name, 
                                     s.descriptions ? CGI.escapeHTML(s.descriptions.to_s) : [],
                                     s.example_values ? s.example_values : [])
  end
  wkf_sinks = []
  parsed_t2flow.main.sinks.each do |s|
    wkf_sinks << TavernaIOData.new(s.name,
                                   s.descriptions ? CGI.escapeHTML(s.descriptions.to_s) : [],
                                   s.example_values ? s.example_values : [])
  end

  workflow = TavernaWorkflow.new(TavernaWorkflow::T2_FLOW, t2flow, wkf_title, wkf_descr, wkf_sources, wkf_sinks)

end


# Set up and parse arguments
out_file = ""
t2_server = ""
options = {}
opts = OptionParser.new do |opt|
  opt.banner = "Usage: workflow_to_galaxy [options] <myExperiement-workflow> | <t2flow-file>"
  opt.separator ""
  opt.separator "Generates a Galaxy tool (a UI xml definition plus a script) for the "
  opt.separator "specified Taverna2 workflow, where <myExperiment-workflow> is "
  opt.separator "the full URL of the workflow in the myExperiment website. Alternatively "
  opt.separator "a t2flow file can be passed for workflows not in myExperiment. Available "
  opt.separator "options are:"

  opt.on("-o OUTPUT", "--output=OUTPUT", "The file name(s) of the generated tool. " +
    "If it is not specified then the workflow's name will be used.") do |val|
    out_file = val if val != nil
  end

  opt.on("-s SERVER", "--server=SERVER", "The taverna server that the script will request execution from. " +
    "If it is not specified then 'http://localhost:8980/taverna-server' will be used.") do |val|
    t2_server = val if val != nil
  end

  opt.on("-t", "--t2flow", "The workflow is a t2flow file. ") do
    options[:t2flow] = true
  end
end

opts.parse!

# Read and check workflow URL or file
url = ARGV.shift
if url == nil
  puts opts
  exit 1
end

# Object to store the workflow object
wkf_data = nil

if options[:t2flow]
  # Parse local t2flow file -- a _Taverna_Workflow_ object is returned
  wkf_data = populate_taverna_workflow_from_t2flow(url)
else
  # Get workflow data from myexperiment -- a _Taverna_Workflow_ object is returned
  wkf_data = Workflows.new.read(url)
end

# Set output files
if out_file != ""
  xml_file = "#{out_file}.xml"
  script_file = "#{out_file}.rb"
else
  xml_file = "#{wkf_data.title}".gsub(/\W/, '') + ".xml"
  script_file = "#{wkf_data.title}".gsub(/\W/, '') + ".rb"
end

# Set taverna server if not specified
t2_server = "http://localhost:8980/taverna-server"  if t2_server == ""



# Generate Galaxy tool's files
xml_file_ob = File.open(xml_file, "w")
generate_xml(wkf_data, xml_file, xml_file_ob)
xml_file_ob.close

script_file_ob = File.open(script_file, "w")
generate_script(wkf_data, t2_server, script_file_ob)
script_file_ob.close

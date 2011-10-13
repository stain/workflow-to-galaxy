#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'cgi'
require 'workflow-to-galaxy'

include WorkflowToGalaxy


# Set up and parse arguments
out_file = ""
t2_server = ""
options = {}
opts = OptionParser.new do |opt|
  opt.banner = "Usage: workflow_to_galaxy [options] <myExperiment-workflow> | <t2flow-file>"
  opt.separator ""
  opt.separator "Generates a Galaxy tool (a UI xml definition plus a script) for the "
  opt.separator "specified Taverna2 workflow, where <myExperiment-workflow> is the full "
  opt.separator "URL of the workflow in the myExperiment website. Alternatively a t2flow "
  opt.separator "file can be passed for workflows not in myExperiment. Available options "
  opt.separator "are:"

  opt.on("-o OUTPUT", "--output=OUTPUT", "The file name(s) of the generated tool.",
                                         "If it is not specified then the",
                                         "workflow's name will be used.") do |val|
    out_file = val if val != nil
  end

  opt.on("-s SERVER", "--server=SERVER", "The taverna server that the script will",
                                         "request execution from. If not specified",
                                         "'http://localhost:8080/taverna-server'",
                                         "will be used.") do |val|
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

# Set taverna server if not specified
t2_server ||= "http://localhost:8080/taverna-server"


#if options[:t2flow]
#  wkf_source =
#else
#  wkf_source = Workflows::MYEXPERIMENT_TAVERNA2
#end

# create file handlers
if out_file != ""
  xml_out = open("#{out_file}.xml", "w")
  rb_out = open("#{out_file}.rb", "w")
end


# create generator or wrapper (could have used url for t2flow key to avoid
# if/else but future sources would still need them)
if options[:t2flow]
  if out_file != ""
    wkf = GalaxyTool.new(:wkf_source => Workflows::T2FLOW,
                         :params => {:t2_server => t2_server,
                                     :t2flow => url,
                                     :xml_out => xml_out,
                                     :rb_out => rb_out } )
  else
    wkf = GalaxyTool.new(:wkf_source => Workflows::T2FLOW,
                         :params => {:t2_server => t2_server,
                                     :t2flow => url } )
  end
else
  if out_file != ""
    wkf = GalaxyTool.new(:wkf_source => Workflows::MYEXPERIMENT_TAVERNA2,
                         :params => {:t2_server => t2_server,
                                     :url => url,
                                     :xml_out => xml_out,
                                     :rb_out => rb_out } )
  else
    wkf = GalaxyTool.new(:wkf_source => Workflows::MYEXPERIMENT_TAVERNA2,
                         :params => {:t2_server => t2_server,
                                     :url => url } )
  end
end

# close file handlers
if out_file != ""
  xml_out.close
  rb_out.close
end

wkf.generate


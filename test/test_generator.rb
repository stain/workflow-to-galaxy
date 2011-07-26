# put lib dir in load path
$LOAD_PATH.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'myexperiment-rest'
require 'workflow-to-galaxy'

include MyExperimentREST
include Generator

class TestGenerator < Test::Unit::TestCase

  def setup
    @wkf = MyExperimentREST::Workflows.new.read('http://www.myexperiment.org/workflows/74/download/bioaid_proteindiscovery_221429.xml?version=3')
    Dir.chdir("test")
    File.open("BioAID_ProteinDiscovery.xml", "w") do |file|
      generate_xml(@wkf, "BioAID_ProteinDiscovery.xml", file)
    end
    File.open("BioAID_ProteinDiscovery.rb", "w") do |file|
      generate_script(@wkf, "http://localhost:8980/taverna-server", file)
    end
  end


  def test_xml_script_files
    File.open("BioAID_ProteinDiscovery.xml", "r") do |i|
      generated = i.read
      expected =  IO.read("Expected_BioAID_ProteinDiscovery_xml")
      assert_equal(generated, expected, "Generated XML differs from expected XML file!")
    end

    File.open("BioAID_ProteinDiscovery.rb", "r") do |i|
      generated = i.read
      expected =  IO.read("Expected_BioAID_ProteinDiscovery_rb")
      assert_equal(generated, expected, "Generated script differs from expected script file!")
    end

  end


  def teardown
    File.delete("BioAID_ProteinDiscovery.xml", "BioAID_ProteinDiscovery.rb")
  end


end

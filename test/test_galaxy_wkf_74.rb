# put lib dir in load path
$LOAD_PATH.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'workflow-to-galaxy'

include WorkflowToGalaxy

class TestGalaxyWkf74 < Test::Unit::TestCase

  def setup
    Dir.chdir("test")
    xml = File.open("BioAID_ProteinDiscovery.xml", "w")
    rb = File.open("BioAID_ProteinDiscovery.rb", "w")
    wkf = GalaxyTool.new(:wkf_source => Workflows::MYEXPERIMENT_TAVERNA2,
                         :params => {:t2_server => "http://test.mybiobank.org/taverna-server",
                                     :url => 'http://www.myexperiment.org/workflows/74/download/bioaid_proteindiscovery_781733.xml?version=5',
                                     :xml_out => xml,
                                     :rb_out => rb } )
    wkf.generate
    xml.close
    rb.close
  end


  def test_xml_script_files
    File.open("BioAID_ProteinDiscovery.xml", "r") do |i|
      generated = i.read
      expected =  IO.read("expected/BioAID_ProteinDiscovery_xml")
      assert_equal(generated, expected, "Generated XML differs from expected XML file!")
    end

    File.open("BioAID_ProteinDiscovery.rb", "r") do |i|
      generated = i.read
      expected =  IO.read("expected/BioAID_ProteinDiscovery_rb")
      assert_equal(generated, expected, "Generated script differs from expected script file!")
    end

  end


  def teardown
    File.delete("BioAID_ProteinDiscovery.xml", "BioAID_ProteinDiscovery.rb")
    Dir.chdir("..")
  end


end

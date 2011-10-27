# put lib dir in load path
$LOAD_PATH.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'workflow-to-galaxy'

include WorkflowToGalaxy

class TestGalaxyWkf823 < Test::Unit::TestCase

  def setup
    Dir.chdir("test")
    @wkf = GalaxyTool.new(:wkf_source => Workflows::MYEXPERIMENT_TAVERNA2,
                         :params => {:t2_server => "http://test.mybiobank.org/taverna-server",
                                     :url => 'http://www.myexperiment.org/workflows/823/download/fetch_pdb_flatfile_from_rcsb_server_58764.t2flow?version=1' } )
    @wkf.generate
  end


  def test_xml_script_files
    # get the name dynamically
    # TODO: delete other special characters!!
    File.open(@wkf.wkf_object.title.gsub(/ /, '_') + ".xml", "r") do |i|
      generated = i.read
      expected =  IO.read("expected/" + @wkf.wkf_object.title.gsub(/ /, '_') + "_xml")
      assert_equal(generated, expected, "Generated XML differs from expected XML file!")
    end

    File.open(@wkf.wkf_object.title.gsub(/ /, '_') + ".rb", "r") do |i|
      generated = i.read
      expected =  IO.read("expected/" + @wkf.wkf_object.title.gsub(/ /, '_') + "_rb")
      assert_equal(generated, expected, "Generated script differs from expected script file!")
    end

  end


  def teardown
    File.delete(@wkf.wkf_object.title.gsub(/ /, '_') + ".xml", @wkf.wkf_object.title.gsub(/ /, '_') + ".rb")
    Dir.chdir("..")
  end


end

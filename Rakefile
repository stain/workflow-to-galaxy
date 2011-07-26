# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rubygems/package_task'
require 'rdoc/task'

spec = Gem::Specification.new do |s|
  s.name = 'workflow-to-galaxy'
  s.version = '0.2.9'
  s.extra_rdoc_files = ['README', 'LICENSE', 'CHANGES']
  s.summary = 'This script acquires information for a taverna 2 workflow from myExperiment (or from a file) and generates a Galaxy tool (.xml and .rb files).'
  s.description = s.summary
  s.author = 'Kostas Karasavvas'
  s.email = 'kostas.karasavvas@nbic.nl'
  s.executables = ['workflow_to_galaxy.rb']
  s.files = %w(LICENSE README CHANGES Rakefile) + Dir.glob("{bin,lib,doc,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
  s.add_dependency 'myexperiment-rest', '>= 0.2.6'
  s.add_dependency 'taverna-t2flow', '>= 0.2.0'
  s.add_dependency 't2-server', '>= 0.5.3'
  s.add_dependency 'rubyzip', '>= 0.9.4'
end

Gem::PackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

RDoc::Task.new do |rdoc|
  files =['README', 'LICENSE', 'CHANGES', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "workflow-to-galaxy Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end


# copies galaxy tool's files to local galaxy installation
task :copy_to_galaxy do
  cp 'bin/BioAID_ProteinDiscovery.xml', '/home/kostas/local/galaxy-dist/tools/taverna_tools'
  cp 'bin/BioAID_ProteinDiscovery.rb', '/home/kostas/local/galaxy-dist/tools/taverna_tools'
end

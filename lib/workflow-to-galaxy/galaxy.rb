require 'myexperiment-rest'
require 't2flow/model.rb'
require 't2flow/parser.rb'


module WorkflowToGalaxy
  include MyExperimentREST


  #
  # The _GalaxyTool_ class contains a +generate+ public method that generates the
  # required files (XML and script) for a Galaxy tool. 
  #
  class GalaxyTool

    # +config+ contains data needed in relation to what the tool will do and
    # +wkf_object+ contains the workflow object that will be used to generate
    # the galaxy tool
    attr_accessor :wkf_object, :config

    
    # Instantiates a galaxy tool generator.
    # +config+ is a hash:
    #
    # :wkf_source (initial workflow input, see Workflows module)
    # :params     (a hash with the following parameters -- MYEXPERIMENT_TAVERNA2)
    #   :t2_server  (the t2 server)
    #   :url        (the myexperiment workflow URL)
    #   :xml_out    (the file handle for the generated xml -- optional)
    #   :rb_out    (the file handle for the generated rb -- optional)
    #
    # :params     (a hash with the following parameters -- T2FLOW)
    #   :t2flow   (the file name and path)
    #   :xml_out    (the file handle for the generated xml -- optional)
    #   :rb_out    (the file handle for the generated rb -- optional)

    #-
    # TODO: does initialize appear in rdoc? -- these will go to README as well...
    def initialize(config)
      @config = config
    end



    # private methods
    private

    # Used to create indentation when generating code
    def indent(n)
      ind = ""
      n.times { ind += "  "  }
      ind
    end

    # Galaxy's XML tool tag
    def tool_begin_tag(out, name)
      # wkf title is used for id but spaces are changed to underscores
      # TODO: delete other special characters!!
      out.write("<tool id=\"#{name.gsub(/ /, '_')}_id\" name=\"#{name}\">\n")
    end

    # Galaxy's XML command tag
    def command_tag(out, t2_workflow, script)
      out.write indent(1) + "<command interpreter=\"ruby\">\n"
      out.write indent(2) + script + "\n"

      # inputs
      t2_workflow.inputs.each do |i|
        out.write indent(2) + "#if $#{i.name}_source.history_or_textfield == \"textfield\":\n"
        out.write indent(3) + "false \"$#{i.name}_source.textfield_#{i.name}\"\n"
        out.write indent(2) + "#else:\n"
        out.write indent(3) + "true  \"$#{i.name}_source.history_#{i.name}\"\n"
        out.write indent(2) + "#end if\n"
      end

      # results as zip input
      out.write indent(2) + "$results_as_zip\n"

      # outputs
      out.write indent(2)
      t2_workflow.outputs.each do |o|
        out.write "$#{o.name} "
      end

      # result zip output
      out.write "$result_zip\n"

      out.write indent(1) + "</command>\n"
    end


    # Galaxy's XML inputs tag
    def inputs_tag(out, inputs)
      out.write indent(1) + "<inputs>\n"
      if inputs.size >= 1
        inputs.each do |i|
          out.write indent(2) + "<conditional name=\"#{i.name}_source\">\n"
          out.write indent(3) + "<param name=\"history_or_textfield\" type=\"select\" label=\"Select source for #{i.name}\">\n"
          out.write indent(4) + "<option value=\"history\">From history</option>\n"
          out.write indent(4) + "<option value=\"textfield\" selected=\"true\">Type manually</option>\n"
          out.write indent(3) + "</param>\n"
          out.write indent(3) + "<when value=\"history\">\n"
          out.write indent(4) + "<param name=\"history_#{i.name}\" type=\"data\" label=\"Select #{i.name}\"/>\n"
          out.write indent(3) + "</when>\n"
          out.write indent(3) + "<when value=\"textfield\">\n"
          out.write indent(4) + "<param name=\"textfield_#{i.name}\" type=\"text\" area=\"True\" size=\"2x50\" "
          if i.examples.size >= 1
            # escape double quotes characters for galaxy's xml file
            ex = i.examples[0].to_s.gsub('"', '&quot;')
            # convert newlines to HTML newlines to display in textareas inputs
            ex = ex.gsub(/[\n]/, '&#xA;')
            out.write "value=\"#{ex}\" "
          end
          out.write "label=\"Enter #{i.name}\"/>\n"
          out.write indent(3) + "</when>\n"
          out.write indent(2) + "</conditional>\n"
        end
      else
        out.write indent(2) + "<param name=\"input\" type=\"select\" display=\"radio\" size=\"250\" label=\"This workflow has no inputs\" />\n"
      end

      # result as zip input
      out.write indent(2) + "<param name=\"results_as_zip\" type=\"select\" label=\"Would you also like the raw results as a zip file\">\n"
      out.write indent(3) + "<option value=\"yes\">Yes</option>\n"
      out.write indent(3) + "<option value=\"no\" selected=\"true\">No</option>\n"
      out.write indent(2) + "</param>\n"

      out.write indent(1) + "</inputs>\n"
    end

    # Galaxy's XML outputs tag
    def outputs_tag(out, outputs)
      out.write indent(1) + "<outputs>\n"
      outputs.each do |o|
        out.write indent(2) + "<data format=\"tabular\" name=\"#{o.name}\" label=\"#{o.name}\"/>\n"
      end

      # result zip output
      out.write indent(2) + "<data format=\"zip\" name=\"result_zip\" label=\"Compressed Results (zip)\">\n"
      out.write indent(3) + "<filter>results_as_zip == \"yes\"</filter>\n"
      out.write indent(2) + "</data>\n"

      out.write indent(1) + "</outputs>\n"
    end

    # Galaxy's XML help tag
    def help_tag(out, t2_workflow)
      out.write indent(1) + "<help>\n"

      if t2_workflow.description
        out.write "**What it does**\n\n"

        description = t2_workflow.description + "\n\n"

        # Sometimes the workflow description contains HTML tags that are not allowed
        # in Galaxy's xml interface specification and thus are removed! Same for
        # HTML entities!
        # TODO go through tags and find Galaxy's equivalent to include
        description.gsub!(/<.*?>|&.*?;/, '')

        # To remove ^M (cntl-v + cntl-m) characters that DOS files might have
        description.gsub!(/\r/, '')

        # TODO that works as a literal too but font changes to courier!
        #out.write "::\n\n"   # Start Galaxy's literal block to ignore indendation

        # remove indendation from all description lines since Galaxy is confused by it
        description.split(/[\n]/).each { |l| out.write "#{l.gsub(/^\s+/, '')}\n" }

        # endline makes the following be parsed as a Galaxy GUI construct
        out.write "\n"
      end

      # if at least one input add it to tool's UI help description
      if t2_workflow.inputs.size >= 1
        out.write "-----\n\n"
        out.write "**Inputs**\n\n"
        t2_workflow.inputs.each do |i|
          out.write "- **#{i.name}** "
          if i.descriptions.size >= 1
            i.descriptions.each do |desc|
              out.write desc.to_s + " "
            end
          end
          if i.examples.size >= 1
            out.write "Examples include:\n\n"
            i.examples.each do |ex|
              # some examples have a newline between them that breaks Galaxy's GUI
              # so we substitute it with ' '
              #out.write "  - " + ex.to_s.gsub(/[\n]/, ' ') + "\n"

              # We could substitute them with with &#xA; that works for HTML (e.g. wkf 1180)
              # But if an example input is truly multiline then input descr. will
              # display them all as separate inputs...
              out.write "  - " + ex.to_s.gsub(/[\n]/, '&#xA;  - ') + "\n"

              # display example inputs as verbatim/literal so it is not our responsibility!!
              # add indendation after each newline to specify the literal block
              # TODO this looks ugly if we don't remove all the bullet points!
              #out.write "::\n\n  " + ex.to_s.gsub(/\n/, '&#xA;  ') + "\n"
            end
          end
          out.write "\n"
        end
        out.write "\n"
      end

      # if at least one output add it to tool's UI help description
      if t2_workflow.outputs.size >= 1
        out.write "-----\n\n"
        out.write "**Outputs**\n\n"
        t2_workflow.outputs.each do |o|
          out.write "- **#{o.name}** "
          if o.descriptions.size >= 1
            o.descriptions.each do |desc|
              out.write desc.to_s + " "
            end
          end
          if o.examples.size >= 1
            out.write "Examples include:\n\n"
            o.examples.each do |ex|
              out.write "  - " + ex.to_s + "\n"
            end
          end
          out.write "\n"
        end
        out.write "\n"
      end

      out.write "-----\n\n"
      out.write ".. class:: warningmark\n\n"
      out.write "**Please note that some workflows are not up-to-date or have dependencies** " <<
                "that cannot be met by the specific Taverna server that you specified during " <<
                "generation of this tool. You can make sure that the workflow is valid " <<
                "by running it in the Taverna Workbench first to confirm that it works " <<
                "before running it via Galaxy.\n\n"

      if @config[:wkf_source] == Workflows::MYEXPERIMENT_TAVERNA2
        out.write "-----\n\n"
        out.write ".. class:: warningmark\n\n"
        out.write "**Please note that there might be some repetitions in the workflow description** " <<
                  "in some of the generated workflows. This is due to a backwards compatibility " <<
                  "issue on the myExperiment repository which keeps the old descriptions to make " <<
                  "sure that no information is lost.\n\n"

        out.write "-----\n\n"
        out.write ".. class:: infomark\n\n"
        out.write "**For more information on that workflow please visit** #{t2_workflow.content_uri.gsub(/(.*workflows\/\d+)[\/.].*/, '\1')}.\n\n"
      end

      out.write indent(1) + "</help>\n"
    end

    # Galaxy's XML tool tag close
    def tool_end_tag(out)
      out.write("</tool>\n")
    end



    # Galaxy's script preample
    def script_preample(out)
      out.write("#!/usr/bin/env ruby\n\n")

      out.write("# This script can be tested without Galaxy. You can run from the shell as follows:\n#\n")
      out.write("#   $ script_name.rb <input1> true|false <input2> true|false  yes|no  <output1> <output2>\n#\n")
      out.write("# After each input value a boolean specifies if the value is literal (false) or if\n")
      out.write("# it specifies a file name to read as input.\n#\n")
      out.write("# After all workflow inputs a yes or no input specifies if we also want our results zipped.\n#\n")
      out.write("# Finally, all the output files follow. Note that if you selected to also get a zip\n")
      out.write("# then you need to specify an additional output in the end after the normal workflow\n")
      out.write("# outputs.\n\n")

      out.write("require 'rubygems'\n")
      out.write("require 't2-server'\n")
      out.write("require 'open-uri'\n")
      out.write("require 'zip/zipfilesystem'\n\n")
    end


    # Galaxy's script utility methods
    # TODO: use ruby's flatten instead of our own !!!
    def script_util_methods(out)

      out.write <<'UTIL_METHODS'

  # sends the zip file to specified output
  def output_zip_file(uuid, zip_out)
    File.open("/tmp/#{uuid}.zip") do |zip|
      while data = zip.read(4096)
        zip_out.write data
      end
    end
    File.delete("/tmp/#{uuid}.zip")
  end


  #
  # replicates the directory result structure as constructed by the
  # taverna server and recreates it in a zip File
  #
  def add_to_zip_file(output_dir, data_lists, zip_out)
    zip_out.dir.mkdir("#{output_dir}")
    data_lists.each_with_index do |item, index|
      if item.instance_of? Array
        add_to_zip_file("#{output_dir}/#{index+1}", item, zip_out)
      else
        zip_out.file.open("#{output_dir}/#{index+1}", "w") { |f| f.puts item }
      end
    end
  end


  # method that flattens the list of list of list ... result of get_output
  def print_flattened_result(out, data_lists)
    data_lists.each do |l|
      if l.instance_of? Array
        print_flattened_result(out, l)
      else
        out.puts l
      end
    end
  end


  #
  # Method that acquires all the results of the specified output directory.
  # If valid zip File is passed it also accumulates results as a zip file.
  #
  def get_outputs(run, refs, outfile, dir, zip_out=nil)
    data_lists = run.get_output(dir, refs)
    print_flattened_result(outfile, data_lists)
    if zip_out
      add_to_zip_file(dir, data_lists, zip_out)
    end
  end


  #
  # Sanitize all special characters in UI inputs that Galaxy substitutes for
  # security reasons. This methods turns them back to their original values before
  # using them (i.e. sending them to the taverna server
  # NB: note that double quote is sanitized to "'" that is because the double code
  #     confuses the Taverna server ruby library. Apparently, this is not trivial
  #     to fix.
  #
  def sanitize(string)
    string.gsub(/(__sq__|__dq__|__at__|__cr__|__cn__|__tc__|__gt__|__lt__|__ob__|__cb__|__oc__|__cc__)/) do
      if $1 == '__sq__'
        "'"
      elsif $1 == '__dq__'
        "'"
      elsif $1 == '__cr__'
        "\r"
      elsif $1 == '__cn__'
        "\n"
      elsif $1 == '__tc__'
        "\t"
      elsif $1 == '__gt__'
        '>'
      elsif $1 == '__lt__'
        '<'
      elsif $1 == '__ob__'
        '['
      elsif $1 == '__cb__'
        ']'
      elsif $1 == '__oc__'
        '{'
      elsif $1 == '__cc__'
        '}'
      else
        '@'
      end
    end
  end

  #
  # Deletes last new line of file if it exists! It is needed for t2 workflows that
  # do not sanitize properly, i.e. via a user-provided beanshell script
  #
  def chomp_last_newline(file)

    if File.file?(file) and File.size(file) > 1
      f = open(file, "rb+")
      f.seek(-1, File::SEEK_END)
      f.truncate(File.size(file) - 1) if f.read(1) == "\n"
      f.close
    end

  end


UTIL_METHODS

    end

    # Galaxy's script taverna 2 run
    def script_create_t2_run(out, wkf, t2_uri)
      if @config[:wkf_source] == Workflows::MYEXPERIMENT_TAVERNA2
        out.write "# use the uri reference to download the workflow locally\n"
        out.write "wkf_file = URI.parse('#{wkf.content_uri}')\n"
        out.write "in_wkf = open(wkf_file)\n"
      else     # Workflows::T2FLOW
        out.write "# uri contains local t2flow file\n"
        out.write "in_wkf = open('#{wkf.content_uri}')\n"
      end

      out.write <<CREATE_T2_RUN

  wkf = in_wkf.read()

  # create run
  begin
    run = T2Server::Run.create('#{t2_uri}', wkf)
  rescue T2Server::T2ServerError => e
    exit 1
  end

CREATE_T2_RUN

    end


    # Galaxy's script input handling
    def script_init_inputs(out, t2_workflow)
      out.write "#\n"
      out.write "# Get input arguments -- for each input a boolean specifies if it's from history\n"
      out.write "# thus, for each t2_workflow input we have two arguments in the script!\n"
      out.write "#\n"
      t2_workflow.inputs.each_with_index do |input, i|
        i_name = input.name.to_s
        out.write "#{i_name}_from_history = ARGV[#{i*2}].chomp\n"
        out.write "#{i_name}_tmp = ARGV[#{i*2+1}].chomp\n"
        out.write "if #{i_name}_from_history == \"true\"\n"
        out.write "  chomp_last_newline(#{i_name}_tmp)\n"
        out.write "  run.upload_input_file('#{i_name}', #{i_name}_tmp)\n"
        out.write "else\n"
        out.write "  run.set_input('#{i_name}', sanitize(#{i_name}_tmp))\n"
        out.write "end\n"
      end

      # add code to handle results_as_zip input, i.e. create zip file
      out.write "\n# get results_as_zip input and open zip file if appropriate\n"
      # get argument index after workflow inputs
      zip_index = t2_workflow.inputs.size * 2
      out.write "zipped = ARGV[#{zip_index}].chomp == \"yes\"\n"
      out.write 'zip_out = Zip::ZipFile.open("/tmp/#{run.uuid}.zip", Zip::ZipFile::CREATE) if zipped' + "\n"

    end


    # Galaxy's script starting taverna run
    def script_start_run(out)
      out.write <<START_RUN


  # start run and wait until it is finished
  run.start
  run.wait(:progress => true)

START_RUN
    end


    # Galaxy's script output handling
    def script_get_outputs(out, t2_workflow)
      # outputs start after all inputs plus the results_as_zip input
      outputs_start_index = t2_workflow.inputs.size * 2 + 1
      outputs_end_index = outputs_start_index + t2_workflow.outputs.size - 1
      out.write "# get output arguments and associated them with a file\n"
      outputs_start_index.upto(outputs_end_index) do |o|
        out.write "output#{o} = File.open(ARGV[#{o}], \"w\")\n"
        out.write "begin\n"
        out.write "  get_outputs(run, false, output#{o}, '" + t2_workflow.outputs[o - outputs_start_index].name.to_s + "', zip_out)\n"
        out.write "rescue Exception => err\n"
        out.write "  get_outputs(run, false, output#{o}, '" + t2_workflow.outputs[o - outputs_start_index].name.to_s + ".error', zip_out)\n"
        out.write "ensure\n"
        out.write "  output#{o}.close\n"
        out.write "end\n"
      end

      # close zip file if created when dealing with the inputs
      #--
      # ideally that would semantically belong to a separate method
      out.write "\n# close zip_out (the newly created zip file) if opened\n"
      out.write "zip_out.close if zip_out\n"

      # dealing with zip output here -- zip arg index is outputs_end_index (last
      # output) plus 1
      out.write "\n# open galaxy zip output and write zip file\n"
      out.write "if zipped\n"
      out.write "  galaxy_zip_out = File.open(ARGV[#{outputs_end_index+1}], \"w\")\n"
      out.write "  output_zip_file(run.uuid, galaxy_zip_out)\n"
      out.write "  galaxy_zip_out.close\n"
      out.write "end\n"

    end


    # Galaxy's script cleaning taverna run
    def script_finish_run(out)
      out.write "\n# delete run\n"
      out.write "run.delete\n"
    end



    # Generates the Galaxy tool's xml file responsible for the UI.
    # TODO: maybe clean arguments -- only xml_out is needed to be passed
    def generate_xml(t2_workflow, xml_out)
      tool_begin_tag(xml_out, t2_workflow.title)
      command_tag(xml_out, t2_workflow, xml_out.path.match('([^\/]+)\..*$')[1] + '.rb')
      inputs_tag(xml_out, t2_workflow.inputs)
      outputs_tag(xml_out, t2_workflow.outputs)
      help_tag(xml_out, t2_workflow)
      tool_end_tag(xml_out)
    end


    # Generates the Galaxy tool's script file responsible for talking to the
    # taverna server
    # TODO: maybe clean arguments -- only xml_out is needed to be passed
    def generate_rb(t2_workflow, script_out, t2_server)
      script_preample(script_out)
      script_util_methods(script_out)
      script_create_t2_run(script_out, t2_workflow, t2_server)
      script_init_inputs(script_out, t2_workflow)
      script_start_run(script_out)
      script_get_outputs(script_out, t2_workflow)
      script_finish_run(script_out)
    end


    # Populates and returns a _MyExperimentWorkflow_ object (same as in
    # myexperiment-rest) from a local t2flow file.
    def populate_taverna_workflow_from_t2flow(t2flow)
      t2flow_file = File.new(t2flow, "r")
      parsed_t2flow = T2Flow::Parser.new.parse(t2flow_file)

      wkf_title = parsed_t2flow.name
      wkf_descr = parsed_t2flow.main.annotations.descriptions[0]    # gets only the first
      wkf_uploader_uri = parsed_t2flow.main.annotations.authors[0]
      wkf_sources = []
      parsed_t2flow.main.sources.each do |s|
        wkf_sources << MyExperimentIOData.new(:name => s.name,
                                              :descriptions => s.descriptions ? CGI.escapeHTML(s.descriptions.to_s) : [],
                                              :examples => s.example_values ? s.example_values : [])
      end
      wkf_sinks = []
      parsed_t2flow.main.sinks.each do |s|
        wkf_sinks << MyExperimentIOData.new(:name => s.name,
                                            :descriptions => s.descriptions ? CGI.escapeHTML(s.descriptions.to_s) : [],
                                            :examples => s.example_values ? s.example_values : [])
      end

      workflow = MyExperimentWorkflow.new(:content_uri => t2flow,
                                          :title => wkf_title,
                                          :description => wkf_descr,
                                          :inputs => wkf_sources,
                                          :outputs => wkf_sinks,
                                          :uploader_uri => wkf_uploader_uri)

    end



    # public methods from here onwards
    public

    #
    # Generates the two files needed for a Galaxy tool: a configuration
    # file (XML) and a processing file (in our case a ruby script)
    #
    # :call-seq:
    #   GalaxyTool.generate() -> nil
    #
    def generate

      # check the type of workflow source and acquire the appropriate data
      if(config[:wkf_source] == Workflows::MYEXPERIMENT_TAVERNA2)

        # TODO: check and add auth stuff -- even more unsafe with session cookies
        # since the myexp username/passwd will be saved in the galaxy ruby script
        # for all to see...

        begin
          # Get workflow data from myexperiment -- a _MyExperimentWorkflow_ object is returned
          @wkf_object = MyExperimentREST::Workflow.from_uri(@config[:params][:url])
        rescue Exception => e
          raise "Problem acquiring workflow data from myExperiment!\n" + e
        end

      elsif(config[:wkf_source] == Workflows::T2FLOW)

        begin
          # Get workflow data from t2flow file -- a _MyExperimentWorkflow_ object is returned
          @wkf_object = populate_taverna_workflow_from_t2flow(@config[:params][:t2flow])
        rescue Exception => e
          raise "Problem acquiring workflow data from t2flow file!\n" + e
        end

      else
        raise "No such workflow source supported!"
      end

      # if an xml_out file handler was not given provide one with the title as the value
      if @config[:params][:xml_out]
        generate_xml(@wkf_object, @config[:params][:xml_out])
      else
        xml_out = open(@wkf_object.title.gsub(/ /, '_') + ".xml", "w")
        generate_xml(@wkf_object, xml_out)
        xml_out.close
      end

      # if an rb_out file handler was not given provide one with the title as the value
      if @config[:params][:rb_out]
        generate_rb(@wkf_object, @config[:params][:rb_out], @config[:params][:t2_server])
      else
        rb_out = open(@wkf_object.title.gsub(/ /, '_') + ".rb", "w")
        generate_rb(@wkf_object, rb_out, @config[:params][:t2_server])
        rb_out.close
      end

      
    end


  end  # class GalaxyTool

end  # module 

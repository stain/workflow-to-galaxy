
# Contains code to generate the Galaxy's tool xml and script files
module Generator

  INDENT = "  "


  # private methods
  private

  def tool_b(out, name)
    out.write("<tool id=\"#{name}_id\" name=\"#{name}\">\n")
  end

  def command_be(out, me_rest, script)
    out.write "#{INDENT}<command interpreter=\"ruby\">"
    out.write script + " "
    me_rest.workflow.inputs.each do |i|
      out.write "\"$#{i.name}\" "
    end
    me_rest.workflow.outputs.each do |o|
      out.write "$#{o.name} "
    end
    out.write "</command>\n"
  end

  def inputs_be(out, inputs)
    out.write "#{INDENT}<inputs>\n"
    if inputs.size >= 1
      inputs.each do |i|
        2.times { out.write "#{INDENT}" }
        out.write "<param name=\"#{i.name}\" type=\"text\" size=\"30\" "
        if i.examples.size >= 1
          # escape double quotes characters for galaxy's xml file
          ex = i.examples[0].to_s.gsub('"', '&quot;')
          out.write "value=\"#{ex}\" "
        end
        out.write "label=\"Enter #{i.name}\"/>\n"
      end
    else
      2.times { out.write "#{INDENT}" }
      out.write "<param name=\"input\" type=\"select\" display=\"radio\" size=\"250\" label=\"This workflow has no inputs\" />\n"
    end  
    out.write "#{INDENT}</inputs>\n"
  end

  def outputs_be(out, outputs)
    out.write "#{INDENT}<outputs>\n"
    outputs.each do |o|
      2.times { out.write "#{INDENT}" }
      out.write "<data format=\"tabular\" name=\"#{o.name}\" label=\"#{o.name}\"/>\n"
    end
    out.write "#{INDENT}</outputs>\n"
  end

  def help_be(out, me_rest)
    out.write "#{INDENT}<help>\n"
    out.write "**What it does**\n\n"

    # Sometimes the workflow description contains HTML tags that are not allowed
    # in Galaxy's xml interface specification and thus are removed! Same for
    # HTML entities!
    out.write me_rest.workflow.description.gsub(/<.*?>|&.*?;/, '') + "\n\n"

    if me_rest.workflow.inputs.size >= 1
      out.write "-----\n\n"
      out.write "**Inputs**\n\n"
      me_rest.workflow.inputs.each do |i|
        out.write "- **#{i.name}** "
        if i.descriptions.size >= 1
          i.descriptions.each do |desc|
            out.write desc.to_s + " "
          end
        end
        if i.examples.size >= 1
          out.write "Examples include:\n\n"
          i.examples.each do |ex|
            out.write "  - " + ex.to_s + "\n"
          end
        end
        out.write "\n"
      end
      out.write "\n"
    end

    # TODO this code is identical to the inputs code above -- method?
    if me_rest.workflow.outputs.size >= 1
      out.write "-----\n\n"
      out.write "**Outputs**\n\n"
      me_rest.workflow.outputs.each do |o|
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
    out.write "For more information on that workflow please visit #{me_rest.uri.gsub(/(.*workflows\/\d+)[\/.].*/, '\1')}.\n"

    out.write "#{INDENT}</help>\n"
  end

  def tool_e(out)
    out.write("</tool>\n")
  end




  def script_preample(out)
    out.write("#!/usr/bin/env ruby\n\n")
    out.write("require 'rubygems'\n")
    out.write("require 't2-server'\n")
    out.write("require 'open-uri'\n\n")
  end

  def script_util_methods(out)

    out.write <<UTIL_METHODS
    
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


  # method that acquires all the results of the specified output
  def get_outputs(run, refs, outfile, dir)
    data_lists = run.get_output(dir, refs)
    print_flattened_result(outfile, data_lists)
  end


  #
  # Sanitize single and double quotes in str. E.g. galaxy substitures them to
  # __sq__ and __dq__ respectively. This methods turns them back to their
  # original values before using them
  #
  def sanitize(string)
    string.gsub(/(__sq__|__dq__|__at__)/) do
      if $1 == '__sq__'
        "'"
      elsif $1 == '__dq__'
        '\\\"'
      else
        '@'
      end
    end
  end

UTIL_METHODS

  end


  def script_create_t2_run(out, wkf_uri, t2_uri)
    out.write <<CREATE_T2_RUN

# use the uri reference to download the workflow locally
wkf_file = URI.parse('#{wkf_uri}')
in_wkf = open(wkf_file)
wkf = in_wkf.read()

# create run
begin
  run = T2Server::Run.create('#{t2_uri}', wkf)
rescue T2Server::T2ServerError => e
  exit 1
end

CREATE_T2_RUN

  end


  def script_init_inputs(out, me_rest)
    out.write "# get input arguments\n"
    0.upto(me_rest.workflow.inputs.size-1) do |i|
      out.write "input#{i}_arg = ARGV[#{i}].chomp\n"
      out.write "run.set_input('" + me_rest.workflow.inputs[i].name.to_s + "', sanitize(input#{i}_arg))\n"
    end

  end


  def script_start_run(out)
    out.write <<START_RUN

# start run and wait until it is finished
run.start
run.wait(:progress => true)

START_RUN
  end


  def script_get_outputs(out, me_rest)
    outputs_start_index = me_rest.workflow.inputs.size
    outputs_end_index = outputs_start_index + me_rest.workflow.outputs.size - 1
    out.write "# get output arguments and associated them with a file\n"
    outputs_start_index.upto(outputs_end_index) do |o|
      out.write "output#{o} = File.open(ARGV[#{o}], \"w\")\n"
      out.write "get_outputs(run, false, output#{o}, '" + me_rest.workflow.outputs[o - outputs_start_index].name.to_s + "')\n"
    end

  end


  def script_finish_run(out)
    out.write "\n# delete run\n"
    out.write "run.delete\n"
  end



  # public methods from here onwards
  public

  # Generates the Galaxy tool's xml file responsible for the UI.
  def generate_xml(me_rest, xml_file)
    out = File.open(xml_file, "w")
    tool_b(out, me_rest.workflow.title)
    command_be(out, me_rest, xml_file.gsub('.xml', '.rb'))
    inputs_be(out, me_rest.workflow.inputs)
    outputs_be(out, me_rest.workflow.outputs)
    help_be(out, me_rest)
    tool_e(out)
    out.close
  end

  #
  # Generates the Galaxy tool's script file responsible for talking to the
  # taverna server
  #
  def generate_script(me_rest, t2_server, script_file)
    out = File.open(script_file, "w")
    script_preample(out)
    script_util_methods(out)
    script_create_t2_run(out, me_rest.uri, t2_server)
    script_init_inputs(out, me_rest)
    script_start_run(out)
    script_get_outputs(out, me_rest)
    script_finish_run(out)
    out.close
  end

end

require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UtilityBillCalculationsTest < MiniTest::Test
  
  def test_create_timeseries_csv
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OutputMeter"=>90}
    expected_values = {}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_AllConstructions_Furnace_CentralAC_Setpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 90, 84)  
  end
  
  def test_parse_timeseries_csv
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OutputMeter"=>90}
    expected_values = {}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_AllConstructions_Furnace_CentralAC_Setpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 90, 84, false, false)  
  end  

  def test_number_of_arguments
    # create an instance of the measure
    measure = UtilityBillCalculations.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    assert_equal(1, arguments.size)
  end
  
  private

  def model_in_path_default
    return "#{File.dirname(__FILE__)}/SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_AllConstructions_Furnace_CentralAC_Setpoints.osm"
  end

  def epw_path_default
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_CO_Denver_Intl_AP_725650_TMY3.epw")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end  
  
  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_out_path(test_name)
    return "#{run_dir(test_name)}/SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_AllConstructions_Furnace_CentralAC_Setpoints.osm"
  end

  def sql_path(test_name)
    return "#{run_dir(test_name)}/run/eplusout.sql"
  end

  def timeseries_path(test_name)
    return "#{run_dir(test_name)}/enduse_timeseries.csv"
  end
  
  def report_path(test_name)
    return "#{run_dir(test_name)}/report.html"
  end 
  
  # create test files if they do not exist when the test first runs
  def setup_test(test_name, idf_output_requests, run, model_in_path=model_in_path_default, epw_path=epw_path_default)

    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    if File.exist?(timeseries_path(test_name))
      FileUtils.rm(timeseries_path(test_name))
    end

    assert(File.exist?(model_in_path))

    if File.exist?(model_out_path(test_name))
      FileUtils.rm(model_out_path(test_name))
    end

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new("Draft".to_StrictnessLevel, "EnergyPlus".to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(test_name), true)

    osw_path = File.join(run_dir(test_name), 'in.osw')
    osw_path = File.absolute_path(osw_path)

    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_out_path(test_name)))
    workflow.setWeatherFile(File.absolute_path(epw_path))
    workflow.saveAs(osw_path)

    if run
      cli_path = OpenStudio.getOpenStudioCLI
      cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
      puts cmd    
      system(cmd)
    else # fake an energyplus simulation
      if !File.exist?("#{run_dir(test_name)}/run")
        FileUtils.mkdir_p("#{run_dir(test_name)}/run")
      end
      FileUtils.cp("#{File.dirname(__FILE__)}/eplusout.sql", "#{run_dir(test_name)}/run")
    end
    
    return model
    
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name, num_infos=0, num_warnings=0, debug=false, run=true)
    # create an instance of the measure
    measure = UtilityBillCalculations.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size == num_infos)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    model = setup_test(test_name, idf_output_requests, run)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(timeseries_path(test_name))
      FileUtils.rm(timeseries_path(test_name))
    end
    assert(!File.exist?(timeseries_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(timeseries_path(test_name)))

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
      
        end
    end
    
    return model
  end  
  
end

require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialEavesTest < MiniTest::Test
  
  def test_not_applicable_no_surfaces
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_equal(result.info[0].logMessage, "No surfaces found for adding eaves.")
  end  
    
  def test_retrofit_replace_gable_roof_aspect_ratio_two
    args_hash = {}
    model = _test_measure("geometry_gable_roof_aspect_ratio_two_default_location.osm", args_hash, false)
    args_hash = {}
    args_hash["eaves_depth"] = 3
    _test_measure(model, args_hash, true)
  end
  
  def test_retrofit_replace_gable_roof_aspect_ratio_half
    args_hash = {}
    model = _test_measure("geometry_gable_roof_aspect_ratio_half_default_location.osm", args_hash, false)
    args_hash = {}
    args_hash["eaves_depth"] = 3
    _test_measure(model, args_hash, true)
  end
  
  def test_retrofit_replace_hip_roof_aspect_ratio_two
    args_hash = {}
    model = _test_measure("geometry_hip_roof_aspect_ratio_two_default_location.osm", args_hash, false)
    args_hash = {}
    args_hash["eaves_depth"] = 3
    _test_measure(model, args_hash, true)
  end
  
  def test_retrofit_replace_hip_roof_aspect_ratio_half
    args_hash = {}
    model = _test_measure("geometry_hip_roof_aspect_ratio_half_default_location.osm", args_hash, false)
    args_hash = {}
    args_hash["eaves_depth"] = 3
    _test_measure(model, args_hash, true)
  end
  
  def test_retrofit_replace_flat_roof_aspect_ratio_two
    args_hash = {}
    model = _test_measure("geometry_flat_roof_aspect_ratio_two_default_location.osm", args_hash, false)
    args_hash = {}
    args_hash["eaves_depth"] = 3
    _test_measure(model, args_hash, true)
  end
  
  def test_retrofit_replace_flat_roof_aspect_ratio_half
    args_hash = {}
    model = _test_measure("geometry_flat_roof_aspect_ratio_half_default_location.osm", args_hash, false)
    args_hash = {}
    args_hash["eaves_depth"] = 3
    _test_measure(model, args_hash, true)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialEaves.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_existing_eaves=false)
    # create an instance of the measure
    measure = CreateResidentialEaves.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    existing_eaves = false
    result.info.each do |info|
        if info.logMessage.include? "Removed existing eaves."
            existing_eaves = true
        end
    end    
    if expected_existing_eaves == false # new
        assert(existing_eaves==false)
    else # replacement
        assert(existing_eaves==true)
    end   

    return model
  end  
  
  def _get_model(osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end  

end

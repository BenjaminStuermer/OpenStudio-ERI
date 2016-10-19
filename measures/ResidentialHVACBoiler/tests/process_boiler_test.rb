require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessBoilerTest < MiniTest::Test
  
  def test_argument_error_steam_boiler
    args_hash = {}
    args_hash["boilerType"] = Constants.BoilerTypeSteam
    result = _test_error("singlefamily_detached_fbsmt.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Cannot currently model steam boilers.")    
  end  
  
  def test_oat_reset_enabled_nil_oat
    args_hash = {}
    args_hash["boilerType"] = Constants.BoilerTypeCondensing
    args_hash["boilerOATResetEnabled"] = "true"
    args_hash["boilerOutputCapacity"] = "20 kBtu/hr"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.76, "NominalCapacity"=>5861.42}
    _test_measure("singlefamily_detached_fbsmt.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2, 1)
  end
      
  def test_condensing_boiler_oat_reset_enabled
    args_hash = {}
    args_hash["boilerType"] = Constants.BoilerTypeCondensing
    args_hash["boilerOATResetEnabled"] = "true"
    args_hash["boilerOATLow"] = 0.0
    args_hash["boilerOATLowHWST"] = 180.0
    args_hash["boilerOATHigh"] = 68.0
    args_hash["boilerOATHighHWST"] = 95.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.76, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_ashp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end  
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_mshp
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>1, "AirConditionerVariableRefrigerantFlow"=>1, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>1, "CoilCoolingDXVariableRefrigerantFlow"=>1, "CoilHeatingDXVariableRefrigerantFlow"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_mshp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilHeatingGas"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end  
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_furnace_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_boiler_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_detached_fbsmt_boiler_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end

  def test_multifamily_new_construction_1
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>num_units*2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>num_units*2, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_attached_fbsmt_4_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*2)
  end

  def test_multifamily_new_construction_2
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>num_units, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>num_units, "SetpointManagerScheduled"=>1, "PumpConstantSpeed"=>1}
    expected_values = {"Efficiency"=>0.8, "NominalCapacity"=>"AutoSize"}
    _test_measure("multifamily_8_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*1)
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessBoiler.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessBoiler.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
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
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["CurveBicubic", "CurveQuadratic", "CurveBiquadratic", "CurveCubic", "Node", "AirLoopHVACZoneMixer", "SizingSystem", "AirLoopHVACZoneSplitter", "ScheduleTypeLimits", "CurveExponent", "ScheduleConstant", "SizingPlant", "PipeAdiabatic", "ConnectorSplitter", "ModelObjectList", "ConnectorMixer"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "BoilerHotWater"
              assert_in_epsilon(expected_values["Efficiency"], new_object.nominalThermalEfficiency, 0.01)
              if new_object.nominalCapacity.is_initialized
                assert_in_epsilon(expected_values["NominalCapacity"], new_object.nominalCapacity.get, 0.01)
              end
            end
        end
    end
    
    return model
  end
  
end

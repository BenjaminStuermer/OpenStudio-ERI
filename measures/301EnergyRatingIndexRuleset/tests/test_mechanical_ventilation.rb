require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class MechVentTest < MiniTest::Test
  def test_mech_vent
    hpxml_name = "valid.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def test_mech_vent_exhaust
    hpxml_name = "valid-mechvent-exhaust.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "exhaust only", 82.5, 24, 40.9)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "exhaust only", 247, 24, 60)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def test_mech_vent_supply
    hpxml_name = "valid-mechvent-supply.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "supply only", 82.5, 24, 40.9)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "supply only", 247, 24, 60)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def test_mech_vent_balanced
    hpxml_name = "valid-mechvent-balanced.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 82.5, 24, 81.8)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "balanced", 247, 24, 123.5)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def test_mech_vent_erv
    hpxml_name = "valid-mechvent-erv.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 82.5, 24, 116.9)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "energy recovery ventilator", 247, 24, 123.5, 0.72, 0.48)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def test_mech_vent_hrv
    hpxml_name = "valid-mechvent-hrv.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 82.5, 24, 116.9)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "heat recovery ventilator", 247, 24, 123.5, 0.72)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def test_mech_vent_cfis
    hpxml_name = "valid-mechvent-cfis.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "central fan integrated supply", 82.5, 24, 40.9)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "central fan integrated supply", 247, 8, 360)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 62.57, 24, 43.8)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34, 24, 43.8)
  end

  def _test_measure(hpxml_name, calc_type)
    root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    args_hash = {}
    args_hash['hpxml_path'] = File.join(root_path, "workflow", "sample_files", hpxml_name)
    args_hash['weather_dir'] = File.join(root_path, "weather")
    args_hash['hpxml_output_path'] = File.join(File.dirname(__FILE__), "#{calc_type}.xml")
    args_hash['calc_type'] = calc_type

    # create an instance of the measure
    measure = EnergyRatingIndex301Measure.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(File.exists? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_mech_vent(hpxml_doc, fantype = nil, flowrate = nil, hours = nil, power = nil, sre = nil, tre = nil)
    mechvent = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not fantype.nil?
      assert_equal(fantype, mechvent.elements["FanType"].text)
      assert_in_epsilon(flowrate, Float(mechvent.elements["RatedFlowRate"].text), 0.01)
      assert_equal(hours, Float(mechvent.elements["HoursInOperation"].text))
      assert_in_epsilon(power, Float(mechvent.elements["FanPower"].text), 0.01)
      if sre.nil?
        assert_nil(mechvent.elements["SensibleRecoveryEfficiency"])
      else
        assert_equal(sre, Float(mechvent.elements["SensibleRecoveryEfficiency"].text))
      end
      if tre.nil?
        assert_nil(mechvent.elements["TotalRecoveryEfficiency"])
      else
        assert_equal(tre, Float(mechvent.elements["TotalRecoveryEfficiency"].text))
      end
    else
      assert_nil(mechvent)
    end
  end
end

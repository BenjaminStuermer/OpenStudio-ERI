require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialAirflowTest < MiniTest::Unit::TestCase
  
  def test_has_clothes_dryer
    args_hash = {}    
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_clothes_dryer_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)    
  end
  
  def test_non_ducted_hvac_equipment
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>14, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>9, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_electric_baseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 2) 
  end  
  
  def test_neighbors
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_neighbors_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)
  end   
  
  def test_no_living_garage_attic_infiltration
    args_hash = {}
    args_hash["inflivingspace"] = 0
    args_hash["infgarage"] = 0
    args_hash["infunfinattic"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_garage_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)
  end  
  
  def test_mech_vent_none
    args_hash = {}
    args_hash["venttype"] = "none"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)   
  end
  
  def test_mech_vent_supply
    args_hash = {}
    args_hash["venttype"] = Constants.VentTypeSupply
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)       
  end
  
  def test_mech_vent_exhaust_ashrae_622_2013
    args_hash = {}
    args_hash["venttype"] = Constants.VentTypeExhaust
    args_hash["ashraestandard"] = "2013"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end  
  
  def test_mech_vent_balanced
    args_hash = {}
    args_hash["venttype"] = Constants.VentTypeBalanced
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)     
  end    
  
  def test_new_construction
    args_hash = {}
    args_hash["homeage"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end  
  
  def test_garage_with_attic
    args_hash = {}  
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>2, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"unfinished attic zone"}
    _test_measure("singlefamily_detached_slab_garage_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end
  
  def test_crawl
    args_hash = {}
    args_hash["infcrawl"] = 0.1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"crawl zone"}
    _test_measure("singlefamily_detached_crawl_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1) 
  end  
  
  def test_ufbasement
    args_hash = {}  
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"unfinished basement zone"}
    _test_measure("singlefamily_detached_ufbsmt_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end
  
  def test_fbasement
    args_hash = {}
    args_hash["inffbsmt"] = 0.1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"finished basement zone"}
    _test_measure("singlefamily_detached_fbsmt_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end  
  
  def test_duct_location_ufbasement
    args_hash = {}
    args_hash["duct_location"] = Constants.BasementZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"unfinished basement zone"}
    _test_measure("singlefamily_detached_ufbsmt_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end  
  
  def test_duct_location_fbasement
    args_hash = {}
    args_hash["duct_location"] = Constants.BasementZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"finished basement zone"}
    _test_measure("singlefamily_detached_fbsmt_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end  
  
  def test_duct_location_ufattic
    args_hash = {}
    args_hash["duct_location"] = Constants.AtticZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"unfinished attic zone"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)     
  end  
  
  def test_duct_location_in_living
    args_hash = {}
    args_hash["duct_location"] = Constants.LivingZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>14, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>9, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1}
    expected_values = {"duct_location"=>"living zone"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1) 
  end  

  def test_duct_location_basement_but_no_basement
    args_hash = {}
    args_hash["duct_location"] = Constants.BasementZone
    result = _test_error("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash)
    assert_equal(result_errors(result)[0], "Duct location is basement, but the building does not have a basement.")      
  end      
 
  def test_duct_norm_leak_to_outside
    args_hash = {}
    args_hash["duct_norm_leakage_to_outside"] = "8.0"
    result = _test_error("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash)
    assert_equal(result_errors(result)[0], "Duct leakage to outside was specified by we don't calculate fan air flow rate.")          
  end  

  def test_duct_norm_leak_to_outside
    args_hash = {}
    args_hash["duct_norm_leakage_to_outside"] = "8.0"
    result = _test_error("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash)
    assert_equal(result_errors(result)[0], "Duct leakage to outside was specified by we don't calculate fan air flow rate.")          
  end  
  
  def test_terrain_ocean
    args_hash = {}
    args_hash["terraintype"] = Constants.TerrainOcean
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"terrain_type"=>"Ocean"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)      
  end  

  def test_terrain_plains
    args_hash = {}
    args_hash["terraintype"] = Constants.TerrainPlains
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"terrain_type"=>"Country"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end
  
  def test_terrain_rural
    args_hash = {}
    args_hash["terraintype"] = Constants.TerrainRural
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"terrain_type"=>"Country"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end
  
  def test_terrain_city
    args_hash = {}
    args_hash["terraintype"] = Constants.TerrainCity
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"terrain_type"=>"City"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end   
  
  def test_mech_vent_erv
    args_hash = {}
    args_hash["venttype"] = Constants.VentTypeBalanced
    args_hash["totaleff"] = 0.48
    args_hash["senseff"] = 0.72
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)
  end
  
  def test_mech_vent_hrv
    args_hash = {}
    args_hash["venttype"] = Constants.VentTypeBalanced
    args_hash["senseff"] = 0.6
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end    
  
  def test_nat_vent_1_wkdy_1_wked
    args_hash = {}
    args_hash["ventweekdays"] = 1
    args_hash["ventweekenddays"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)       
  end  
  
  def test_nat_vent_2_wkdy_2_wked
    args_hash = {}
    args_hash["ventweekdays"] = 2
    args_hash["ventweekenddays"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end
  
  def test_nat_vent_4_wkdy
    args_hash = {}
    args_hash["ventweekdays"] = 4
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"unfinished attic zone"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)  
  end
  
  def test_nat_vent_5_wkdy
    args_hash = {}
    args_hash["ventweekdays"] = 5
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end 
    
  def test_mshp
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>14, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>9, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_mshp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 3)      
  end
  
  def test_duct_location_frac
    args_hash = {}
    args_hash["duct_location"] = Constants.AtticZone
    args_hash["duct_location_frac"] = "0.5"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"unfinished attic zone"}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)     
  end  
  
  def test_duct_location_attic_but_no_attic
    args_hash = {}
    args_hash["duct_location"] = Constants.AtticZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>14, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>9, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1}
    expected_values = {"duct_location"=>"living zone"}
    _test_measure("singlefamily_detached_slab_no_attic_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)      
  end    
    
  def test_garage_without_attic
    args_hash = {}  
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"duct_location"=>"garage zone"}
    _test_measure("singlefamily_detached_slab_no_attic_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end
  
  def test_return_loss_greater_than_supply_loss
    args_hash = {}
    args_hash["duct_sup_frac"] = 0.067
    args_hash["duct_ret_frac"] = 0.6
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)    
  end
    
  def test_retrofit_infiltration
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"infiltration_c"=>0.069}
    model = _test_measure("singlefamily_detached_slab_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)
    args_hash["inflivingspace"] = 3
    expected_num_del_objects = {"Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemOutputVariable"=>7, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>23, "EnergyManagementSystemActuator"=>14, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>18, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1}
    expected_values = {"infiltration_c"=>0.029}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)     
  end
  
  def test_multifamily_new_construction_1
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>num_units*7, "ScheduleRule"=>num_units*84, "EnergyManagementSystemSubroutine"=>num_units*1, "EnergyManagementSystemProgramCallingManager"=>num_units*2, "EnergyManagementSystemOutputVariable"=>num_units*7, "EnergyManagementSystemProgram"=>num_units*3, "EnergyManagementSystemSensor"=>num_units*23, "EnergyManagementSystemActuator"=>num_units*14, "EnergyManagementSystemGlobalVariable"=>num_units*23, "OutputVariable"=>num_units*18, "SpaceInfiltrationDesignFlowRate"=>num_units*2, "ZoneMixing"=>num_units*2, "OtherEquipment"=>num_units*10, "OtherEquipmentDefinition"=>num_units*10, "Construction"=>num_units*1, "Surface"=>num_units*6, "Space"=>num_units*1, "ThermalZone"=>num_units*1, "AirLoopHVACReturnPlenum"=>num_units*1}
    expected_values = {"duct_location"=>"finished basement zone", "infiltration_c"=>0.041}
    _test_measure("singlefamily_attached_fbsmt_4_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units, num_units)
  end
  
  def test_multifamily_new_construction_2
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>num_units*7, "ScheduleRule"=>num_units*84, "EnergyManagementSystemProgramCallingManager"=>num_units*2, "EnergyManagementSystemOutputVariable"=>num_units*7, "EnergyManagementSystemProgram"=>num_units*3, "EnergyManagementSystemSensor"=>num_units*14, "EnergyManagementSystemActuator"=>num_units*2, "EnergyManagementSystemGlobalVariable"=>num_units*2, "OutputVariable"=>num_units*9, "SpaceInfiltrationDesignFlowRate"=>num_units*2}
    expected_values = {"duct_location"=>"living zone", "infiltration_c"=>0.047}
    _test_measure("multifamily_8_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, num_units) 
  end
    
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ResidentialAirflow.new

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
    assert_equal("Fail", result_value(result))
    assert(result_errors(result).size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ResidentialAirflow.new

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
    assert_equal("Success", result_value(result))
    assert(result_infos(result).size == num_infos)
    assert(result_warnings(result).size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ScheduleDay", "ZoneHVACEquipmentList", "PortList", "Node", "SizingZone", "ScheduleConstant", "ScheduleTypeLimits", "CurveCubic", "CurveExponent"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "EnergyManagementSystemSensor"
                next unless new_object.name.to_s == "AHZone_T_Sensor_1"
                next if expected_values["duct_location"].nil?
                assert_equal(expected_values["duct_location"], new_object.keyName.get)
            elsif obj_type == "EnergyManagementSystemProgram"
                next unless new_object.name.to_s.include? "InfiltrationProgram_1"
                next if expected_values["infiltration_c"].nil?
                new_object.lines.get.each do |line|
                    next unless line.start_with? "Set c ="
                    assert_in_epsilon(expected_values["infiltration_c"], line.split(" = ")[1].to_f, 0.1)
                end
            end
        end
    end
    unless expected_values["terrain_type"].nil?
      assert_equal(expected_values["terrain_type"], model.getSite.terrain.to_s)
    end
    
    return model
  end

end

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class ProcessRoomAirConditioner < OpenStudio::Ruleset::ModelUserScript

  class Supply
    def initialize
    end
    attr_accessor(:shr_Rated, :coolingCFMs, :min_flow_ratio, :fanspeed_ratio, :cfm_TON_Rated)
  end
  
  class Curves
    def initialize
    end
    attr_accessor(:number_Speeds, :cool_CAP_FT_SPEC_coefficients, :cool_EIR_FT_SPEC_coefficients, :cool_CAP_FFLOW_SPEC_coefficients, :cool_EIR_FFLOW_SPEC_coefficients, :cool_PLF_FPLR)
  end
  
  # human readable name
  def name
    return "Set Residential Room Air Conditioner"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a room air conditioner."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure parses the IDF for the CoolingSeasonSchedule. Any supply components, except for heating coils, are removed from any existing air loops or zones. Any existing air loops are also removed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for room air eer
    roomaceer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("roomaceer", true)
    roomaceer.setDisplayName("EER")
    roomaceer.setUnits("Btu/W-h")
    roomaceer.setDescription("This is a measure of the instantaneous energy efficiency of the cooling equipment.")
    roomaceer.setDefaultValue(8.5)
    args << roomaceer         
    
    #make a double argument for room air shr
    roomacshr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("roomacshr", true)
    roomacshr.setDisplayName("Rated SHR")
	roomacshr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    roomacshr.setDefaultValue(0.65)
    args << roomacshr

    #make a double argument for room air airflow
    roomacairflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("roomacairflow", true)
    roomacairflow.setDisplayName("Airflow")
    roomacairflow.setUnits("cfm/ton")
    roomacairflow.setDefaultValue(350.0)
    args << roomacairflow     
    
    #make a choice argument for living thermal zone
    thermal_zones = model.getThermalZones
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
        thermal_zone_args << thermal_zone.name.to_s
    end
    if not thermal_zone_args.include?(Constants.LivingZone)
        thermal_zone_args << Constants.LivingZone
    end
    living_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_thermal_zone", thermal_zone_args, true)
    living_thermal_zone.setDisplayName("Living thermal zone")
    living_thermal_zone.setDescription("Select the living thermal zone")
    living_thermal_zone.setDefaultValue(Constants.LivingZone)
    args << living_thermal_zone		   

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	living_thermal_zone_r = runner.getStringArgumentValue("living_thermal_zone",user_arguments)
    living_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, living_thermal_zone_r, runner)
    if living_thermal_zone.nil?
        return false
    end 
    
    supply = Supply.new
    curves = Curves.new

    coolingseasonschedule = nil
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "CoolingSeasonSchedule"
        coolingseasonschedule = scheduleRuleset
        break
      end
    end
    
    roomaceer = runner.getDoubleArgumentValue("roomaceer",user_arguments)
    supply.shr_Rated = runner.getDoubleArgumentValue("roomacshr",user_arguments)
    supply.coolingCFMs = runner.getDoubleArgumentValue("roomacairflow",user_arguments)

    # Check if has equipment
    ptacs = model.getZoneHVACPackagedTerminalAirConditioners
    ptacs.each do |ptac|
      thermalZone = ptac.thermalZone.get
      runner.registerInfo("Removed '#{ptac.name}' from thermal zone '#{thermalZone.name}'")
      ptac.remove
    end
    airLoopHVACs = model.getAirLoopHVACs
    airLoopHVACs.each do |airLoopHVAC|
      thermalZones = airLoopHVAC.thermalZones
      thermalZones.each do |thermalZone|
        if living_thermal_zone.handle.to_s == thermalZone.handle.to_s
          supplyComponents = airLoopHVAC.supplyComponents
          supplyComponents.each do |supplyComponent|
            if supplyComponent.to_AirLoopHVACUnitarySystem.is_initialized
              air_loop_unitary = supplyComponent.to_AirLoopHVACUnitarySystem.get
              if air_loop_unitary.coolingCoil.is_initialized
                clg_coil = air_loop_unitary.coolingCoil.get
                if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
                  runner.registerInfo("Removed '#{clg_coil.name}' from air loop '#{airLoopHVAC.name}'")
                  air_loop_unitary.resetCoolingCoil
                  clg_coil.remove
                end
                if clg_coil.to_CoilCoolingDXTwoSpeed.is_initialized
                  runner.registerInfo("Removed '#{clg_coil.name}' from air loop '#{airLoopHVAC.name}'")
                  air_loop_unitary.resetCoolingCoil
                  clg_coil.remove
                end
              end
            end
          end
        end
      end
    end     
    
    # Performance curves
    supply, curves = get_cooling_coefficients_RoomAC(supply, curves)                   
    # To avoid BEopt errors
    supply.min_flow_ratio = 1
    curves.number_Speeds = 1
    supply.fanspeed_ratio = [1]       

    # _processCurvesRoomAirConditioner    
    
    roomac_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
    roomac_cap_ft.setName("RoomAC-Cap-fT")
    roomac_cap_ft.setCoefficient1Constant(curves.cool_CAP_FT_SPEC_coefficients[0])
    roomac_cap_ft.setCoefficient2x(curves.cool_CAP_FT_SPEC_coefficients[1])
    roomac_cap_ft.setCoefficient3xPOW2(curves.cool_CAP_FT_SPEC_coefficients[2])
    roomac_cap_ft.setCoefficient4y(curves.cool_CAP_FT_SPEC_coefficients[3])
    roomac_cap_ft.setCoefficient5yPOW2(curves.cool_CAP_FT_SPEC_coefficients[4])
    roomac_cap_ft.setCoefficient6xTIMESY(curves.cool_CAP_FT_SPEC_coefficients[5])
    roomac_cap_ft.setMinimumValueofx(0)
    roomac_cap_ft.setMaximumValueofx(100)
    roomac_cap_ft.setMinimumValueofy(0)
    roomac_cap_ft.setMaximumValueofy(100)

    roomac_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
    roomac_cap_fff.setName("RoomAC-Cap-fFF")
    roomac_cap_fff.setCoefficient1Constant(curves.cool_CAP_FFLOW_SPEC_coefficients[0])
    roomac_cap_fff.setCoefficient2x(curves.cool_CAP_FFLOW_SPEC_coefficients[1])
    roomac_cap_fff.setCoefficient3xPOW2(curves.cool_CAP_FFLOW_SPEC_coefficients[2])
    roomac_cap_fff.setMinimumValueofx(0)
    roomac_cap_fff.setMaximumValueofx(2)

    roomac_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
    roomac_eir_ft.setName("RoomAC-EIR-fT")
    roomac_eir_ft.setCoefficient1Constant(curves.cool_EIR_FT_SPEC_coefficients[0])
    roomac_eir_ft.setCoefficient2x(curves.cool_EIR_FT_SPEC_coefficients[1])
    roomac_eir_ft.setCoefficient3xPOW2(curves.cool_EIR_FT_SPEC_coefficients[2])
    roomac_eir_ft.setCoefficient4y(curves.cool_EIR_FT_SPEC_coefficients[3])
    roomac_eir_ft.setCoefficient5yPOW2(curves.cool_EIR_FT_SPEC_coefficients[4])
    roomac_eir_ft.setCoefficient6xTIMESY(curves.cool_EIR_FT_SPEC_coefficients[5])
    roomac_eir_ft.setMinimumValueofx(0)
    roomac_eir_ft.setMaximumValueofx(100)
    roomac_eir_ft.setMinimumValueofy(0)
    roomac_eir_ft.setMaximumValueofy(100)    
    
    roomcac_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
    roomcac_eir_fff.setName("RoomAC-EIR-fFF")
    roomcac_eir_fff.setCoefficient1Constant(curves.cool_EIR_FFLOW_SPEC_coefficients[0])
    roomcac_eir_fff.setCoefficient2x(curves.cool_EIR_FFLOW_SPEC_coefficients[1])
    roomcac_eir_fff.setCoefficient3xPOW2(curves.cool_EIR_FFLOW_SPEC_coefficients[2])
    roomcac_eir_fff.setMinimumValueofx(0)
    roomcac_eir_fff.setMaximumValueofx(2)    
    
    roomac_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
    roomac_plf_fplr.setName("RoomAC-PLF-fPLR")
    roomac_plf_fplr.setCoefficient1Constant(curves.cool_PLF_FPLR[0])
    roomac_plf_fplr.setCoefficient2x(curves.cool_PLF_FPLR[1])
    roomac_plf_fplr.setCoefficient3xPOW2(curves.cool_PLF_FPLR[2])
    roomac_plf_fplr.setMinimumValueofx(0)
    roomac_plf_fplr.setMaximumValueofx(1)
    
    # _processSystemRoomAC
    
    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, coolingseasonschedule, roomac_cap_ft, roomac_cap_fff, roomac_eir_ft, roomcac_eir_fff, roomac_plf_fplr)
    clg_coil.setName("WindowAC Coil")
    clg_coil.setRatedSensibleHeatRatio(supply.shr_Rated)
    clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(OpenStudio::convert(roomaceer, "Btu/h", "W").get))
    clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(773.3))
    clg_coil.setEvaporativeCondenserEffectiveness(OpenStudio::OptionalDouble.new(0.9))
    clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(10))
    clg_coil.setBasinHeaterSetpointTemperature(OpenStudio::OptionalDouble.new(2))
    
    supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
    supply_fan_availability.setName("SupplyFanAvailability")
    supply_fan_availability.setValue(1)    
    
    fan_onoff = OpenStudio::Model::FanOnOff.new(model, supply_fan_availability)
    fan_onoff.setName("WindowAC Fan")
    fan_onoff.setFanEfficiency(1)
    fan_onoff.setPressureRise(0)
    fan_onoff.setMotorEfficiency(1)
    fan_onoff.setMotorInAirstreamFraction(0)
    
    supply_fan_operation = OpenStudio::Model::ScheduleConstant.new(model)
    supply_fan_operation.setName("SupplyFanOperation")
    supply_fan_operation.setValue(0)
    
    htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule())
    
    ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model,coolingseasonschedule, fan_onoff, htg_coil, clg_coil)
    ptac.setName("Window AC")
    ptac.setOutdoorAirMixerName("WindowAC Mixer")
    ptac.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
    # ptac.setFanPlacement("BlowThrough")
    ptac.addToThermalZone(living_thermal_zone)
    runner.registerInfo("Added packaged terminal air conditioner '#{ptac.name}' to thermal zone '#{living_thermal_zone.name}'")
    
    # _processSystemVentilationNodes
    
    return true

  end
  
  def get_cooling_coefficients_RoomAC(supply, curves)
    
    # From Frigidaire 10.7 EER unit in Winkler et. al. Lab Testing of Window ACs (2013)
    
    # Hard coded coefficients in SI UNITS
    curves.cool_CAP_FT_SPEC_coefficients = [0.6405, 0.01568, 0.0004531, 0.001615, -0.0001825, 0.00006614]
    curves.cool_EIR_FT_SPEC_coefficients = [2.287, -0.1732, 0.004745, 0.01662, 0.000484, -0.001306]
    curves.cool_CAP_FFLOW_SPEC_coefficients = [0.887, 0.1128, 0]
    curves.cool_EIR_FFLOW_SPEC_coefficients = [1.763, -0.6081, 0]
    curves.cool_PLF_FPLR = [0.78, 0.22, 0]
    supply.cfm_TON_Rated = [312]    # medium speed

    return supply, curves

  end    
  
end

# register the measure to be used by the application
ProcessRoomAirConditioner.new.registerWithApplication

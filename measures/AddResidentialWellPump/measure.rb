require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class ResidentialWellPump < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Well Pump"
  end
  
  def description
    return "Adds (or replaces) a residential well pump with the specified efficiency and schedule. The well is assumed to be outdoors."
  end
  
  def modeler_description
    return "Since there is no Well Pump object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential well pump. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for well pumps (alternate schedules if automatic DR control is specified)
	
	#make a double argument for Base Energy Use
	base_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("base_energy")
	base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("kWh/yr")
	base_energy.setDescription("The national average (Building America Benchmark) energy use.")
	base_energy.setDefaultValue(400)
	args << base_energy

	#make a double argument for Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Energy Multiplier")
	mult.setDescription("Sets the annual energy use equal to the base energy use times this multiplier.")
	mult.setDefaultValue(1)
	args << mult

    #make a boolean argument for Scale Energy Use
	scale_energy = OpenStudio::Ruleset::OSArgument::makeBoolArgument("scale_energy",true)
	scale_energy.setDisplayName("Scale Energy Use")
	scale_energy.setDescription("If true, scales the energy use relative to a 3-bedroom, 1920 sqft house using the following equation: Fscale = (0.5 + 0.25 x Nbr/3 + 0.25 x FFA/1920) where Nbr is the number of bedrooms and FFA is the finished floor area.")
	scale_energy.setDefaultValue(true)
	args << scale_energy

	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154")
	args << monthly_sch

    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type. The well will be located outdoors, but the living space floor area is needed to scale energy use.")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type

    #make a choice argument for finished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.FinishedBasementSpaceType)
        space_type_args << Constants.FinishedBasementSpaceType
    end
    fbasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_space_type", space_type_args, true)
    fbasement_space_type.setDisplayName("Finished Basement space type")
    fbasement_space_type.setDescription("Select the finished basement space type. The well will be located outdoors, but the finished basement space floor area is needed to scale energy use.")
    fbasement_space_type.setDefaultValue(Constants.FinishedBasementSpaceType)
    args << fbasement_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    #assign the user inputs to variables
    base_energy = runner.getDoubleArgumentValue("base_energy",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
    scale_energy = runner.getBoolArgumentValue("scale_energy",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    
    #check for valid inputs
    if base_energy < 0
		runner.registerError("Base energy use must be greater than or equal to 0.")
		return false
    end
    if mult < 0
		runner.registerError("Energy multiplier must be greater than or equal to 0.")
		return false
    end
    
	# Space type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	fbasement_space_type_r = runner.getStringArgumentValue("fbasement_space_type",user_arguments)
    fbasement_space_type = HelperMethods.get_space_type_from_string(model, fbasement_space_type_r, runner, false)

    # Get number of bedrooms/bathrooms
    nbeds, nbaths = HelperMethods.get_bedrooms_bathrooms(model, living_space_type.handle, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end
    
    cfa_living = HelperMethods.get_floor_area(model, living_space_type.handle, runner)
    cfa_fbasement = 0.0
    if not fbasement_space_type.nil?
        cfa_fbasement = HelperMethods.get_floor_area(model, fbasement_space_type.handle, runner)
    end
    cfa_total = cfa_living + cfa_fbasement

	#Calculate annual energy use
    ann_elec = base_energy * mult # kWh/yr
    
    if scale_energy
        #Scale energy use by num beds and floor area
        constant = ann_elec/2
        nbr_coef = ann_elec/4/3
        cfa_coef = ann_elec/4/1920
        wp_ann = constant + nbr_coef * nbeds + cfa_coef * cfa_total # kWh/yr
    else
        wp_ann = ann_elec # kWh/yr
    end

    #hard coded convective, radiative, latent, and lost fractions
    wp_lat = 0
    wp_rad = 0
    wp_conv = 0
    wp_lost = 1 - wp_lat - wp_rad - wp_conv
	
	obj_name = Constants.ObjectNameWellPump
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailykWh(wp_ann/365.0)
	
	#add well pump to the living space
    #because there are no space gains, the choice of space is arbitrary
	has_wp = 0
	replace_wp = 0
    space_equipments = living_space_type.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
            has_wp = 1
            runner.registerInfo("There is already a well pump, the existing well pump will be replaced with the specified well pump.")
            space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment)
            replace_wp = 1
        end
    end
    if has_wp == 0 
        has_wp = 1
        
        #Add electric equipment for the well pump
        wp_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        wp = OpenStudio::Model::ElectricEquipment.new(wp_def)
        wp.setName(obj_name)
        wp.setSpaceType(living_space_type)
        wp_def.setName(obj_name)
        wp_def.setDesignLevel(design_level)
        wp_def.setFractionRadiant(wp_rad)
        wp_def.setFractionLatent(wp_lat)
        wp_def.setFractionLost(wp_lost)
        sch.setSchedule(wp)
        
    end
	
    #reporting final condition of model
    if replace_wp == 1
        runner.registerFinalCondition("The existing well pump has been replaced by one with #{wp_ann.round} kWhs annual energy consumption.")
    else
        runner.registerFinalCondition("A well pump has been added with #{wp_ann.round} kWhs annual energy consumption.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialWellPump.new.registerWithApplication
#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessThermalMassPartitionWall < OpenStudio::Ruleset::ModelUserScript

  class PartitionWallMass
    def initialize(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat, partitionWallMassPCMType)
      @partitionWallMassThickness = partitionWallMassThickness
      @partitionWallMassConductivity = partitionWallMassConductivity
      @partitionWallMassDensity = partitionWallMassDensity
      @partitionWallMassSpecHeat = partitionWallMassSpecHeat
      @partitionWallMassPCMType = partitionWallMassPCMType
    end

    def PartitionWallMassThickness
      return @partitionWallMassThickness
    end

    def PartitionWallMassConductivity
      return @partitionWallMassConductivity
    end

    def PartitionWallMassDensity
      return @partitionWallMassDensity
    end

    def PartitionWallMassSpecificHeat
      return @partitionWallMassSpecHeat
    end

    def PartitionWallMassPCMType
      return @partitionWallMassPCMType
    end

    attr_accessor(:living_space_area, :finished_basement_area)
  end

  class LivingSpace
    def initialize
    end
    attr_accessor(:area)
  end

  class FinishedBasement
    def initialize
    end
    attr_accessor(:area)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add/Replace Residential Partition Wall Thermal Mass"
  end
  
  def description
    return "This measure creates internal mass for partition walls in the living space and finished basement."
  end
  
  def modeler_description
    return "This measure creates constructions representing the internal mass of partition walls in the living space and finished basement. The constructions are set to define the internal mass objects of their respective spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Living Space")
	selected_living.setDescription("The living space type.")
    args << selected_living

    #make a choice argument for crawlspace
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", spacetype_handles, spacetype_display_names, false)
    selected_fbsmt.setDisplayName("Finished Basement Space")
	selected_fbsmt.setDescription("The finished basement space type.")
    args << selected_fbsmt

    #make a double argument for partition wall mass thickness
    partitionwallmassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmassth", false)
    partitionwallmassth.setDisplayName("Partition Wall Mass: Thickness")
	partitionwallmassth.setUnits("in")
	partitionwallmassth.setDescription("Thickness of the layer.")
    partitionwallmassth.setDefaultValue(0.5)
    args << partitionwallmassth

    #make a double argument for partition wall mass conductivity
    partitionwallmasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmasscond", false)
    partitionwallmasscond.setDisplayName("Partition Wall Mass: Conductivity")
	partitionwallmasscond.setUnits("Btu-in/h-ft^2-R")
	partitionwallmasscond.setDescription("Conductivity of the layer.")
    partitionwallmasscond.setDefaultValue(1.1112)
    args << partitionwallmasscond

    #make a double argument for partition wall mass density
    partitionwallmassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmassdens", false)
    partitionwallmassdens.setDisplayName("Partition Wall Mass: Density")
	partitionwallmassdens.setUnits("lb/ft^3")
	partitionwallmassdens.setDescription("Density of the layer.")
    partitionwallmassdens.setDefaultValue(50.0)
    args << partitionwallmassdens

    #make a double argument for partition wall mass specific heat
    partitionwallmasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmasssh", false)
    partitionwallmasssh.setDisplayName("Partition Wall Mass: Specific Heat")
	partitionwallmasssh.setUnits("Btu/lb-R")
	partitionwallmasssh.setDescription("Specific heat of the layer.")
    partitionwallmasssh.setDefaultValue(0.2)
    args << partitionwallmasssh

    #make a double argument for partition wall fraction of floor area
    partitionwallfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallfrac", false)
    partitionwallfrac.setDisplayName("Partition Wall Mass: Fraction of Floor Area")
	partitionwallfrac.setDescription("Ratio of exposed partition wall area to total conditioned floor area and accounts for the area of both sides of partition walls.")
    partitionwallfrac.setDefaultValue(1.0)
    args << partitionwallfrac

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Space Type
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)
    partitionWallMassThickness = runner.getDoubleArgumentValue("partitionwallmassth",user_arguments)
    partitionWallMassConductivity = runner.getDoubleArgumentValue("partitionwallmasscond",user_arguments)
    partitionWallMassDensity = runner.getDoubleArgumentValue("partitionwallmassdens",user_arguments)
    partitionWallMassSpecificHeat = runner.getDoubleArgumentValue("partitionwallmasssh",user_arguments)
    partitionWallMassFractionOfFloorArea = runner.getDoubleArgumentValue("partitionwallfrac",user_arguments)

    # loop thru all the spaces
    hasFinishedBasement = false
    if not selected_fbsmt.empty?
      hasFinishedBasement = true
    end
    
    living_space_area = 0
    finished_basement_area = 0
	model.getSpaceTypes.each do |spaceType|
		spacehandle = spaceType.handle.to_s
        if spacehandle == selected_living.get.handle.to_s
            living_space_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
        elsif hasFinishedBasement and spacehandle == selected_fbsmt.get.handle.to_s
            finished_basement_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
        end
    end

    # Constants
    mat_wood = get_mat_wood
 
    partitionWallMassPCMType = nil

    # Create the material class instances
    partition_wall_mass = PartitionWallMass.new(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat, partitionWallMassPCMType)

    # Create the sim object
    sim = Sim.new(model, runner)
    living_space = LivingSpace.new
    finished_basement = FinishedBasement.new

    living_space.area = living_space_area
    finished_basement.area = finished_basement_area

    # Process the partition wall
    partition_wall_mass = sim._processThermalMassPartitionWall(partitionWallMassFractionOfFloorArea, partition_wall_mass, living_space, finished_basement)

    # Initialize variables for drawn partition wall areas
    livingPartWallDrawnArea = 0 # Drawn partition wall area of the living space
    fbsmtPartWallDrawnArea = 0 # Drawn partition wall area of the finished basement

    # Loop through all walls and find the wall area of drawn partition walls
    # for wall in geometry.walls.wall:
    #   if wall.space_int == wall.space_ext:
    #       if wall.space_int == Constants.SpaceLiving:
    #           self.LivingPartWallDrawnArea += wall.area
    #       elif wall.space_int == Constants.SpaceFinBasement:
    #           self.FBsmtPartWallDrawnArea += wall.area
    #       # End drawn partition wall area sumation loop

    # ConcPCMPartWall
    if partition_wall_mass.PartitionWallMassPCMType == Constants.PCMtypeConcentrated
      pcm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      pcm.setName("ConcPCMPartWall")
      pcm.setRoughness("Rough")
      pcm.setThickness(OpenStudio::convert(get_mat_part_pcm_conc(get_mat_part_pcm(partition_wall_mass), partition_wall_mass).thick,"ft","m").get)
      pcm.setConductivity()
      pcm.setDensity()
      pcm.setSpecificHeat()
    end

    # PartitionWallMass
    pwm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    pwm.setName("PartitionWallMass")
    pwm.setRoughness("Rough")
    pwm.setThickness(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).thick,"ft","m").get)
    pwm.setConductivity(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).k,"Btu/hr*ft*R","W/m*K").get)
    pwm.setDensity(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).rho,"lb/ft^3","kg/m^3").get)
    pwm.setSpecificHeat(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).Cp,"Btu/lb*R","J/kg*K").get)
    pwm.setThermalAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).TAbs)
    pwm.setSolarAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).SAbs)
    pwm.setVisibleAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).VAbs)

    # StudandAirWall
    saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saw.setName("StudandAirWall")
    saw.setRoughness("Rough")
    saw.setThickness(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).thick,"ft","m").get)
    saw.setConductivity(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).k,"Btu/hr*ft*R","W/m*K").get)
    saw.setDensity(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).rho,"lb/ft^3","kg/m^3").get)
    saw.setSpecificHeat(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).Cp,"Btu/lb*R","J/kg*K").get)

    # FinUninsFinWall
    layercount = 0
    fufw = OpenStudio::Model::Construction.new(model)
    fufw.setName("FinUninsFinWall")
    fufw.insertLayer(layercount,pwm)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == Constants.PCMtypeConcentrated
      fufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    fufw.insertLayer(layercount,saw)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == Constants.PCMtypeConcentrated
      fufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    fufw.insertLayer(layercount,pwm)

    # Remaining partition walls within spaces (those without geometric representation)
    lp = OpenStudio::Model::InternalMassDefinition.new(model)
    lp.setName("LivingPartition")
    lp.setConstruction(fufw)
    if partition_wall_mass.living_space_area > (livingPartWallDrawnArea * 2)
      lp.setSurfaceArea(OpenStudio::convert(partition_wall_mass.living_space_area - livingPartWallDrawnArea * 2,"ft^2","m^2").get)
    else
      lp.setSurfaceArea(OpenStudio::convert(0.001,"ft^2","m^2").get)
    end
    im = OpenStudio::Model::InternalMass.new(lp)
    im.setName("LivingPartition")
    # loop thru all the space types
    spaceTypes = model.getSpaceTypes
    spaceTypes.each do |spaceType|
      if selected_living.get.handle.to_s == spaceType.handle.to_s
        runner.registerInfo("Assigned internal mass object 'LivingPartition' to space type '#{spaceType.name}'")
        im.setSpaceType(spaceType)
      end
    end

    if hasFinishedBasement
      # Remaining partition walls within spaces (those without geometric representation)
      fbp = OpenStudio::Model::InternalMassDefinition.new(model)
      fbp.setName("FBsmtPartition")
      fbp.setConstruction(fufw)
      #fbp.setZone # TODO: what is this?
      if partition_wall_mass.finished_basement_area > (fbsmtPartWallDrawnArea * 2)
        fbp.setSurfaceArea(OpenStudio::convert(partition_wall_mass.finished_basement_area - fbsmtPartWallDrawnArea * 2,"ft^2","m^2").get)
      else
        runner.registerWarning("The variable PartitionWallMassFractionOfFloorArea in the Partition Wall Mass category resulted in an area that is less than the partition wall area drawn. The mass of the drawn partition walls will be simulated, hence the variable PartitionWallMassFractionOfFloorArea will be ignored.")
        fbp.setSurfaceArea(OpenStudio::convert(0.001,"ft^2","m^2").get)
      end
      im = OpenStudio::Model::InternalMass.new(fbp)
      im.setName("FBsmtPartition")
      # loop thru all the space types
      spaceTypes = model.getSpaceTypes
      spaceTypes.each do |spaceType|
        if selected_fbsmt.get.handle.to_s == spaceType.handle.to_s
          runner.registerInfo("Assigned internal mass object 'FBsmtPartition' to space type '#{spaceType.name}'")
          im.setSpaceType(spaceType)
        end
      end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessThermalMassPartitionWall.new.registerWithApplication
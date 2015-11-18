# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsICF < OpenStudio::Ruleset::ModelUserScript

	class ICFWall
		def initialize(icfFramingFactor, icfInsThickness, icfInsRvalue, icfConcreteThickness)
			@icfFramingFactor = icfFramingFactor
			@icfInsThickness = icfInsThickness
			@icfInsRvalue = icfInsRvalue
			@icfConcreteThickness = icfConcreteThickness
		end
		attr_accessor(:ins_layer_thickness, :ins_layer_conductivity, :ins_layer_density, :ins_layer_spec_heat, :conc_layer_thickness, :conc_layer_conductivity, :conc_layer_density, :conc_layer_spec_heat)
		
		def ICFFramingFactor
			return @icfFramingFactor
		end
		
		def ICFInsThickness
			return @icfInsThickness
		end
		
		def ICFInsRvalue
			return @icfInsRvalue
		end
		
		def ICFConcreteThickness
			return @icfConcreteThickness
		end
	end

	class ExtWallMass
		def initialize(gypsumThickness, gypsumNumLayers, gypsumRvalue)
			@gypsumThickness = gypsumThickness
			@gypsumNumLayers = gypsumNumLayers
			@gypsumRvalue = gypsumRvalue
		end
		
		def ExtWallMassGypsumThickness
			return @gypsumThickness
		end
		
		def ExtWallMassGypsumNumLayers
			return @gypsumNumLayers
		end
		
		def ExtWallMassGypsumRvalue
			return @gypsumRvalue
		end
	end		
	
	class ExteriorFinish
		def initialize(finishThickness, finishConductivity, finishRvalue)
			@finishThickness = finishThickness
			@finishConductivity = finishConductivity
			@finishRvalue = finishRvalue
		end
		
		def FinishThickness
			return @finishThickness
		end
		
		def FinishConductivity
			return @finishConductivity
		end
		
		def FinishRvalue
			return @finishRvalue
		end
	end
	
	class WallSheathing
		def initialize(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
			@rigidInsThickness = rigidInsThickness
			@rigidInsRvalue = rigidInsRvalue
			@hasOSB = hasOSB
			@osbRvalue = osbRvalue
		end

		attr_accessor(:rigid_ins_layer_thickness, :rigid_ins_layer_conductivity, :rigid_ins_layer_density, :rigid_ins_layer_spec_heat)
		
		def WallSheathingContInsThickness
			return @rigidInsThickness
		end
		
		def WallSheathingContInsRvalue
			return @rigidInsRvalue
		end
		
		def WallSheathingHasOSB
			return @hasOSB
		end
		
		def OSBRvalue
			return @osbRvalue		
		end
	end

  # human readable name
  def name
    return "Add/Replace Residential ICF Walls"
  end

  # human readable description
  def description
    return "This measure creates ICF constructions for the exterior walls adjacent to the living space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates material layer properties of ICF constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
  end

  # define the arguments that the user will input
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

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Living Space")
	selected_living.setDescription("The living space type.")
    args << selected_living
	
    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Exterior Wall Mass: Thickness")
	userdefined_gypthickness.setUnits("in")
	userdefined_gypthickness.setDescription("Gypsum layer thickness.")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Exterior Wall Mass: Num Layers")
	userdefined_gyplayers.setUnits("#")
	userdefined_gyplayers.setDescription("Integer number of layers of gypsum.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers
		
	#make a double argument for framing factor
	userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", false)
	userdefined_framingfrac.setDisplayName("ICF: Framing Factor")
	userdefined_framingfrac.setUnits("frac")
	userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.076)
	args << userdefined_framingfrac	
	
    #make a double argument for thickness of the icf insulation
    userdefined_icfinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfinsthickness", true)
    userdefined_icfinsthickness.setDisplayName("ICF: Insulation Thickness")
	userdefined_icfinsthickness.setUnits("in")
	userdefined_icfinsthickness.setDescription("Thickness of each insulating layer of the form.")
	userdefined_icfinsthickness.setDefaultValue(2.0)
    args << userdefined_icfinsthickness	
	
	#make a double argument for nominal R-value of the icf insulation
	userdefined_icfinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfinsr", false)
	userdefined_icfinsr.setDisplayName("ICF: Nominal Insulation R-value")
	userdefined_icfinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_icfinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_icfinsr.setDefaultValue(10.0)
	args << userdefined_icfinsr

    #make a double argument for thickness of the concrete
    userdefined_sipintsheathingthick = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfconcth", true)
    userdefined_sipintsheathingthick.setDisplayName("ICF: Concrete Thickness")
	userdefined_sipintsheathingthick.setUnits("in")
	userdefined_sipintsheathingthick.setDescription("The thickness of the concrete core of the ICF.")
	userdefined_sipintsheathingthick.setDefaultValue(4.0)
    args << userdefined_sipintsheathingthick
	
	#make a bool argument for OSB of wall cavity
	userdefined_hasosb = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasosb", true)
	userdefined_hasosb.setDisplayName("Wall Sheathing: Has OSB")
	userdefined_hasosb.setDescription("Specifies if the walls have a layer of structural shear OSB sheathing.")
	userdefined_hasosb.setDefaultValue(true)
	args << userdefined_hasosb	
	
	#make a double argument for rigid insulation thickness of wall cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Wall Sheathing: Continuous Insulation Thickness")
	userdefined_rigidinsthickness.setUnits("in")
	userdefined_rigidinsthickness.setDescription("The thickness of the continuous insulation.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness
	
	#make a double argument for rigid insulation R-value of wall cavity
	userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
	userdefined_rigidinsr.setDisplayName("Wall Sheathing: Continuous Insulation Nominal R-value")
	userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_rigidinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_rigidinsr.setDefaultValue(0)
	args << userdefined_rigidinsr
	
	#make a double argument for exterior finish thickness of wall cavity
	userdefined_extfinthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinthickness", false)
	userdefined_extfinthickness.setDisplayName("Exterior Finish: Thickness")
	userdefined_extfinthickness.setUnits("in")
	userdefined_extfinthickness.setDescription("Thickness of the exterior finish assembly.")
    userdefined_extfinthickness.setDefaultValue(0.375)
	args << userdefined_extfinthickness
	
	#make a double argument for exterior finish R-value of wall cavity
	userdefined_extfinr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinr", false)
	userdefined_extfinr.setDisplayName("Exterior Finish: R-value")
	userdefined_extfinr.setUnits("hr-ft^2-R/Btu")
	userdefined_extfinr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_extfinr.setDefaultValue(0.6)
	args << userdefined_extfinr	
	
	#make a double argument for exterior finish density of wall cavity
	userdefined_extfindensity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfindensity", false)
	userdefined_extfindensity.setDisplayName("Exterior Finish: Density")
	userdefined_extfindensity.setUnits("lb/ft^3")
	userdefined_extfindensity.setDescription("Density of the exterior finish assembly.")
    userdefined_extfindensity.setDefaultValue(11.1)
	args << userdefined_extfindensity

	#make a double argument for exterior finish specific heat of wall cavity
	userdefined_extfinspecheat = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinspecheat", false)
	userdefined_extfinspecheat.setDisplayName("Exterior Finish: Specific Heat")
	userdefined_extfinspecheat.setUnits("Btu/lb-R")
	userdefined_extfinspecheat.setDescription("Specific heat of the exterior finish assembly.")
    userdefined_extfinspecheat.setDefaultValue(0.25)
	args << userdefined_extfinspecheat
	
	#make a double argument for exterior finish thermal absorptance of wall cavity
	userdefined_extfinthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinthermalabs", false)
	userdefined_extfinthermalabs.setDisplayName("Exterior Finish: Emissivity")
	userdefined_extfinthermalabs.setDescription("The property that determines the fraction of the incident radiation that is absorbed.")
    userdefined_extfinthermalabs.setDefaultValue(0.9)
	args << userdefined_extfinthermalabs

	#make a double argument for exterior finish solar/visible absorptance of wall cavity
	userdefined_extfinabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinabs", false)
	userdefined_extfinabs.setDisplayName("Exterior Finish: Solar Absorptivity")
	userdefined_extfinabs.setDescription("The property that determines the fraction of the incident radiation that is absorbed.")
    userdefined_extfinabs.setDefaultValue(0.3)
	args << userdefined_extfinabs

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	# Space Type
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
	
	# Gypsum
	userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
	userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
	# ICF
	userdefined_framingfrac = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)
	userdefined_icfinsthickness = runner.getDoubleArgumentValue("userdefinedicfinsthickness",user_arguments)
	userdefined_icfinsr = runner.getDoubleArgumentValue("userdefinedicfinsr",user_arguments)
	userdefined_icfconcth = runner.getDoubleArgumentValue("userdefinedicfconcth",user_arguments)
	# Rigid
	userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
	userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
	userdefined_hasosb = runner.getBoolArgumentValue("userdefinedhasosb",user_arguments)
	# Exterior Finish
	userdefined_extfinthickness = runner.getDoubleArgumentValue("userdefinedextfinthickness",user_arguments)
	userdefined_extfinr = runner.getDoubleArgumentValue("userdefinedextfinr",user_arguments)
	userdefined_extfindensity = runner.getDoubleArgumentValue("userdefinedextfindensity",user_arguments)
	userdefined_extfinspecheat = runner.getDoubleArgumentValue("userdefinedextfinspecheat",user_arguments)
	userdefined_extfinthermalabs = runner.getDoubleArgumentValue("userdefinedextfinthermalabs",user_arguments)
	userdefined_extfinabs = runner.getDoubleArgumentValue("userdefinedextfinabs",user_arguments)	

	# Constants
	mat_wood = get_mat_wood
	mat_gyp = get_mat_gypsum
	mat_air = get_mat_air
	mat_rigid = get_mat_rigid_ins
	mat_densepack_generic = get_mat_densepack_generic

	# Gypsum	
	gypsumThickness = userdefined_gypthickness
	gypsumNumLayers = userdefined_gyplayers
	gypsumConductivity = mat_gyp.k
	gypsumDensity = mat_gyp.rho
	gypsumSpecificHeat = mat_gyp.Cp
	gypsumThermalAbs = get_mat_gypsum_extwall(mat_gyp).TAbs
	gypsumSolarAbs = get_mat_gypsum_extwall(mat_gyp).SAbs
	gypsumVisibleAbs = get_mat_gypsum_extwall(mat_gyp).VAbs
	gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)

	# Rigid	
	rigidInsRvalue = userdefined_rigidinsr
	rigidInsThickness = userdefined_rigidinsthickness
	rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
	rigidInsDensity = mat_rigid.rho
	rigidInsSpecificHeat = mat_rigid.Cp	
	hasOSB = userdefined_hasosb
	osbThickness = 0.5
	osbConductivity = mat_wood.k
	osbDensity = mat_wood.rho
	osbSpecificHeat = mat_wood.Cp
	if hasOSB
		mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)	
		osbRvalue = mat_plywood1_2in.Rvalue
	else
		osbRvalue = 0
	end
	
	# ICF
	icfFramingFactor = userdefined_framingfrac
	icfInsThickness = userdefined_icfinsthickness
	icfInsRvalue = userdefined_icfinsr
	icfConcreteThickness = userdefined_icfconcth

	# Exterior Finish
	finishRvalue = userdefined_extfinr
	finishThickness = userdefined_extfinthickness
	finishConductivity = finishThickness / finishRvalue
	finishDensity = userdefined_extfindensity
	finishSpecHeat = userdefined_extfinspecheat
	finishThermalAbs = userdefined_extfinthermalabs
	finishSolarAbs = userdefined_extfinabs
	finishVisibleAbs = userdefined_extfinabs

	# Create the material class instances
	icf = ICFWall.new(icfFramingFactor, icfInsThickness, icfInsRvalue, icfConcreteThickness)
	extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
	exteriorfinish = ExteriorFinish.new(finishThickness, finishConductivity, finishRvalue)
	wallsh = WallSheathing.new(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
	
	# Create the sim object
	sim = Sim.new(model, runner)
	
	# Process the wood stud walls
	icf, wallsh = sim._processConstructionsExteriorInsulatedWallsICF(icf, extwallmass, exteriorfinish, wallsh)
	
	# Create the material layers
	
	# ICFInsForm
	insFormThickness = icf.ins_layer_thickness
	insFormConductivity = icf.ins_layer_conductivity
	insFormDensity= icf.ins_layer_density
	insFormSpecHeat = icf.ins_layer_spec_heat
	
	# ICFConcrete
	concThickness = icf.conc_layer_thickness
	concConductivity = icf.conc_layer_conductivity
	concDensity = icf.conc_layer_density
	concSpecHeat = icf.conc_layer_spec_heat
	
	# Gypsum
	gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	gypsum.setName("GypsumBoard-ExtWall")
	gypsum.setRoughness("Rough")
	gypsum.setThickness(OpenStudio::convert(gypsumThickness,"in","m").get)
	gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
	gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
	gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
	gypsum.setThermalAbsorptance(gypsumThermalAbs)
	gypsum.setSolarAbsorptance(gypsumSolarAbs)
	gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

	# Rigid
	if rigidInsRvalue > 0
	  rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      rigid.setName("WallRigidIns")
      rigid.setRoughness("Rough")
      rigid.setThickness(OpenStudio::convert(wallsh.rigid_ins_layer_thickness,"ft","m").get)
      rigid.setConductivity(OpenStudio::convert(wallsh.rigid_ins_layer_conductivity,"Btu/hr*ft*R","W/m*K").get)
      rigid.setDensity(OpenStudio::convert(wallsh.rigid_ins_layer_density,"lb/ft^3","kg/m^3").get)
      rigid.setSpecificHeat(OpenStudio::convert(wallsh.rigid_ins_layer_spec_heat,"Btu/lb*R","J/kg*K").get)
	end
	
	# OSB
	osb = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	osb.setName("Plywood-1_2in")
	osb.setRoughness("Rough")
	osb.setThickness(OpenStudio::convert(osbThickness,"in","m").get)
	osb.setConductivity(OpenStudio::convert(osbConductivity,"Btu/hr*ft*R","W/m*K").get)
	osb.setDensity(OpenStudio::convert(osbDensity,"lb/ft^3","kg/m^3").get)
	osb.setSpecificHeat(OpenStudio::convert(osbSpecificHeat,"Btu/lb*R","J/kg*K").get)
	
	# ExteriorFinish
	extfin = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	extfin.setName("ExteriorFinish")
	extfin.setRoughness("Rough")
	extfin.setThickness(OpenStudio::convert(finishThickness,"in","m").get)
	extfin.setConductivity(OpenStudio::convert(finishConductivity,"Btu*in/hr*ft^2*R","W/m*K").get)
	extfin.setDensity(OpenStudio::convert(finishDensity,"lb/ft^3","kg/m^3").get)
	extfin.setSpecificHeat(OpenStudio::convert(finishSpecHeat,"Btu/lb*R","J/kg*K").get)
	extfin.setThermalAbsorptance(finishThermalAbs)
	extfin.setSolarAbsorptance(finishSolarAbs)
	extfin.setVisibleAbsorptance(finishVisibleAbs)	
	
	# ICFInsForm
	insform = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	insform.setName("ICFInsForm")
	insform.setRoughness("Rough")
	insform.setThickness(OpenStudio::convert(insFormThickness,"ft","m").get)
	insform.setConductivity(OpenStudio::convert(insFormConductivity,"Btu/hr*ft*R","W/m*K").get)
	insform.setDensity(OpenStudio::convert(insFormDensity,"lb/ft^3","kg/m^3").get)
	insform.setSpecificHeat(OpenStudio::convert(insFormSpecHeat,"Btu/lb*R","J/kg*K").get)	
	
	# ICFConcrete
	conc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc.setName("ICFConcrete")
	conc.setRoughness("Rough")
	conc.setThickness(OpenStudio::convert(concThickness,"ft","m").get)
	conc.setConductivity(OpenStudio::convert(concConductivity,"Btu/hr*ft*R","W/m*K").get)
	conc.setDensity(OpenStudio::convert(concDensity,"lb/ft^3","kg/m^3").get)
	conc.setSpecificHeat(OpenStudio::convert(concSpecHeat,"Btu/lb*R","J/kg*K").get)		
	
	# ExtInsFinWall
	layercount = 0
	extinsfinwall = OpenStudio::Model::Construction.new(model)
	extinsfinwall.setName("ExtInsFinWall")
	extinsfinwall.insertLayer(layercount,extfin)
	layercount += 1
	if rigidInsRvalue > 0
		extinsfinwall.insertLayer(layercount,rigid)
		layercount += 1
	end
	if hasOSB
		extinsfinwall.insertLayer(layercount,osb)
		layercount += 1
	end
	extinsfinwall.insertLayer(layercount,insform)
	layercount += 1
	extinsfinwall.insertLayer(layercount,conc)
	layercount += 1
	extinsfinwall.insertLayer(layercount,insform)
	layercount += 1
	(0...gypsumNumLayers).to_a.each do |i|
		extinsfinwall.insertLayer(layercount,gypsum)
		layercount += 1
	end	
	
	# ExtInsUnfinWall
	layercount = 0
	extinsunfinwall = OpenStudio::Model::Construction.new(model)
	extinsunfinwall.setName("ExtInsUnfinWall")
	extinsunfinwall.insertLayer(layercount,extfin)
	layercount += 1
	if rigidInsRvalue > 0
		extinsunfinwall.insertLayer(layercount,rigid)
		layercount += 1
	end
	if hasOSB
		extinsunfinwall.insertLayer(layercount,osb)
		layercount += 1
	end
	extinsunfinwall.insertLayer(layercount,insform)
	layercount += 1
	extinsunfinwall.insertLayer(layercount,conc)
	layercount += 1
	extinsunfinwall.insertLayer(layercount,insform)
	
    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(extinsfinwall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"ExtInsFinWall"]
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Surface '#{key}', attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}' and with Surface Type '#{value[0]}' and Outside Boundary Condition '#{value[1]}', was assigned Construction '#{value[2]}'")
      end
    end	

    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsICF.new.registerWithApplication

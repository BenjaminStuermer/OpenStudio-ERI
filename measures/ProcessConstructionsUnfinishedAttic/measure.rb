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
class ProcessConstructionsUnfinishedAttic < OpenStudio::Ruleset::ModelUserScript

  class UnfinishedAttic
    def initialize(uACeilingInsThickness, uARoofFramingThickness, uACeilingFramingFactor, uACeilingInsRvalueNominal, uACeilingJoistThickness, uARoofContInsThickness, uARoofContInsRvalue, uARoofFramingFactor, uARoofInsThickness, uARoofInsRvalueNominal)
      @uACeilingInsThickness = uACeilingInsThickness
      @uARoofFramingThickness = uARoofFramingThickness
      @uACeilingFramingFactor = uACeilingFramingFactor
      @uACeilingInsRvalueNominal = uACeilingInsRvalueNominal
      @uACeilingJoistThickness = uACeilingJoistThickness
      @uARoofContInsThickness = uARoofContInsThickness
      @uARoofContInsRvalue = uARoofContInsRvalue
      @uARoofFramingFactor = uARoofFramingFactor
      @uARoofInsThickness = uARoofInsThickness
      @uARoofInsRvalueNominal = uARoofInsRvalueNominal
    end

    attr_accessor(:UACeilingInsThickness_Rev, :UACeilingInsRvalueNominal_Rev)

    def UACeilingInsThickness
      return @uACeilingInsThickness
    end

    def UARoofFramingThickness
      return @uARoofFramingThickness
    end

    def UACeilingFramingFactor
      return @uACeilingFramingFactor
    end

    def UACeilingInsRvalueNominal
      return @uACeilingInsRvalueNominal
    end

    def UACeilingJoistThickness
      return @uACeilingJoistThickness
    end

    def UARoofContInsThickness
      return @uARoofContInsThickness
    end

    def UARoofContInsRvalue
      return @uARoofContInsRvalue
    end

    def UARoofFramingFactor
      return @uARoofFramingFactor
    end

    def UARoofInsThickness
      return @uARoofInsThickness
    end

    def UARoofInsRvalueNominal
      return @uARoofInsRvalueNominal
    end
  end

  class Eaves
    def initialize(eavesDepth)
      @eavesDepth = eavesDepth
    end

    def EavesDepth
      return @eavesDepth
    end
  end

  class CeilingMass
    def initialize(ceilingMassGypsumThickness, ceilingMassGypsumNumLayers, rvalue, ceilingMassPCMType)
      @ceilingMassGypsumThickness = ceilingMassGypsumThickness
      @ceilingMassGypsumNumLayers = ceilingMassGypsumNumLayers
      @rvalue = rvalue
      @ceilingMassPCMType = ceilingMassPCMType
    end

    def CeilingMassGypsumThickness
      return @ceilingMassGypsumThickness
    end

    def CeilingMassGypsumNumLayers
      return @ceilingMassGypsumNumLayers
    end

    def Rvalue
      return @rvalue
    end

    def CeilingMassPCMType
      return @ceilingMassPCMType
    end
  end

  class UAAdditionalCeilingIns
    def initialize
    end
    attr_accessor(:UA_ceiling_ins_above_density, :UA_ceiling_ins_above_spec_heat)
  end

  class UATrussandIns
    def initialize
    end
    attr_accessor(:UA_ceiling_joist_ins_conductivity, :UA_ceiling_joist_ins_density, :UA_ceiling_joist_ins_spec_heat)
  end

  class RadiantBarrier
    def initialize(hasRadiantBarrier)
      @hasRadiantBarrier = hasRadiantBarrier
    end

    def HasRadiantBarrier
      return @hasRadiantBarrier
    end
  end

  class UARigidRoofIns
    def initialize
    end
    attr_accessor(:UA_roof_rigid_foam_ins_thickness, :UA_roof_rigid_foam_ins_conductivity, :UA_roof_rigid_foam_ins_density, :UA_roof_rigid_foam_ins_spec_heat)
  end

  class UARoofIns
    def initialize
    end
    attr_accessor(:UA_roof_ins_thickness, :UA_roof_ins_conductivity, :UA_roof_ins_density, :UA_roof_ins_spec_heat)
  end

  class RoofingMaterial
    def initialize(roofMatEmissivity, roofMatAbsorptivity)
      @roofMatEmissivity = roofMatEmissivity
      @roofMatAbsorptivity = roofMatAbsorptivity
    end

    def RoofMatEmissivity
      return @roofMatEmissivity
    end

    def RoofMatAbsorptivity
      return @roofMatAbsorptivity
    end
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Unfinished Attic Constructions"
  end
  
  def description
    return "This measure assigns constructions to the unfinished attic floor and ceiling."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for the unfinished attic floor and ceiling. Finds surfaces adjacent to the unfinished attic and sets applicable constructions."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    uains_display_names = OpenStudio::StringVector.new
    uains_display_names << "Uninsulated"
    uains_display_names << "Ceiling"
    uains_display_names << "Roof"

    #make a choice argument for unfinished attic insulation type
    selected_uains = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduains", uains_display_names, false)
    selected_uains.setDisplayName("Unfinished Attic: Insulation Type")
	selected_uains.setDescription("The type of insulation.")
	selected_uains.setDefaultValue("Ceiling")
    args << selected_uains

    #make a double argument for ceiling / roof insulation thickness
    userdefined_ceilroofinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedceilroofinsthickness", false)
    userdefined_ceilroofinsthickness.setDisplayName("Unfinished Attic: Ceiling/Roof Insulation Thickness")
	userdefined_ceilroofinsthickness.setUnits("in")
	userdefined_ceilroofinsthickness.setDescription("The thickness in inches of insulation required to obtain a certain R-value.")
    userdefined_ceilroofinsthickness.setDefaultValue(8.55)
    args << userdefined_ceilroofinsthickness

    #make a double argument for unfinished attic ceiling / roof insulation R-value
    userdefined_uaceilroofr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaceilroofr", false)
    userdefined_uaceilroofr.setDisplayName("Unfinished Attic: Ceiling/Roof Insulation Nominal R-value")
	userdefined_uaceilroofr.setUnits("hr-ft^2-R/Btu")
	userdefined_uaceilroofr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_uaceilroofr.setDefaultValue(30.0)
    args << userdefined_uaceilroofr

    #make a choice argument for model objects
    joistthickness_display_names = OpenStudio::StringVector.new
    joistthickness_display_names << "3.5"

    #make a string argument for wood stud size of wall cavity
    selected_joistthickness = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduaceiljoistthickness", joistthickness_display_names, false)
    selected_joistthickness.setDisplayName("Unfinished Attic: Ceiling Joist Thickness")
	selected_joistthickness.setDescription("Thickness of joists in the ceiling.")
    selected_joistthickness.setDefaultValue("3.5")
    args << selected_joistthickness

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_uaceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaceilff", false)
    userdefined_uaceilff.setDisplayName("Unfinished Attic: Ceiling Framing Factor")
	userdefined_uaceilff.setUnits("frac")
	userdefined_uaceilff.setDescription("The framing factor of the ceiling.")
    userdefined_uaceilff.setDefaultValue(0.07)
    args << userdefined_uaceilff

    #make a choice argument for model objects
    framethickness_display_names = OpenStudio::StringVector.new
    framethickness_display_names << "7.25"

    #make a string argument for unfinished attic roof framing factor
    selected_framethickness = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduaroofframethickness", framethickness_display_names, false)
    selected_framethickness.setDisplayName("Unfinished Attic: Roof Framing Thickness")
	selected_framethickness.setUnits("in")
	selected_framethickness.setDescription("Thickness of roof framing.")
    selected_framethickness.setDefaultValue("7.25")
    args << selected_framethickness

    #make a choice argument for unfinished attic roof framing factor
    userdefined_uaroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaroofff", false)
    userdefined_uaroofff.setDisplayName("Unfinished Attic: Roof Framing Factor")
	userdefined_uaroofff.setUnits("frac")
	userdefined_uaroofff.setDescription("Fraction of roof that is made up of framing elements.")
    userdefined_uaroofff.setDefaultValue(0.07)
    args << userdefined_uaroofff

    #make a double argument for rigid insulation thickness of roof cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Unfinished Attic: Roof Continuous Insulation Thickness")
	userdefined_rigidinsthickness.setUnits("in")
	userdefined_rigidinsthickness.setDescription("Thickness of rigid insulation added to the roof.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness

    #make a double argument for rigid insulation R-value of roof cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Unfinished Attic: Roof Continuous Insulation Nominal R-value")
	userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_rigidinsr.setDescription("The nominal R-value of the continuous insulation.")
    userdefined_rigidinsr.setDefaultValue(0)
    args << userdefined_rigidinsr

    #make a bool argument for radiant barrier of roof cavity
    userdefined_hasradiantbarrier = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasradiantbarrier", false)
    userdefined_hasradiantbarrier.setDisplayName("Has Radiant Barrier")
	userdefined_hasradiantbarrier.setDescription("Layers of reflective material used to reduce heat transfer between the attic roof and the ceiling insulation and ductwork (if present).")
	userdefined_hasradiantbarrier.setDefaultValue(false)
    args << userdefined_hasradiantbarrier

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Ceiling Mass: Thickness")
	userdefined_gypthickness.setUnits("in")
	userdefined_gypthickness.setDescription("Gypsum layer thickness.")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Ceiling Mass: Num Layers")
	userdefined_gyplayers.setUnits("#")
	userdefined_gyplayers.setDescription("Integer number of layers of gypsum.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

    #make a double argument for roofing material thermal absorptance of unfinished attic
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roof Material: Emissivity.")
	userdefined_roofmatthermalabs.setDescription("Infrared emissivity of the outside surface of the roof.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of unfinished attic
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roof Material: Absorptivity")
	userdefined_roofmatabs.setDescription("The solar radiation absorptance of the outside roof surface, specified as a value between 0 and 1.")
    userdefined_roofmatabs.setDefaultValue(0.85)
    args << userdefined_roofmatabs

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
    living_space_type.setDescription("Select the living space type")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type

    #make a choice argument for unfinished attic space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.UnfinishedAtticSpaceType)
        space_type_args << Constants.UnfinishedAtticSpaceType
    end
    unfin_attic_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("unfin_attic_space_type", space_type_args, true)
    unfin_attic_space_type.setDisplayName("Unfinished Attic space type")
    unfin_attic_space_type.setDescription("Select the unfinished attic space type")
    unfin_attic_space_type.setDefaultValue(Constants.UnfinishedAtticSpaceType)
    args << unfin_attic_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    eavesDepth = 0
    ceilingMassPCMType = nil
    uACeilingInsThickness = 0
    uACeilingInsRvalueNominal = 0
    uARoofInsThickness = 0
    uARoofInsRvalueNominal = 0
    rigidInsThickness = 0
    rigidInsRvalue = 0

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	unfin_attic_space_type_r = runner.getStringArgumentValue("unfin_attic_space_type",user_arguments)
    unfin_attic_space_type = HelperMethods.get_space_type_from_string(model, unfin_attic_space_type_r, runner, false)
    if unfin_attic_space_type.nil?
        # If the building has no unfinished attic, no constructions are assigned and we continue by returning True
        return true
    end

    # Unfinished Attic Insulation
    selected_uains = runner.getStringArgumentValue("selecteduains",user_arguments)

    # Ceiling / Roof Insulation
    if ["Ceiling", "Roof"].include? selected_uains.to_s
      userdefined_uaceilroofr = runner.getDoubleArgumentValue("userdefineduaceilroofr",user_arguments)
      userdefined_ceilroofinsthickness = runner.getDoubleArgumentValue("userdefinedceilroofinsthickness",user_arguments)
    end

    # Ceiling Joist Thickness
    selected_uaceiljoistthickness = runner.getStringArgumentValue("selecteduaceiljoistthickness",user_arguments)

    # Ceiling Framing Factor
    userdefined_uaceilff = runner.getDoubleArgumentValue("userdefineduaceilff",user_arguments)
    if not ( userdefined_uaceilff > 0.0 and userdefined_uaceilff < 1.0 )
      runner.registerError("Invalid unfinished attic ceiling framing factor")
      return false
    end

    # Roof Framing Thickness
    selected_uaroofframethickness = runner.getStringArgumentValue("selecteduaroofframethickness",user_arguments)

    # Roof Framing Factor
    userdefined_uaroofff = runner.getDoubleArgumentValue("userdefineduaroofff",user_arguments)
    if not ( userdefined_uaroofff > 0.0 and userdefined_uaroofff < 1.0 )
      runner.registerError("Invalid unfinished attic roof framing factor")
      return false
    end

    # Rigid
    if ["Roof"].include? selected_uains.to_s
      userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
      userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
    end

    # Radiant Barrier
    userdefined_hasradiantbarrier = runner.getBoolArgumentValue("userdefinedhasradiantbarrier",user_arguments)

    # Gypsum
    userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)

    # Exterior Finish
    userdefined_roofmatthermalabs = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
    userdefined_roofmatabs = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)

    # Constants
    mat_gyp = get_mat_gypsum
    mat_rigid = get_mat_rigid_ins

    # Insulation
    if selected_uains.to_s == "Ceiling"
      uACeilingInsThickness = userdefined_ceilroofinsthickness
      uACeilingInsRvalueNominal = userdefined_uaceilroofr
    elsif selected_uains.to_s == "Roof"
      uARoofInsThickness = userdefined_ceilroofinsthickness
      uARoofInsRvalueNominal = userdefined_uaceilroofr
    end

    # Ceiling Joist Thickness
    uACeilingJoistThickness_dict = {"3.5"=>3.5}
    uACeilingJoistThickness = uACeilingJoistThickness_dict[selected_uaceiljoistthickness]

    # Ceiling Framing Factor
    uACeilingFramingFactor = userdefined_uaceilff

    # Roof Framing Thickness
    uARoofFramingThickness_dict = {"7.25"=>7.25}
    uARoofFramingThickness = uARoofFramingThickness_dict[selected_uaroofframethickness]

    # Roof Framing Factor
    uARoofFramingFactor = userdefined_uaroofff

    # Rigid
    if selected_uains.to_s == "Roof"
      rigidInsRvalue = userdefined_rigidinsr
      rigidInsThickness = userdefined_rigidinsthickness
      rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
      rigidInsDensity = mat_rigid.rho
      rigidInsSpecificHeat = mat_rigid.Cp
    end

    # Radiant Barrier
    hasRadiantBarrier = userdefined_hasradiantbarrier

    # Gypsum
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    gypsumConductivity = mat_gyp.k
    gypsumDensity = mat_gyp.rho
    gypsumSpecificHeat = mat_gyp.Cp
    gypsumThermalAbs = get_mat_gypsum_ceiling(mat_gyp).TAbs
    gypsumSolarAbs = get_mat_gypsum_ceiling(mat_gyp).SAbs
    gypsumVisibleAbs = get_mat_gypsum_ceiling(mat_gyp).VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)

    # Roofing Material
    roofMatEmissivity = userdefined_roofmatthermalabs
    roofMatAbsorptivity = userdefined_roofmatabs

    # Create the material class instances
    uatc = UnfinishedAttic.new(uACeilingInsThickness, uARoofFramingThickness, uACeilingFramingFactor, uACeilingInsRvalueNominal, uACeilingJoistThickness, rigidInsThickness, rigidInsRvalue, uARoofFramingFactor, uARoofInsThickness, uARoofInsRvalueNominal)
    eaves_options = Eaves.new(eavesDepth)
    ceiling_mass = CeilingMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue, ceilingMassPCMType)
    uaaci = UAAdditionalCeilingIns.new
    uatai = UATrussandIns.new
    radiant_barrier = RadiantBarrier.new(hasRadiantBarrier)
    uarri = UARigidRoofIns.new
    uari = UARoofIns.new
    roofing_material = RoofingMaterial.new(roofMatEmissivity, roofMatAbsorptivity)

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the unfinished attic ceiling
    uaaci, uatai = sim._processConstructionsUnfinishedAtticCeiling(uatc, eaves_options, ceiling_mass, uaaci, uatai)

    # Process the unfinished attic roof
    uarri, uari = sim._processConstructionsUnfinishedAtticRoof(uatc, radiant_barrier, uarri, uari)

    # UAAdditionalCeilingIns
    uaaciDensity = uaaci.UA_ceiling_ins_above_density
    uaaciSpecificHeat = uaaci.UA_ceiling_ins_above_spec_heat
    if not (uatc.UACeilingInsRvalueNominal == 0 or uatc.UACeilingInsThickness_Rev == 0)
      if uatc.UACeilingInsThickness_Rev >= uatc.UACeilingJoistThickness
        if uatc.UACeilingInsThickness_Rev > uatc.UACeilingJoistThickness
          uaaci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
          uaaci.setName("UAAdditionalCeilingIns")
          uaaci.setRoughness("Rough")
          uaaci.setThickness(OpenStudio::convert(uatc.UACeilingInsThickness_Rev - uatc.UACeilingJoistThickness,"in","m").get)
          uaaci.setConductivity(OpenStudio::convert(uatc.UACeilingInsThickness_Rev,"Btu*in/hr*ft^2*R","W/m*K").get / uatc.UACeilingInsRvalueNominal_Rev)
          uaaci.setDensity(OpenStudio::convert(uaaciDensity,"lb/ft^3","kg/m^3").get)
          uaaci.setSpecificHeat(OpenStudio::convert(uaaciSpecificHeat,"Btu/lb*R","J/kg*K").get)
        end
      end
    end

    # ConcPCMCeilWall
    if ceiling_mass.CeilingMassPCMType == Constants.PCMtypeConcentrated
      pcm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      pcm.setName("ConcPCMCeilWall")
      pcm.setRoughness("Rough")
      pcm.setThickness(OpenStudio::convert(get_mat_ceil_pcm_conc(get_mat_ceil_pcm(ceiling_mass), ceiling_mass).thick,"ft","m").get)
      pcm.setConductivity()
      pcm.setDensity()
      pcm.setSpecificHeat()
    end

    # Gypsum
    gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gypsum.setName("GypsumBoard-Ceiling")
    gypsum.setRoughness("Rough")
    gypsum.setThickness(OpenStudio::convert(gypsumThickness,"in","m").get)
    gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
    gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
    gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
    gypsum.setThermalAbsorptance(gypsumThermalAbs)
    gypsum.setSolarAbsorptance(gypsumSolarAbs)
    gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

    # FinInsUnfinUAFloor
    materials = []
    if ceiling_mass.CeilingMassPCMType == Constants.PCMtypeConcentrated
       materials << pcm
    end
    (0...gypsumNumLayers).to_a.each do |i|
      materials << gypsum
    end	

    # UATrussandIns
    uataiConductivity = uatai.UA_ceiling_joist_ins_conductivity
    uataiDensity = uatai.UA_ceiling_joist_ins_density
    uataiSpecificHeat = uatai.UA_ceiling_joist_ins_spec_heat
    if uatc.UACeilingInsRvalueNominal_Rev != 0 and uatc.UACeilingInsThickness_Rev != 0
      uatai = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      uatai.setName("UATrussandIns")
      uatai.setRoughness("Rough")
      uatai.setThickness(OpenStudio::convert(uatc.UACeilingJoistThickness,"in","m").get)
      uatai.setConductivity(OpenStudio::convert(uataiConductivity,"Btu/hr*ft*R","W/m*K").get)
      uatai.setDensity(OpenStudio::convert(uataiDensity,"lb/ft^3","kg/m^3").get)
      uatai.setSpecificHeat(OpenStudio::convert(uataiSpecificHeat,"Btu/lb*R","J/kg*K").get)
      materials << uatai
      if uatc.UACeilingInsThickness_Rev > uatc.UACeilingJoistThickness
        materials << uaaci
      end
    else
      # Without insulation, we run the risk of CTF errors ("Construction too thin or too light")
      # We add a layer here to prevent that error.
      ctf = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      ctf.setName("AddforCTFCalc")
      ctf.setRoughness("Rough")
      ctf.setThickness(OpenStudio::convert(0.75,"in","m").get)
      ctf.setConductivity(OpenStudio::convert(get_mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
      ctf.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
      ctf.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)
      materials << ctf
    end
    fininsunfinuafloor = OpenStudio::Model::Construction.new(materials)
    fininsunfinuafloor.setName("FinInsUnfinUAFloor")	

    # RevFinInsUnfinUAFloor
    revfininsunfinuafloor = fininsunfinuafloor.reverseConstruction
    revfininsunfinuafloor.setName("RevFinInsUnfinUAFloor")

    # RoofingMaterial
    mat_roof_mat = get_mat_roofing_mat(roofing_material)
    roofmat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    roofmat.setName("RoofingMaterial")
    roofmat.setRoughness("Rough")
    roofmat.setThickness(OpenStudio::convert(mat_roof_mat.thick,"ft","m").get)
    roofmat.setConductivity(OpenStudio::convert(mat_roof_mat.k,"Btu/hr*ft*R","W/m*K").get)
    roofmat.setDensity(OpenStudio::convert(mat_roof_mat.rho,"lb/ft^3","kg/m^3").get)
    roofmat.setSpecificHeat(OpenStudio::convert(mat_roof_mat.Cp,"Btu/lb*R","J/kg*K").get)
    roofmat.setThermalAbsorptance(mat_roof_mat.TAbs)
    roofmat.setSolarAbsorptance(mat_roof_mat.SAbs)
    roofmat.setVisibleAbsorptance(mat_roof_mat.VAbs)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(get_mat_wood).thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(get_mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # RadiantBarrier
    mat_radiant_barrier = get_mat_radiant_barrier
    radbar = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    radbar.setName("RadiantBarrier")
    radbar.setRoughness("Rough")
    radbar.setThickness(OpenStudio::convert(mat_radiant_barrier.thick,"ft","m").get)
    radbar.setConductivity(OpenStudio::convert(mat_radiant_barrier.k,"Btu/hr*ft*R","W/m*K").get)
    radbar.setDensity(OpenStudio::convert(mat_radiant_barrier.rho,"lb/ft^3","kg/m^3").get)
    radbar.setSpecificHeat(OpenStudio::convert(mat_radiant_barrier.Cp,"Btu/lb*R","J/kg*K").get)
    radbar.setThermalAbsorptance(mat_radiant_barrier.TAbs)
    radbar.setSolarAbsorptance(mat_radiant_barrier.SAbs)
    radbar.setVisibleAbsorptance(mat_radiant_barrier.VAbs)

    # UARigidRoofIns
    if uatc.UARoofContInsThickness > 0
      uarriThickness = uarri.UA_roof_rigid_foam_ins_thickness
      uarriConductivity = uarri.UA_roof_rigid_foam_ins_conductivity
      uarriDensity = uarri.UA_roof_rigid_foam_ins_density
      uarriSpecificHeat = uarri.UA_roof_rigid_foam_ins_spec_heat
      uarri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      uarri.setName("UARigidRoofIns")
      uarri.setRoughness("Rough")
      uarri.setThickness(OpenStudio::convert(uarriThickness,"ft","m").get)
      uarri.setConductivity(OpenStudio::convert(uarriConductivity,"Btu/hr*ft*R","W/m*K").get)
      uarri.setDensity(OpenStudio::convert(uarriDensity,"lb/ft^3","kg/m^3").get)
      uarri.setSpecificHeat(OpenStudio::convert(uarriSpecificHeat,"Btu/lb*R","J/kg*K").get)
    end

    # UARoofIns
    uariThickness = uari.UA_roof_ins_thickness
    uariConductivity = uari.UA_roof_ins_conductivity
    uariDensity = uari.UA_roof_ins_density
    uariSpecificHeat = uari.UA_roof_ins_spec_heat
    uari = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    uari.setName("UARoofIns")
    uari.setRoughness("Rough")
    uari.setThickness(OpenStudio::convert(uariThickness,"ft","m").get)
    uari.setConductivity(OpenStudio::convert(uariConductivity,"Btu/hr*ft*R","W/m*K").get)
    uari.setDensity(OpenStudio::convert(uariDensity,"lb/ft^3","kg/m^3").get)
    uari.setSpecificHeat(OpenStudio::convert(uariSpecificHeat,"Btu/lb*R","J/kg*K").get)

    # UnfinInsExtRoof
    materials = []
    materials << roofmat
    materials << ply3_4
    if uatc.UARoofContInsThickness > 0
      materials << uarri
      materials << ply3_4
    end
    materials << uari
    if radiant_barrier.HasRadiantBarrier
      materials << radbar
    end
    unfininsextroof = OpenStudio::Model::Construction.new(materials)
    unfininsextroof.setName("UnfinInsExtRoof")	

	
	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless ["roofceiling"].include? living_surface.surfaceType.downcase
		adjacent_surface = living_surface.adjacentSurface
		next unless adjacent_surface.is_initialized
		adjacent_surface = adjacent_surface.get
	    adjacent_surface_r = adjacent_surface.name.to_s
	    adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
	    next unless [unfin_attic_space_type_r].include? adjacent_space_type_r
	    living_surface.setConstruction(revfininsunfinuafloor)
		runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{revfininsunfinuafloor.name}'")
	    adjacent_surface.setConstruction(fininsunfinuafloor)		
		runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{fininsunfinuafloor.name}'")
	  end	
	end	
	
	unfin_attic_space_type.spaces.each do |unfin_attic_space|
	  unfin_attic_space.surfaces.each do |unfin_attic_surface|
	    next unless unfin_attic_surface.surfaceType.downcase == "roofceiling" and unfin_attic_surface.outsideBoundaryCondition.downcase == "outdoors"
	    unfin_attic_surface.setConstruction(unfininsextroof)
		runner.registerInfo("Surface '#{unfin_attic_surface.name}', of Space Type '#{unfin_attic_space_type_r}' and with Surface Type '#{unfin_attic_surface.surfaceType}' and Outside Boundary Condition '#{unfin_attic_surface.outsideBoundaryCondition}', was assigned Construction '#{unfininsextroof.name}'")		
	  end	
	end	

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUnfinishedAttic.new.registerWithApplication
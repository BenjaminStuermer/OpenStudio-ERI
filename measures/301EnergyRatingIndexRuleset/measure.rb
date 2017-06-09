# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require "pathname"
require "#{File.dirname(__FILE__)}/resources/301"
require "#{File.dirname(__FILE__)}/resources/hpxml"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/helper_methods"

# start the measure
class EnergyRatingIndex301 < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Generate Energy Rating Index Model"
  end

  # human readable description
  def description
    return "Generates a model from a HPXML building description as defined by the ANSI/RESNET 301-2014 ruleset. Used as part of the caclulation of an Energy Rating Index."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the provided HPXML building description and choice of calculation type (e.g., #{Constants.CalcTypeERIReferenceHome}, #{Constants.CalcTypeERIRatedHome}, etc.), creates an updated version of the HPXML file as well as an OpenStudio model, as specified by ANSI/RESNET 301-2014 \"Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index\"."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for design type
    calc_types = []
    #calc_types << Constants.CalcTypeStandard
    calc_types << Constants.CalcTypeERIReferenceHome
    calc_types << Constants.CalcTypeERIRatedHome
    #calc_types << Constants.CalcTypeERIIndexAdjustmentDesign
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("calc_type", calc_types, true)
    calc_type.setDisplayName("Calculation Type")
    calc_type.setDescription("'#{Constants.CalcTypeStandard}' will use the DOE Building America Simulation Protocols. HERS options will use the ANSI/RESNET 301-2014 Standard.")
    calc_type.setDefaultValue(Constants.CalcTypeStandard)
    args << calc_type

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_file_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute (or relative) path of the HPXML file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", true)
    arg.setDisplayName("EPW File Path")
    arg.setDescription("Absolute (or relative) path of the EPW weather file to assign. The corresponding DDY file must also be in the same directory.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("measures_dir", true)
    arg.setDisplayName("Residential Measures Directory")
    arg.setDescription("Absolute path of the residential measures.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("schemas_dir", true)
    arg.setDisplayName("HPXML Schemas Directory")
    arg.setDescription("Absolute path of the hpxml schemas.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("output_file_path", false)
    arg.setDisplayName("HPXML Output File Path")
    arg.setDescription("Absolute (or relative) path of the output HPXML file.")
    args << arg
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    calc_type = runner.getStringArgumentValue("calc_type", user_arguments)
    hpxml_file_path = runner.getStringArgumentValue("hpxml_file_path", user_arguments)
    weather_file_path = runner.getStringArgumentValue("weather_file_path", user_arguments)
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)
    schemas_dir = runner.getStringArgumentValue("schemas_dir", user_arguments)
    output_file_path = runner.getOptionalStringArgumentValue("output_file_path", user_arguments)

    unless (Pathname.new hpxml_file_path).absolute?
      hpxml_file_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_file_path))
    end 
    unless File.exists?(hpxml_file_path) and hpxml_file_path.downcase.end_with? ".xml"
      runner.registerError("'#{hpxml_file_path}' does not exist or is not an .xml file.")
      return false
    end
    
    unless (Pathname.new weather_file_path).absolute?
      weather_file_path = File.expand_path(File.join(File.dirname(__FILE__), weather_file_path))
    end
    unless File.exists?(weather_file_path) and weather_file_path.downcase.end_with? ".epw"
      runner.registerError("'#{weather_file_path}' does not exist or is not an .epw file.")
      return false
    end
    
    unless (Pathname.new measures_dir).absolute?
      measures_dir = File.expand_path(File.join(File.dirname(__FILE__), measures_dir))
    end
    unless Dir.exists?(measures_dir)
      runner.registerError("'#{measures_dir}' does not exist.")
      return false
    end
    
    unless (Pathname.new schemas_dir).absolute?
      schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
    end
    unless Dir.exists?(schemas_dir)
      runner.registerError("'#{schemas_dir}' does not exist.")
      return false
    end
    
    hpxml_doc = REXML::Document.new(File.read(hpxml_file_path))
    
    show_measure_calls=false
    
    # Validate input HPXML
    has_errors = false
    XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd")).each do |error|
      runner.registerError("Input HPXML: #{error.to_s}")
      has_errors = true
    end
    if has_errors
      return false
    end
    
    # Apply Location measure to obtain weather data
    measures = {}
    measure_subdir = "ResidentialLocation"
    args = {
            "weather_directory"=>File.dirname(weather_file_path),
            "weather_file_name"=>File.basename(weather_file_path),
            "dst_start_date"=>"NA",
            "dst_end_date"=>"NA"
           }
    measures[measure_subdir] = args
    if not apply_measures(measures_dir, measures, runner, model, show_measure_calls)
      return false
    end
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    
    # Apply 301 ruleset on HPXML object
    errors, building = EnergyRatingIndex301Ruleset.apply_ruleset(hpxml_doc, calc_type, weather)
    errors.each do |error|
      runner.registerError(error)
    end
    unless errors.empty?
      return false
    end
    
    if output_file_path.is_initialized
      XMLHelper.write_file(hpxml_doc, output_file_path.get)
    end
    
    # Validate new HPXML
    has_errors = false
    XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd")).each do |error|
      runner.registerError("Generated HPXML: #{error.to_s}")
      has_errors = true
    end
    if has_errors
      return false
    end
    
    # Obtain list of OpenStudio measures (and arguments)
    measures = OSMeasures.build_measures_from_hpxml(building, weather_file_path)
    
    #puts "measures #{measures.to_s}"
    
    # Create OpenStudio model
    if not OSModel.create_geometry(building, runner, model)
      return false
    end
    if not apply_measures(measures_dir, measures, runner, model, show_measure_calls)
      return false
    end
    
    return true

  end
  
end

# register the measure to be used by the application
EnergyRatingIndex301.new.registerWithApplication

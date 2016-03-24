
# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class HelperMethods

    # Retrieves the number of bedrooms and bathrooms from the space type
    # They are assigned in the SetResidentialBedroomsAndBathrooms measure.
    def self.get_bedrooms_bathrooms(model, runner=nil)
        nbeds = nil
        nbaths = nil
        model.getSpaces.each do |space|
            space_equipments = space.electricEquipment
            space_equipments.each do |space_equipment|
                name = space_equipment.electricEquipmentDefinition.name.get.to_s
                br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(name)
                ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(name)	
                if br_regexpr
                    nbeds = br_regexpr[:br].to_f
                elsif ba_regexpr
                    nbaths = ba_regexpr[:ba].to_f
                end
            end
        end
        if nbeds.nil? or nbaths.nil?
            if not runner.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            end
        end
        return [nbeds, nbaths]
    end
	
    def self.get_bedrooms_bathrooms_from_idf(workspace, runner=nil)
        nbeds = nil
        nbaths = nil
		electricEquipments = workspace.getObjectsByType("ElectricEquipment".to_IddObjectType)
        electricEquipments.each do |electricEquipment|
            br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(electricEquipment.getString(0).to_s)
            ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(electricEquipment.getString(0).to_s)	
            if br_regexpr
                nbeds = br_regexpr[:br].to_f
            elsif ba_regexpr
                nbaths = ba_regexpr[:ba].to_f
            end
        end
        if nbeds.nil? or nbaths.nil?
            if not runner.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            end
        end
        return [nbeds, nbaths]
    end	
    
	# Removes the number of bedrooms and bathrooms in the model
    def self.remove_bedrooms_bathrooms(model)
        model.getSpaces.each do |space|
            space_equipments = space.electricEquipment
            space_equipments.each do |space_equipment|
                name = space_equipment.electricEquipmentDefinition.name.get.to_s
                br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(name)
                ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(name)	
                if br_regexpr
                    space_equipment.electricEquipmentDefinition.remove
                elsif ba_regexpr
                    space_equipment.electricEquipmentDefinition.remove
                end
            end
        end
    end	
	
    # Retrieves the floor area of the specified space type
    def self.get_floor_area_for_space_type(model, spacetype_handle)
        floor_area = 0
        model.getSpaceTypes.each do |spaceType|
            if spaceType.handle.to_s == spacetype_handle.to_s
                floor_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
            end
        end
        return floor_area
    end
    
    # Retrieves the conditioned floor area for the building
    def self.get_building_conditioned_floor_area(model, runner=nil)
        floor_area = 0
        model.getThermalZones.each do |zone|
            if self.zone_is_conditioned(zone)
                runner.registerWarning(zone.name.to_s)
                floor_area += OpenStudio.convert(zone.floorArea,"m^2","ft^2").get
            end
        end
        if floor_area == 0 and not runner.nil?
            runner.registerError("Could not find any conditioned floor area. Please assign HVAC equipment first.")
            return nil
        end
        return floor_area
    end
    
    def self.zone_is_conditioned(zone)
        # FIXME: Ugly hack until we can get conditioned floor area from OS
        if zone.name.to_s == Constants.LivingZone or zone.name.to_s == Constants.FinishedBasementZone
            return true
        end
        return false
    end
    
    def self.get_default_space(model, runner=nil)
        space = nil
        model.getSpaces.each do |s|
            if s.name.to_s == Constants.LivingSpace(1) # Try to return our living space
                return s
            elsif space.nil? # Return first space in list if our living space not found
                space = s
            end
        end
        if space.nil? and not runner.nil?
            runner.registerError("Could not find any spaces in the model.")
        end
        return space
    end
    
    def self.get_space_type_from_string(model, spacetype_s, runner, print_err=true)
        space_type = nil
        model.getSpaceTypes.each do |st|
            if st.name.to_s == spacetype_s
                space_type = st
                break
            end
        end
        if space_type.nil?
            if print_err
                runner.registerError("Could not find space type with the name '#{spacetype_s}'.")
            else
                runner.registerWarning("Could not find space type with the name '#{spacetype_s}'.")
            end
        end
        return space_type
    end
	
    def self.get_space_from_string(model, space_s, runner, print_err=true)
        space = nil
        model.getSpaces.each do |s|
            if s.name.to_s == space_s
                space = s
                break
            end
        end
        if space.nil?
            if print_err
                runner.registerError("Could not find space with the name '#{space_s}'.")
            else
                runner.registerWarning("Could not find space with the name '#{space_s}'.")
            end
        end
        return space
    end

    def self.get_thermal_zone_from_string(model, thermalzone_s, runner, print_err=true)
        thermal_zone = nil
        model.getThermalZones.each do |tz|
            if tz.name.to_s == thermalzone_s
                thermal_zone = tz
                break
            end
        end
        if thermal_zone.nil?
            if print_err
                runner.registerError("Could not find thermal zone with the name '#{thermalzone_s}'.")
            else
                runner.registerWarning("Could not find thermal zone with the name '#{thermalzone_s}'.")
            end
        end
        return thermal_zone
    end

    def self.get_thermal_zone_from_string_from_idf(workspace, thermalzone_s, runner, print_err=true)
        thermal_zone = nil
        workspace.getObjectsByType("Zone".to_IddObjectType).each do |tz|
            if tz.getString(0).to_s == thermalzone_s
                thermal_zone = tz
                break
            end
        end
        if thermal_zone.nil?
            if print_err
                runner.registerError("Could not find thermal zone with the name '#{thermalzone_s}'.")
            else
                runner.registerWarning("Could not find thermal zone with the name '#{thermalzone_s}'.")
            end
        end
        return thermal_zone
    end		
    
	def self.get_space_type_from_surface(model, surface_s, print_err=true)
		space_type_r = nil
		model.getSpaces.each do |space|
			space.surfaces.each do |s|
				if s.name.to_s == surface_s
					space_type_r = space.spaceType.get.name.to_s
					break
				end
			end
		end
        if space_type_r.nil?
            if print_err
                runner.registerError("Could not find surface with the name '#{surface_s}'.")
            else
                runner.registerWarning("Could not find surface with the name '#{surface_s}'.")
            end
        end		
		return space_type_r
	end
    
    def self.remove_object_from_idf_based_on_name(workspace, name_s, object_s, runner=nil)
      workspace.getObjectsByType(object_s.to_IddObjectType).each do |str|
        n = str.getString(0).to_s
        name_s.each do |name|
		  if n.include? name
		    str.remove
		    unless runner.nil?
			  runner.registerInfo("Removed object '#{object_s} - #{n}'")
		    end
            break
		  end
		end
      end
      return workspace
    end
	
    def self.get_plant_loop_from_string(model, plantloop_s, runner, print_err=true)
        plant_loop = nil
        model.getPlantLoops.each do |pl|
            if pl.name.to_s == plantloop_s
                plant_loop = pl
                break
            end
        end
        if plant_loop.nil?
            if print_err
                runner.registerError("Could not find plant loop with the name '#{plantloop_s}'.")
            else
                runner.registerWarning("Could not find plant loop with the name '#{plantloop_s}'.")
            end
        end
        return plant_loop
    end
	
	def self.eplus_fuel_map(fuel)
		if fuel == Constants.FuelTypeElectric
			return "Electricity"
		elsif fuel == Constants.FuelTypeGas
			return "NaturalGas"
		elsif fuel == Constants.FuelTypeOil
			return "FuelOil#1"
		elsif fuel == Constants.FuelTypePropane
			return "Propane"
		end
	end
    
    def self.remove_existing_hvac_equipment_except_for_specified_object(model, runner, thermal_zone, excepted_object=nil)
        htg_coil = nil
        clg_coil = nil
        airLoopHVACs = model.getAirLoopHVACs
        airLoopHVACs.each do |airLoopHVAC|
          thermalZones = airLoopHVAC.thermalZones
          thermalZones.each do |thermalZone|
            if thermal_zone.handle.to_s == thermalZone.handle.to_s
              supplyComponents = airLoopHVAC.supplyComponents
              supplyComponents.each do |supplyComponent|
                if supplyComponent.to_AirLoopHVACUnitarySystem.is_initialized
                  air_loop_unitary = supplyComponent.to_AirLoopHVACUnitarySystem.get
                  if excepted_object == "Furnace"
                      if air_loop_unitary.heatingCoil.is_initialized
                        htg_coil = air_loop_unitary.heatingCoil.get
                        if htg_coil.to_CoilHeatingGas.is_initialized
                          htg_coil = htg_coil.clone
                          htg_coil = htg_coil.to_CoilHeatingGas.get
                        end
                        if htg_coil.to_CoilHeatingElectric.is_initialized
                          htg_coil = htg_coil.clone
                          htg_coil = htg_coil.to_CoilHeatingElectric.get
                        end
                      end
                  elsif excepted_object == "Central Air Conditioner"
                      if air_loop_unitary.coolingCoil.is_initialized
                        clg_coil = air_loop_unitary.coolingCoil.get
                        if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
                          clg_coil = clg_coil.clone
                          clg_coil = clg_coil.to_CoilCoolingDXSingleSpeed.get
                        end
                        if clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
                          clg_coil = clg_coil.clone
                          clg_coil = clg_coil.to_CoilCoolingDXMultiSpeed.get
                        end
                      end
                  end
                end
                runner.registerInfo("Removed '#{supplyComponent.name}' from air loop '#{airLoopHVAC.name}'")
                supplyComponent.remove
              end
              runner.registerInfo("Removed air loop '#{airLoopHVAC.name}'")
              airLoopHVAC.remove
            end
          end
        end     
        unless htg_coil.nil?
            return htg_coil
        end
        unless clg_coil.nil?
            return clg_coil
        end
    end
    
    def self.get_heating_or_cooling_season_schedule_object(model, runner, name)
        seasonschedule = nil
        scheduleRulesets = model.getScheduleRulesets
        scheduleRulesets.each do |scheduleRuleset|
          if scheduleRuleset.name.to_s == name
            seasonschedule = scheduleRuleset
            break
          end
        end
        return seasonschedule
    end  

    def self.Iterate(x0,f0,x1,f1,x2,f2,icount,cvg)
        '''
        Description:
        ------------
            Determine if a guess is within tolerance for convergence
            if not, output a new guess using the Newton-Raphson method

        Source:
        -------
            Based on XITERATE f77 code in ResAC (Brandemuehl)

        Inputs:
        -------
            x0      float    current guess value
            f0      float    value of function f(x) at current guess value

            x1,x2   floats   previous two guess values, used to create quadratic
                             (or linear fit)
            f1,f2   floats   previous two values of f(x)

            icount  int      iteration count
            cvg     bool     Has the iteration reached convergence?

        Outputs:
        --------
            x_new   float    new guess value
            cvg     bool     Has the iteration reached convergence?

            x1,x2   floats   updated previous two guess values, used to create quadratic
                             (or linear fit)
            f1,f2   floats   updated previous two values of f(x)

        Example:
        --------

            # Find a value of x that makes f(x) equal to some specific value f:

            # initial guess (all values of x)
            x = 1.0
            x1 = x
            x2 = x

            # initial error
            error = f - f(x)
            error1 = error
            error2 = error

            itmax = 50  # maximum iterations
            cvg = False # initialize convergence to "False"

            for i in range(1,itmax+1):
                error = f - f(x)
                x,cvg,x1,error1,x2,error2 = \
                                         Iterate(x,error,x1,error1,x2,error2,i,cvg)

                if cvg:
                    break
            if cvg:
                print "x converged after", i, :iterations"
            else:
                print "x did NOT converge after", i, "iterations"

            print "x, when f(x) is", f,"is", x
        '''

        tolRel = 1e-5
        dx = 0.1

        # Test for convergence
        if ((x0-x1).abs < tolRel*[x0.abs,Constants.small].max and icount != 1) or f0 == 0
            x_new = x0
            cvg = true
        else
            cvg = false

            if icount == 1 # Perturbation
                mode = 1
            elsif icount == 2 # Linear fit
                mode = 2
            else # Quadratic fit
                mode = 3
            end

            if mode == 3
                # Quadratic fit
                if x0 == x1 # If two xi are equal, use a linear fit
                    x1 = x2
                    f1 = f2
                    mode = 2
                elsif x0 == x2  # If two xi are equal, use a linear fit
                    mode = 2
                else
                    # Set up quadratic coefficients
                    c = ((f2 - f0)/(x2 - x0) - (f1 - f0)/(x1 - x0))/(x2 - x1)
                    b = (f1 - f0)/(x1 - x0) - (x1 + x0)*c
                    a = f0 - (b + c*x0)*x0

                    if c.abs < Constants.small # If points are co-linear, use linear fit
                        mode = 2
                    elsif ((a + (b + c*x1)*x1 - f1)/f1).abs > Constants.small
                        # If coefficients do not accurately predict data points due to
                        # round-off, use linear fit
                        mode = 2
                    else
                        d = b**2 - 4.0*a*c # calculate discriminant to check for real roots
                        if d < 0.0 # if no real roots, use linear fit
                            mode = 2
                        else
                            if d > 0.0 # if real unequal roots, use nearest root to recent guess
                                x_new = (-b + Math.sqrt(d))/(2*c)
                                x_other = -x_new - b/c
                                if (x_new - x0).abs > (x_other - x0).abs
                                    x_new = x_other
                                end
                            else # If real equal roots, use that root
                                x_new = -b/(2*c)
                            end

                            if f1*f0 > 0 and f2*f0 > 0 # If the previous two f(x) were the same sign as the new
                                if f2.abs > f1.abs
                                    x2 = x1
                                    f2 = f1
                                end
                            else
                                if f2*f0 > 0
                                    x2 = x1
                                    f2 = f1
                                end
                            end
                            x1 = x0
                            f1 = f0
                        end
                    end
                end
            end

            if mode == 2
                # Linear Fit
                m = (f1-f0)/(x1-x0)
                if m == 0 # If slope is zero, use perturbation
                    mode = 1
                else
                    x_new = x0-f0/m
                    x2 = x1
                    f2 = f1
                    x1 = x0
                    f1 = f0
                end
            end

            if mode == 1
                # Perturbation
                if x0.abs > Constants.small
                    x_new = x0*(1+dx)
                else
                    x_new = dx
                end
                x2 = x1
                f2 = f1
                x1 = x0
                f1 = f0
            end
        end
        return x_new,cvg,x1,f1,x2,f2
    end
    
    def self.biquadratic(x,y,c)
        '''
        Description:
        ------------
            Calculate the result of a biquadratic polynomial with independent variables
            x and y, and a list of coefficients, C:

            z = C[1] + C[2]*x + C[3]*x**2 + C[4]*y + C[5]*y**2 + C[6]*x*y

        Inputs:
        -------
            x       float      independent variable 1
            y       float      independent variable 2
            C       tuple      list of 6 coeffients [floats]

        Outputs:
        --------
            z       float      result of biquadratic polynomial
        '''
        if c.length != 6
            puts "Error: There must be 6 coefficients in a biquadratic polynomial"
        end
        z = c[0] + c[1]*x + c[2]*x**2 + c[3]*y + c[4]*y**2 + c[5]*y*x
        return z
    end
    
end

class HVAC

    def self.calc_EIR_from_COP(cop, supplyFanPower_Rated)
        return OpenStudio::convert((OpenStudio::convert(1,"Btu","W*h").get + supplyFanPower_Rated * 0.03333) / cop - supplyFanPower_Rated * 0.03333,"W*h","Btu").get
    end
  
    def self.calc_EIR_from_EER(eer, supplyFanPower_Rated)
        return OpenStudio::convert((1 - OpenStudio::convert(supplyFanPower_Rated * 0.03333,"W*h","Btu").get) / eer - supplyFanPower_Rated * 0.03333,"W*h","Btu").get
    end
    
    def self.calc_cfm_ton_rated(rated_airflow_rate, fanspeed_ratios, capacity_ratios)
        array = Array.new
        fanspeed_ratios.each_with_index do |fanspeed_ratio, i|
            capacity_ratio = capacity_ratios[i]
            array << fanspeed_ratio * rated_airflow_rate / capacity_ratio
        end
        return array
    end      
    
    def self.get_cooling_coefficients(runner, num_speeds, is_ideal_system, isHeatPump, curves)
    if not [1,2,4,Constants.Num_Speeds_MSHP].include? num_speeds
        runner.registerError("Number_Speeds = #{num_speeds} is not supported. Only 1, 2, 4, and 10 cooling equipment can be modeled.")
        return false
    end

    # Hard coded curves
    if is_ideal_system
        if num_speeds == 1
            curves.COOL_CAP_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.COOL_EIR_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.COOL_CAP_FFLOW_SPEC_coefficients = [1, 0, 0]
            curves.COOL_EIR_FFLOW_SPEC_coefficients = [1, 0, 0]
            
        elsif num_speeds > 1
            curves.COOL_CAP_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.COOL_EIR_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
            curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
        
        end
            
    else
        if isHeatPump
            if num_speeds == 1
                curves.COOL_CAP_FT_SPEC_coefficients = [3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]
                curves.COOL_EIR_FT_SPEC_coefficients = [-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [0.718664047, 0.41797409, -0.136638137]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [1.143487507, -0.13943972, -0.004047787]
                
            elsif num_speeds == 2
                # one set for low, one set for high
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716], [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405], [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[0.655239515, 0.511655216, -0.166894731], [0.618281092, 0.569060264, -0.187341356]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1.639108268, -0.998953996, 0.359845728], [1.570774717, -0.914152018, 0.343377302]]
        
            elsif num_speeds == 4
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.63396857, -0.093606786, 0.000918114, 0.011852512, -0.0000318307, -0.000206446],
                                                        [1.808745668, -0.041963484, 0.000545263, 0.011346539, -0.000023838, -0.000205162],
                                                        [0.112814745, 0.005638646, 0.000203427, 0.011981545, -0.0000207957, -0.000212379],
                                                        [1.141506147, -0.023973142, 0.000420763, 0.01038334, -0.0000174633, -0.000197092]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-1.380674217, 0.083176919, -0.000676029, -0.028120348, 0.000320593, -0.0000616147],
                                                        [4.817787321, -0.100122768, 0.000673499, -0.026889359, 0.00029445, -0.0000390331],
                                                        [-1.502227232, 0.05896401, -0.000439349, 0.002198465, 0.000148486, -0.000159553],
                                                        [-3.443078025, 0.115186164, -0.000852001, 0.004678056, 0.000134319, -0.000171976]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
        
            elsif num_speeds == Constants.Num_Speeds_MSHP
                # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
                curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
                curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds
                
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds

            end
                
        else #AC
            if num_speeds == 1
                curves.COOL_CAP_FT_SPEC_coefficients = [3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]
                curves.COOL_EIR_FT_SPEC_coefficients = [-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [0.718605468, 0.410099989, -0.128705457]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [1.32299905, -0.477711207, 0.154712157]
                
            elsif num_speeds == 2
                # one set for low, one set for high
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658], \
                                                        [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539], \
                                                        [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[0.65673024, 0.516470835, -0.172887149], [0.690334551, 0.464383753, -0.154507638]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1.562945114, -0.791859997, 0.230030877], [1.31565404, -0.482467162, 0.166239001]]

            elsif num_speeds == 4
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.845135427537, -0.095933272242, 0.000924533273, 0.008939030321, -0.000021025870, -0.000191684744], \
                                                        [1.902445285801, -0.042809294549, 0.000555959865, 0.009928999493, -0.000013373437, -0.000211453245], \
                                                        [-3.176259152730, 0.107498394091, -0.000574951600, 0.005484032413, -0.000011584801, -0.000135528854], \
                                                        [1.216308942608, -0.021962441981, 0.000410292252, 0.007362335339, -0.000000025748, -0.000202117724]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-1.400822352, 0.075567798, -0.000589362, -0.024655521, 0.00032690848, -0.00010222178], \
                                                        [3.278112067, -0.07106453, 0.000468081, -0.014070845, 0.00022267912, -0.00004950051], \
                                                        [1.183747649, -0.041423179, 0.000390378, 0.021207528, 0.00011181091, -0.00034107189], \
                                                        [-3.97662986, 0.115338094, -0.000841943, 0.015962287, 0.00007757092, -0.00018579409]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                
            elsif num_speeds == Constants.Num_Speeds_MSHP
                # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
                curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
                curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds
                
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                
            end
        end
    end   
    return curves
    end

    def self.get_heating_coefficients(runner, num_speeds, is_ideal_system, curves, min_compressor_temp=nil)
    # Hard coded curves
    if is_ideal_system
        if num_speeds == 1
            curves.HEAT_CAP_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.HEAT_EIR_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [1, 0, 0]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [1, 0, 0]
            
        else
            curves.HEAT_CAP_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.HEAT_EIR_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
            
        end

    else
        if num_speeds == 1
            curves.HEAT_CAP_FT_SPEC_coefficients = [0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]
            curves.HEAT_EIR_FT_SPEC_coefficients = [0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [0.694045465, 0.474207981, -0.168253446]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [2.185418751, -1.942827919, 0.757409168]

        elsif num_speeds == 2
            
            if min_compressor_temp.nil? or not HVAC.is_cold_climate_hp(num_speeds, min_compressor_temp)
            
                # one set for low, one set for high
                curves.HEAT_CAP_FT_SPEC_coefficients = [[0.335690634, 0.002405123, -0.0000464, 0.013498735, 0.0000499, -0.00000725], [0.306358843, 0.005376987, -0.0000579, 0.011645092, 0.0000591, -0.0000203]]
                curves.HEAT_EIR_FT_SPEC_coefficients = [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723], [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
                curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[0.741466907, 0.378645444, -0.119754733], [0.76634609, 0.32840943, -0.094701495]]
                curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[2.153618211, -1.737190609, 0.584269478], [2.001041353, -1.58869128, 0.587593517]]
                
            else
                 
                #ORNL cold climate heat pump
                curves.HEAT_CAP_FT_SPEC_coefficients = [[0.821139, 0, 0, 0.005111, -0.00002778, 0], [0.821139, 0, 0, 0.005111, -0.00002778, 0]]   
                curves.HEAT_EIR_FT_SPEC_coefficients = [[1.244947090, 0, 0, -0.006455026, 0.000026455, 0], [1.244947090, 0, 0, -0.006455026, 0.000026455, 0]]
                curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0]]
                curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0]]
             
            end

        elsif num_speeds == 4
            curves.HEAT_CAP_FT_SPEC_coefficients = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                                                    [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                                                    [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                                                    [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
            curves.HEAT_EIR_FT_SPEC_coefficients = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                                                    [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                                                    [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                                                    [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
            
        elsif num_speeds == Constants.Num_Speeds_MSHP
            # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
            curves.HEAT_CAP_FT_SPEC_coefficients = [[1.1527124655908571, -0.010386676170938, 0.0, 0.011263752411403, -0.000392549621117, 0.0]] * num_speeds            
            curves.HEAT_EIR_FT_SPEC_coefficients = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * num_speeds
            
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
        end
    end
    return curves
    end  
  
    def self._processCurvesSupplyFan(model)
      const_biquadratic = OpenStudio::Model::CurveBiquadratic.new(model)
      const_biquadratic.setName("ConstantBiquadratic")
      const_biquadratic.setCoefficient1Constant(1)
      const_biquadratic.setCoefficient2x(0)
      const_biquadratic.setCoefficient3xPOW2(0)
      const_biquadratic.setCoefficient4y(0)
      const_biquadratic.setCoefficient5yPOW2(0)
      const_biquadratic.setCoefficient6xTIMESY(0)
      const_biquadratic.setMinimumValueofx(-100)
      const_biquadratic.setMaximumValueofx(100)
      const_biquadratic.setMinimumValueofy(-100)
      const_biquadratic.setMaximumValueofy(100)   
      return const_biquadratic
    end
  
    def self._processCurvesDXCooling(model, supply, outputCapacity)

      const_biquadratic = HVAC._processCurvesSupplyFan(model)
    
      clg_coil_stage_data = []
      (0...supply.Number_Speeds).to_a.each do |speed|
        # Cooling Capacity f(T). Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.COOL_CAP_FT_SPEC_coefficients[speed]
        else
          c = supply.COOL_CAP_FT_SPEC_coefficients
        end
        cool_Cap_fT_coeff = Array.new
        cool_Cap_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        cool_Cap_fT_coeff << 9.0 / 5.0 * c[1] + 576.0 / 5.0 * c[2] + 288.0 / 5.0 * c[5]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[2]
        cool_Cap_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[4]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[5]

        cool_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_cap_ft.setName("Cool-Cap-fT#{speed + 1}")
        else
          cool_cap_ft.setName("Cool-Cap-fT")
        end
        cool_cap_ft.setCoefficient1Constant(cool_Cap_fT_coeff[0])
        cool_cap_ft.setCoefficient2x(cool_Cap_fT_coeff[1])
        cool_cap_ft.setCoefficient3xPOW2(cool_Cap_fT_coeff[2])
        cool_cap_ft.setCoefficient4y(cool_Cap_fT_coeff[3])
        cool_cap_ft.setCoefficient5yPOW2(cool_Cap_fT_coeff[4])
        cool_cap_ft.setCoefficient6xTIMESY(cool_Cap_fT_coeff[5])
        cool_cap_ft.setMinimumValueofx(13.88)
        cool_cap_ft.setMaximumValueofx(23.88)
        cool_cap_ft.setMinimumValueofy(18.33)
        cool_cap_ft.setMaximumValueofy(51.66)

        # Cooling EIR f(T) Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.COOL_EIR_FT_SPEC_coefficients[speed]
        else
          c = supply.COOL_EIR_FT_SPEC_coefficients
        end
        cool_EIR_fT_coeff = Array.new
        cool_EIR_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        cool_EIR_fT_coeff << 9.0 / 5 * c[1] + 576.0 / 5 * c[2] + 288.0 / 5.0 * c[5]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[2]
        cool_EIR_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[4]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[5]

        cool_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_eir_ft.setName("Cool-EIR-fT#{speed + 1}")
        else
          cool_eir_ft.setName("Cool-EIR-fT")
        end
        cool_eir_ft.setCoefficient1Constant(cool_EIR_fT_coeff[0])
        cool_eir_ft.setCoefficient2x(cool_EIR_fT_coeff[1])
        cool_eir_ft.setCoefficient3xPOW2(cool_EIR_fT_coeff[2])
        cool_eir_ft.setCoefficient4y(cool_EIR_fT_coeff[3])
        cool_eir_ft.setCoefficient5yPOW2(cool_EIR_fT_coeff[4])
        cool_eir_ft.setCoefficient6xTIMESY(cool_EIR_fT_coeff[5])
        cool_eir_ft.setMinimumValueofx(13.88)
        cool_eir_ft.setMaximumValueofx(23.88)
        cool_eir_ft.setMinimumValueofy(18.33)
        cool_eir_ft.setMaximumValueofy(51.66)

        # Cooling PLF f(PLR) Convert DOE-2 curves to E+ curves
        cool_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_plf_fplr.setName("Cool-PLF-fPLR#{speed + 1}")
        else
          cool_plf_fplr.setName("Cool-PLF-fPLR")
        end
        cool_plf_fplr.setCoefficient1Constant(supply.COOL_CLOSS_FPLR_SPEC_coefficients[0])
        cool_plf_fplr.setCoefficient2x(supply.COOL_CLOSS_FPLR_SPEC_coefficients[1])
        cool_plf_fplr.setCoefficient3xPOW2(supply.COOL_CLOSS_FPLR_SPEC_coefficients[2])
        cool_plf_fplr.setMinimumValueofx(0.0)
        cool_plf_fplr.setMaximumValueofx(1.0)
        cool_plf_fplr.setMinimumCurveOutput(0.7)
        cool_plf_fplr.setMaximumCurveOutput(1.0)

        # Cooling CAP f(FF) Convert DOE-2 curves to E+ curves
        cool_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_cap_fff.setName("Cool-Cap-fFF#{speed + 1}")
          cool_cap_fff.setCoefficient1Constant(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][0])
          cool_cap_fff.setCoefficient2x(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][1])
          cool_cap_fff.setCoefficient3xPOW2(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][2])
        else
          cool_cap_fff.setName("Cool-CAP-fFF")
          cool_cap_fff.setCoefficient1Constant(supply.COOL_CAP_FFLOW_SPEC_coefficients[0])
          cool_cap_fff.setCoefficient2x(supply.COOL_CAP_FFLOW_SPEC_coefficients[1])
          cool_cap_fff.setCoefficient3xPOW2(supply.COOL_CAP_FFLOW_SPEC_coefficients[2])
        end
        cool_cap_fff.setMinimumValueofx(0.0)
        cool_cap_fff.setMaximumValueofx(2.0)
        cool_cap_fff.setMinimumCurveOutput(0.0)
        cool_cap_fff.setMaximumCurveOutput(2.0)

        # Cooling EIR f(FF) Convert DOE-2 curves to E+ curves
        cool_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_eir_fff.setName("Cool-EIR-fFF#{speed + 1}")
          cool_eir_fff.setCoefficient1Constant(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][0])
          cool_eir_fff.setCoefficient2x(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][1])
          cool_eir_fff.setCoefficient3xPOW2(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][2])
        else
          cool_eir_fff.setName("Cool-EIR-fFF")
          cool_eir_fff.setCoefficient1Constant(supply.COOL_EIR_FFLOW_SPEC_coefficients[0])
          cool_eir_fff.setCoefficient2x(supply.COOL_EIR_FFLOW_SPEC_coefficients[1])
          cool_eir_fff.setCoefficient3xPOW2(supply.COOL_EIR_FFLOW_SPEC_coefficients[2])
        end
        cool_eir_fff.setMinimumValueofx(0.0)
        cool_eir_fff.setMaximumValueofx(2.0)
        cool_eir_fff.setMinimumCurveOutput(0.0)
        cool_eir_fff.setMaximumCurveOutput(2.0)

        stage_data = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, cool_cap_ft, cool_cap_fff, cool_eir_ft, cool_eir_fff, cool_plf_fplr, const_biquadratic)
        if outputCapacity != "Autosize"
          stage_data.setGrossRatedTotalCoolingCapacity(outputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[speed])
          stage_data.setRatedAirFlowRate(supply.CFM_TON_Rated[speed] * outputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * supply.Capacity_Ratio_Cooling[speed]) 
        end      
        stage_data.setGrossRatedSensibleHeatRatio(supply.SHR_Rated[speed])
        stage_data.setGrossRatedCoolingCOP(1.0 / supply.CoolingEIR[speed])
        stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage_data.setMaximumCyclingRate(3)
        stage_data.setLatentCapacityTimeConstant(45)
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        clg_coil_stage_data[speed] = stage_data
      end
      return clg_coil_stage_data
    end
      
    def self._processCurvesDXHeating(model, supply, outputCapacity)
    
      const_biquadratic = HVAC._processCurvesSupplyFan(model)
    
      htg_coil_stage_data = []
      # Loop through speeds to create curves for each speed
      (0...supply.Number_Speeds).to_a.each do |speed|
        # Heating Capacity f(T). Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.HEAT_CAP_FT_SPEC_coefficients[speed]
        else
          c = supply.HEAT_CAP_FT_SPEC_coefficients
        end
        heat_Cap_fT_coeff = Array.new
        heat_Cap_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        heat_Cap_fT_coeff << 9.0 / 5.0 * c[1] + 576.0 / 5.0 * c[2] + 288.0 / 5.0 * c[5]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[2]
        heat_Cap_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[4]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[5]

        hp_heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_cap_ft.setName("HP_Heat-Cap-fT#{speed + 1}")
        else
          hp_heat_cap_ft.setName("HP_Heat-Cap-fT")
        end
        hp_heat_cap_ft.setCoefficient1Constant(heat_Cap_fT_coeff[0])
        hp_heat_cap_ft.setCoefficient2x(heat_Cap_fT_coeff[1])
        hp_heat_cap_ft.setCoefficient3xPOW2(heat_Cap_fT_coeff[2])
        hp_heat_cap_ft.setCoefficient4y(heat_Cap_fT_coeff[3])
        hp_heat_cap_ft.setCoefficient5yPOW2(heat_Cap_fT_coeff[4])
        hp_heat_cap_ft.setCoefficient6xTIMESY(heat_Cap_fT_coeff[5])
        hp_heat_cap_ft.setMinimumValueofx(-100)
        hp_heat_cap_ft.setMaximumValueofx(100)
        hp_heat_cap_ft.setMinimumValueofy(-100)
        hp_heat_cap_ft.setMaximumValueofy(100)

        # Heating EIR f(T) Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.HEAT_EIR_FT_SPEC_coefficients[speed]
        else
          c = supply.HEAT_EIR_FT_SPEC_coefficients
        end
        hp_heat_EIR_fT_coeff = Array.new
        hp_heat_EIR_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        hp_heat_EIR_fT_coeff << 9.0 / 5 * c[1] + 576.0 / 5 * c[2] + 288.0 / 5.0 * c[5]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[2]
        hp_heat_EIR_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[4]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[5]

        hp_heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_eir_ft.setName("HP_Heat-EIR-fT#{speed + 1}")
        else
          hp_heat_eir_ft.setName("HP_Heat-EIR-fT")
        end
        hp_heat_eir_ft.setCoefficient1Constant(hp_heat_EIR_fT_coeff[0])
        hp_heat_eir_ft.setCoefficient2x(hp_heat_EIR_fT_coeff[1])
        hp_heat_eir_ft.setCoefficient3xPOW2(hp_heat_EIR_fT_coeff[2])
        hp_heat_eir_ft.setCoefficient4y(hp_heat_EIR_fT_coeff[3])
        hp_heat_eir_ft.setCoefficient5yPOW2(hp_heat_EIR_fT_coeff[4])
        hp_heat_eir_ft.setCoefficient6xTIMESY(hp_heat_EIR_fT_coeff[5])
        hp_heat_eir_ft.setMinimumValueofx(-100)
        hp_heat_eir_ft.setMaximumValueofx(100)
        hp_heat_eir_ft.setMinimumValueofy(-100)
        hp_heat_eir_ft.setMaximumValueofy(100)

        hp_heat_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_plf_fplr.setName("HP_Heat-PLF-fPLR#{speed + 1}")
        else
          hp_heat_plf_fplr.setName("HP_Heat-PLF-fPLR")
        end
        hp_heat_plf_fplr.setCoefficient1Constant(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[0])
        hp_heat_plf_fplr.setCoefficient2x(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[1])
        hp_heat_plf_fplr.setCoefficient3xPOW2(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[2])
        hp_heat_plf_fplr.setMinimumValueofx(-100)
        hp_heat_plf_fplr.setMaximumValueofx(100)
        hp_heat_plf_fplr.setMinimumCurveOutput(-100)
        hp_heat_plf_fplr.setMaximumCurveOutput(100)

        # Heating CAP f(FF) Convert DOE-2 curves to E+ curves
        hp_heat_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_cap_fff.setName("HP_Heat-Cap-fFF#{speed + 1}")
          hp_heat_cap_fff.setCoefficient1Constant(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][0])
          hp_heat_cap_fff.setCoefficient2x(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][1])
          hp_heat_cap_fff.setCoefficient3xPOW2(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][2])
        else
          hp_heat_cap_fff.setName("HP_Heat-CAP-fFF")
          hp_heat_cap_fff.setCoefficient1Constant(supply.HEAT_CAP_FFLOW_SPEC_coefficients[0])
          hp_heat_cap_fff.setCoefficient2x(supply.HEAT_CAP_FFLOW_SPEC_coefficients[1])
          hp_heat_cap_fff.setCoefficient3xPOW2(supply.HEAT_CAP_FFLOW_SPEC_coefficients[2])
        end
        hp_heat_cap_fff.setMinimumValueofx(0.0)
        hp_heat_cap_fff.setMaximumValueofx(2.0)
        hp_heat_cap_fff.setMinimumCurveOutput(0.0)
        hp_heat_cap_fff.setMaximumCurveOutput(2.0)

        # Heating EIR f(FF) Convert DOE-2 curves to E+ curves
        hp_heat_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_eir_fff.setName("HP_Heat-EIR-fFF#{speed + 1}")
          hp_heat_eir_fff.setCoefficient1Constant(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][0])
          hp_heat_eir_fff.setCoefficient2x(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][1])
          hp_heat_eir_fff.setCoefficient3xPOW2(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][2])
        else
          hp_heat_eir_fff.setName("HP_Heat-EIR-fFF")
          hp_heat_eir_fff.setCoefficient1Constant(supply.HEAT_EIR_FFLOW_SPEC_coefficients[0])
          hp_heat_eir_fff.setCoefficient2x(supply.HEAT_EIR_FFLOW_SPEC_coefficients[1])
          hp_heat_eir_fff.setCoefficient3xPOW2(supply.HEAT_EIR_FFLOW_SPEC_coefficients[2])
        end
        hp_heat_eir_fff.setMinimumValueofx(0.0)
        hp_heat_eir_fff.setMaximumValueofx(2.0)
        hp_heat_eir_fff.setMinimumCurveOutput(0.0)
        hp_heat_eir_fff.setMaximumCurveOutput(2.0)

        stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, hp_heat_cap_ft, hp_heat_cap_fff, hp_heat_eir_ft, hp_heat_eir_fff, hp_heat_plf_fplr, const_biquadratic)
        if outputCapacity != "Autosize"
          stage_data.setGrossRatedHeatingCapacity(outputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * supply.Capacity_Ratio_Heating[speed])
          stage_data.setRatedAirFlowRate(supply.CFM_TON_Rated_Heat[speed] * outputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * supply.Capacity_Ratio_Heating[speed]) 
        end   
        stage_data.setGrossRatedHeatingCOP(1.0 / supply.HeatingEIR[speed])
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil_stage_data[speed] = stage_data
      end
      return htg_coil_stage_data
    end
  
    def self.is_cold_climate_hp(num_speeds, min_compressor_temp)
        if num_speeds == 2.0 and min_compressor_temp == -99.9
            return true
        else
            return false
        end
    end
  
    def self._processAirSystemCoolingCoil(number_Speeds, coolingEER, coolingSEER, supplyFanPower, supplyFanPower_Rated, shr_Rated, capacity_Ratio, fanspeed_Ratio, condenserType, crankcase, crankcase_MaxT, eer_CapacityDerateFactor, air_conditioner, supply, hasHeatPump)

    # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
    #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

    # Curves are hardcoded for both one and two speed models
    supply.Number_Speeds = number_Speeds

    if air_conditioner.hasIdealAC
      supply = HVAC.get_cooling_coefficients(supply.Number_Speeds, true, nil, supply)
    end

    supply.CoolingEIR = Array.new
    supply.SHR_Rated = Array.new
    (0...supply.Number_Speeds).to_a.each do |speed|

      if air_conditioner.hasIdealAC
        eir = calc_EIR_from_COP(1.0, supplyFanPower_Rated)
        supply.CoolingEIR << eir

        shr_Rated = 0.8
        supply.SHR_Rated << shr_Rated
        supply.SHR_Rated[speed] = shr_Rated
        supply.FAN_EIR_FPLR_SPEC_coefficients = [1.00000000, 0.00000000, 0.00000000, 0.00000000]

      else
        eir = calc_EIR_from_EER(coolingEER[speed], supplyFanPower_Rated)
        supply.CoolingEIR << eir

        # Convert SHRs from net to gross
        qtot_net_nominal = 12000.0
        qsens_net_nominal = qtot_net_nominal * shr_Rated[speed]
        qtot_gross_nominal = qtot_net_nominal + OpenStudio::convert(supply.CFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
        qsens_gross_nominal = qsens_net_nominal + OpenStudio::convert(supply.CFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
        supply.SHR_Rated << (qsens_gross_nominal / qtot_gross_nominal)

        # Make sure SHR's are in valid range based on E+ model limits.
        # The following correlation was devloped by Jon Winkler to test for maximum allowed SHR based on the 300 - 450 cfm/ton limits in E+
        maxSHR = 0.3821066 + 0.001050652 * supply.CFM_TON_Rated[speed] - 0.01
        supply.SHR_Rated[speed] = [supply.SHR_Rated[speed], maxSHR].min
        minSHR = 0.60   # Approximate minimum SHR such that an ADP exists
        supply.SHR_Rated[speed] = [supply.SHR_Rated[speed], minSHR].max
      end
    end

    if supply.Number_Speeds == 1.0
        c_d = HVAC.calc_Cd_from_SEER_EER_SingleSpeed(coolingSEER, coolingEER[0],supplyFanPower_Rated, hasHeatPump, supply)
    elsif supply.Number_Speeds == 2.0
        c_d = HVAC.calc_Cd_from_SEER_EER_TwoSpeed(coolingSEER, coolingEER, capacity_Ratio, fanspeed_Ratio, supplyFanPower_Rated, hasHeatPump)
    elsif supply.Number_Speeds == 4.0
        c_d = HVAC.calc_Cd_from_SEER_EER_FourSpeed(coolingSEER, coolingEER, capacity_Ratio, fanspeed_Ratio, supplyFanPower_Rated, hasHeatPump)

    else
        runner.registerError("AC number of speeds must equal 1, 2, or 4.")
        return false
    end

    if air_conditioner.hasIdealAC
      supply.COOL_CLOSS_FPLR_SPEC_coefficients = [1.0, 0.0, 0.0]
    else
      supply.COOL_CLOSS_FPLR_SPEC_coefficients = [(1.0 - c_d), c_d, 0.0]    # Linear part load model
    end

    supply.Capacity_Ratio_Cooling = capacity_Ratio
    supply.fanspeed_ratio = fanspeed_Ratio
    supply.CondenserType = condenserType
    supply.Crankcase = crankcase
    supply.Crankcase_MaxT = crankcase_MaxT

    # Supply Fan
    supply.fan_power = supplyFanPower
    supply.fan_power_rated = supplyFanPower_Rated
    supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
    supply.min_flow_ratio = fanspeed_Ratio[0] / fanspeed_Ratio[-1]

    supply.EER_CapacityDerateFactor = eer_CapacityDerateFactor

    return supply

    end

    def self._processAirSystemHeatingCoil(heatingCOP, heatingHSPF, supplyFanPower_Rated, capacity_Ratio, fanspeed_Ratio_Heating, min_T, cop_CapacityDerateFactor, supply)

    # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
    #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

    supply.HeatingEIR = Array.new
    (0...supply.Number_Speeds).to_a.each do |speed|
      eir = calc_EIR_from_COP(heatingCOP[speed], supplyFanPower_Rated)
      supply.HeatingEIR << eir
    end

    if supply.Number_Speeds == 1.0
      c_d = HVAC.calc_Cd_from_HSPF_COP_SingleSpeed(heatingHSPF, heatingCOP[0], supplyFanPower_Rated)
    elsif supply.Number_Speeds == 2.0
      c_d = HVAC.calc_Cd_from_HSPF_COP_TwoSpeed(heatingHSPF, heatingCOP, capacity_Ratio, fanspeed_Ratio_Heating, supplyFanPower_Rated)
    elsif supply.Number_Speeds == 4.0
      c_d = HVAC.calc_Cd_from_HSPF_COP_FourSpeed(heatingHSPF, heatingCOP, capacity_Ratio, fanspeed_Ratio_Heating, supplyFanPower_Rated)
    else
      runner.registerError("HP number of speeds must equal 1, 2, or 4.")
      return false
    end

    supply.HEAT_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0] # Linear part load model

    supply.Capacity_Ratio_Heating = capacity_Ratio
    supply.fanspeed_ratio_heating = fanspeed_Ratio_Heating
    supply.max_temp = 105.0             # Hardcoded due to all heat pumps options having this value. Also effects the sizing so it shouldn't be a user variable
    supply.min_hp_temp = min_T          # Minimum temperature for Heat Pump operation
    supply.supp_htg_max_outdoor_temp = 40.0 # Moved from DOE-2. DOE-2 Default
    supply.max_defrost_temp = 40.0      # Moved from DOE-2. DOE-2 Default

    # Supply Air Tempteratures
    supply.htg_supply_air_temp = 105.0 # used for sizing heating flow rate
    supply.supp_htg_max_supply_temp = 170.0 # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.    
    
    supply.COP_CapacityDerateFactor = cop_CapacityDerateFactor

    return supply

    end  
  
    def self.calc_Cd_from_SEER_EER_SingleSpeed(seer, eer_A, supplyFanPower_Rated, isHeatPump, supply)

      # Use hard-coded Cd values
      if seer < 13.0
        return 0.20
      else
        return 0.07
      end


      # eir_A = calc_EIR_from_EER(eer_A, supplyFanPower_Rated)
      #
      # # supply = SuperDict()
      # supply = get_cooling_coefficients(1.0, false, isHeatPump, supply)
      #
      # eir_B = eir_A * MathTools.biquadratic(67, 82, supply.COOL_EIR_FT_SPEC_coefficients) # tk ?
      # eer_B = calc_EER_from_EIR(eir_B, supplyFanPower_Rated)
      #
      # c_d = (seer / eer_B - 1.0) / (-0.5)
      #
      # if c_d < 0.0
      #   c_d = 0.02
      # elsif c_d > 0.25
      #   c_d = 0.25
      # end
      #
      # return c_d
    end

    def self.calc_Cd_from_SEER_EER_TwoSpeed(seer, eer_A, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)

      # Use hard-coded Cd values
      return 0.11


      # c_d = 0.1
      # c_d_1 = c_d
      # c_d_2 = c_d
      #
      # error = seer - calc_SEER_TwoSpeed(eer_A, c_d, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)
      # error1 = error
      # error2 = error
      #
      # itmax = 50  # maximum iterations
      # cvg = false
      #
      # (1...(itmax+1)).each do |n|
      #
      #   error = eer - calc_SEER_TwoSpeed(eer_A, c_d, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)
      #
      #   c_d, cvg, c_d_1, error1, c_d_2, error2 = MathTools.Iterate(c_d, error, c_d_1, error1, c_d_2, error2, n, cvg)
      #
      #   if cvg == true
      #     break
      #   end
      #
      # end
      #
      # if cvg == false
      #   c_d = 0.25
      #   runner.registerWarning("Two-speed cooling C_d iteration failed to converge. Setting to maximum value.")
      # end
      #
      # if c_d < 0.0
      #   c_d = 0.02
      # elsif c_d > 0.25
      #   c_d = 0.25
      # end
      #
      # return c_d
    end

    def self.calc_Cd_from_SEER_EER_FourSpeed(seer, eer_A, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)

      # Use hard-coded Cd values
      return 0.25

    #   l_EER_A = list(EER_A)
    #   l_CapacityRatio = list(CapacityRatio)
    #   l_FanSpeedRatio = list(FanSpeedRatio)
    #
    # # first need to find the nominal capacity
    #   if 1 in l_CapacityRatio:
    #       nomIndex = l_CapacityRatio.index(1)
    #
    #   if nomIndex <= 1:
    #       SimError('Invalid CapacityRatio array passed to calc_Cd_from_SEER_EER_FourSpeed. Must contain more than 2 elements.')
    #   elif nomIndex == 2:
    #       del l_EER_A[3]
    #   del l_CapacityRatio[3]
    #   del l_FanSpeedRatio[3]
    #   elif nomIndex == 3:
    #       l_EER_A[2] = (l_EER_A[1] + l_EER_A[2]) / 2
    #   l_CapacityRatio[2] = (l_CapacityRatio[1] + l_CapacityRatio[2]) / 2
    #   l_FanSpeedRatio[2] = (l_FanSpeedRatio[1] + l_FanSpeedRatio[2]) / 2
    #   del l_EER_A[1]
    #   del l_CapacityRatio[1]
    #   del l_FanSpeedRatio[1]
    #   else:
    #       SimError('Invalid CapacityRatio array passed to calc_Cd_from_SEER_EER_FourSpeed. Must contain value of 1.')
    #
    #   C_d = 0.25
    #   C_d_1 = C_d
    #   C_d_2 = C_d
    #
    # # Note: calc_SEER_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
    #   error = SEER - calc_SEER_VariableSpeed(l_EER_A, C_d, l_CapacityRatio, l_FanSpeedRatio, nomIndex,
    #                                          SupplyFanPower_Rated, isHeatPump)
    #
    #   error1 = error
    #   error2 = error
    #
    #   itmax = 50  # maximum iterations
    #   cvg = False
    #
    #   for n in range(1,itmax+1):
    #
    #     # Note: calc_SEER_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
    #     error = SEER - calc_SEER_VariableSpeed(l_EER_A, C_d, l_CapacityRatio, l_FanSpeedRatio, nomIndex,
    #                                            SupplyFanPower_Rated, isHeatPump)
    #
    #     C_d,cvg,C_d_1,error1,C_d_2,error2 = \
    #                 MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
    #
    #     if cvg == True: break
    #
    #     if cvg == False:
    #         C_d = 0.25
    #     SimWarning('Variable-speed cooling C_d iteration failed to converge. Setting to maximum value.')
    #
    #     if C_d < 0:
    #         C_d = 0.02
    #     elif C_d > 0.25:
    #         C_d = 0.25
    #
    #     return C_d
    end

    def self.calc_Cd_from_HSPF_COP_SingleSpeed(hspf, cop_47, supplyFanPower_Rated)

      # Use hard-coded Cd values
      if hspf < 7.0
          return 0.20
      else
          return 0.11
      end

      # C_d = 0.1
      # C_d_1 = C_d
      # C_d_2 = C_d
      #
      # error = HSPF - calc_HSPF_SingleSpeed(COP_47, C_d, SupplyFanPower_Rated)
      # error1 = error
      # error2 = error
      #
      # itmax = 50  # maximum iterations
      # cvg = False
      #
      # for n in range(1,itmax+1):
      #
      #   error = HSPF - calc_HSPF_SingleSpeed(COP_47, C_d, SupplyFanPower_Rated)
      #
      #   C_d,cvg,C_d_1,error1,C_d_2,error2 = \
      #               MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
      #
      #   if cvg == True: break
      #
      #   if cvg == False:
      #       C_d = 0.25
      #   SimWarning('Single-speed heating C_d iteration failed to converge. Setting to maximum value.')
      #
      #   if C_d < 0:
      #       C_d = 0.02
      #   elif C_d > 0.25:
      #       C_d = 0.25
      #
      #   return C_d

    end

    def self.calc_Cd_from_HSPF_COP_TwoSpeed(hspf, cop_47, capacityRatio, fanSpeedRatio, supplyFanPower_Rated)

      # Use hard-coded Cd values
      return 0.11

      # C_d = 0.1
      # C_d_1 = C_d
      # C_d_2 = C_d
      #
      # error = HSPF - calc_HSPF_TwoSpeed(COP_47, C_d, CapacityRatio, FanSpeedRatio,
      #                                   SupplyFanPower_Rated)
      # error1 = error
      # error2 = error
      #
      # itmax = 50  # maximum iterations
      # cvg = False
      #
      # for n in range(1,itmax+1):
      #
      #   error = HSPF - calc_HSPF_TwoSpeed(COP_47, C_d, CapacityRatio, FanSpeedRatio,
      #                                     SupplyFanPower_Rated)
      #
      #   C_d,cvg,C_d_1,error1,C_d_2,error2 = \
      #               MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
      #
      #   if cvg == True: break
      #
      #   if cvg == False:
      #       C_d = 0.25
      #   SimWarning('Two-speed heating C_d iteration failed to converge. Setting to maximum value.')
      #
      #   if C_d < 0:
      #       C_d = 0.02
      #   elif C_d > 0.25:
      #       C_d = 0.25
      #
      #   return C_d

    end

    def self.calc_Cd_from_HSPF_COP_FourSpeed(hspf, cop_47, capacityRatio, fanSpeedRatio, supplyFanPower_Rated)

      # Use hard-coded Cd values
      return 0.24

      # l_COP_47 = list(COP_47)
      # l_CapacityRatio = list(CapacityRatio)
      # l_FanSpeedRatio = list(FanSpeedRatio)
      #
      # # first need to find the nominal capacity
      # if 1 in l_CapacityRatio:
      #     nomIndex = l_CapacityRatio.index(1)
      #
      # if nomIndex <= 1:
      #     SimError('Invalid CapacityRatio array passed to calc_Cd_from_HSPF_COP_FourSpeed. Must contain more than 2 elements.')
      # elif nomIndex == 2:
      #     del l_COP_47[3]
      # del l_CapacityRatio[3]
      # del l_FanSpeedRatio[3]
      # elif nomIndex == 3:
      #     l_COP_47[2] = (l_COP_47[1] + l_COP_47[2]) / 2
      # l_CapacityRatio[2] = (l_CapacityRatio[1] + l_CapacityRatio[2]) / 2
      # l_FanSpeedRatio[2] = (l_FanSpeedRatio[1] + l_FanSpeedRatio[2]) / 2
      # del l_COP_47[1]
      # del l_CapacityRatio[1]
      # del l_FanSpeedRatio[1]
      # else:
      #     SimError('Invalid CapacityRatio array passed to calc_Cd_from_HSPF_COP_FourSpeed. Must contain value of 1.')
      #
      # C_d = 0.25
      # C_d_1 = C_d
      # C_d_2 = C_d
      #
      # # Note: calc_HSPF_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
      # error = HSPF - calc_HSPF_VariableSpeed(l_COP_47, C_d, l_CapacityRatio,
      #                                        l_FanSpeedRatio, nomIndex,
      #                                        SupplyFanPower_Rated)
      # error1 = error
      # error2 = error
      #
      # itmax = 50  # maximum iterations
      # cvg = False
      #
      # for n in range(1,itmax+1):
      #
      #   # Note: calc_HSPF_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
      #   error = HSPF - calc_HSPF_VariableSpeed(l_COP_47, C_d, l_CapacityRatio,
      #                                          l_FanSpeedRatio, nomIndex,
      #                                          SupplyFanPower_Rated)
      #
      #   C_d,cvg,C_d_1,error1,C_d_2,error2 = \
      #               MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
      #
      #   if cvg == True: break
      #
      #   if cvg == False:
      #       C_d = 0.25
      #   SimWarning('Variable-speed heating C_d iteration failed to converge. Setting to maximum value.')
      #
      #   if C_d < 0:
      #       C_d = 0.02
      #   elif C_d > 0.25:
      #       C_d = 0.25
      #
      #   return C_d

    end  
  
end

class Material

    def initialize(name=nil, type=nil, thick=nil, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=nil, dens=nil, sh=nil, tAbs=nil, sAbs=nil, vAbs=nil, rvalue=nil)
        @name = name
        @type = type
        
        if !thick.nil?
            @thick = thick
            @thick_in = OpenStudio::convert(@thick,"ft","in").get
        elsif !thick_in.nil?
            @thick_in = thick_in
            @thick = OpenStudio::convert(@thick_in,"in","ft").get
        end
        
        if not width.nil?
            @width = width
            @width_in = OpenStudio::convert(@width,"ft","in").get
        elsif not width_in.nil?
            @width_in = thick_in
            @width = OpenStudio::convert(@width_in,"in","ft").get
        end
        
        if not mat_base.nil?
            @k = mat_base.k
            @rho = mat_base.rho
            @cp = mat_base.Cp
        else
            @k = nil
            @rho = nil
            @cp = nil
        end
        # override the base material if both are included
        if not cond.nil?
            @k = cond
        end
        if not dens.nil?
            @rho = dens
        end
        if not sh.nil?
            @cp = sh
        end
        @tAbs = tAbs
        @sAbs = sAbs
        @vAbs = vAbs
        if not rvalue.nil?
            @rvalue = rvalue
        elsif not @thick.nil? and not @k.nil?
            if @k != 0
                @rvalue = @thick / @k
            end
        end
    end
    
    def thick
        return @thick
    end

    def thick_in
        return @thick_in
    end

    def width
        return @width
    end
    
    def width_in
        return @width_in
    end
    
    def k
        return @k
    end
    
    def rho
        return @rho
    end
    
    def Cp
        return @cp
    end
    
    def Rvalue
        return @rvalue
    end
    
    def TAbs
        return @tAbs
    end
    
    def SAbs
        return @sAbs
    end
    
    def VAbs
        return @vAbs
    end

    def self.CarpetBare(carpetFloorFraction, carpetPadRValue)
        thickness = 0.5 # in
        return Material.new(name=Constants.MaterialCarpetBareLayer, type=Constants.MaterialTypeProperties, thick=nil, thick_in=thickness, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(thickness,"in","ft").get / (carpetPadRValue * carpetFloorFraction), dens=3.4, sh=0.32, tAbs=0.9, sAbs=0.9)
    end

    def self.Concrete8in
        return Material.new(name=Constants.MaterialConcrete8in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=8, width=nil, width_in=nil, mat_base=BaseMaterial.Concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
    end

    def self.Concrete4in
        return Material.new(name=Constants.MaterialConcrete8in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=4, width=nil, width_in=nil, mat_base=BaseMaterial.Concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
    end

    def self.Gypsum1_2in
        return Material.new(name=Constants.MaterialGypsumBoard1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.GypsumExtWall
        return Material.new(name=Constants.MaterialGypsumBoard1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.GypsumCeiling
        return Material.new(name=Constants.MaterialGypsumBoard1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsCeiling, vAbs=0.1)
    end

    def self.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
        return Material.new(name=Constants.MaterialFloorMass, type=Constants.MaterialTypeProperties, thick=nil, thick_in=floorMassThickness, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(floorMassConductivity,"in","ft").get, dens=floorMassDensity, sh=floorMassSpecificHeat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsFloor)
    end

    def self.MassPartitionWall(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat)
        return Material.new(name=Constants.MaterialPartitionWallMass, type=Constants.MaterialTypeProperties, thick=nil, thick_in=partitionWallMassThickness, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(partitionWallMassConductivity,"in","ft").get, dens=partitionWallMassDensity, sh=partitionWallMassSpecHeat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.Soil12in
        return Material.new(name=Constants.MaterialSoil12in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=12, width=nil, width_in=nil, mat_base=BaseMaterial.Soil)
    end

    def self.Stud2x(thickness)
        return Material.new(name=Constants.Material2x, type=Constants.MaterialTypeProperties, thick=nil, thick_in=thickness, width=nil, width_in=1.5, mat_base=BaseMaterial.Wood)
    end
    
    def self.Stud2x4
        return Material.new(name=Constants.Material2x4, type=Constants.MaterialTypeProperties, thick=nil, thick_in=3.5, width=nil, width_in=1.5, mat_base=BaseMaterial.Wood)
    end

    def self.Stud2x6
        return Material.new(name=Constants.Material2x6, type=Constants.MaterialTypeProperties, thick=nil, thick_in=5.5, width=nil, width_in=1.5, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood1_2in
        return Material.new(name=Constants.MaterialPlywood1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood3_4in
        return Material.new(name=Constants.MaterialPlywood3_4in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.75, width=nil, width_in=nil, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood3_2in
        return Material.new(name=Constants.MaterialPlywood3_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=1.5, width=nil, width_in=nil, mat_base=BaseMaterial.Wood)
    end

    def self.RadiantBarrier
        return Material.new(name=Constants.MaterialRadiantBarrier, type=Constants.MaterialTypeProperties, thick=0.0007, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=135.8, dens=168.6, sh=0.22, tAbs=0.05, sAbs=0.05, vAbs=0.05)
    end

    def self.RoofMaterial(roofMatEmissivity, roofMatAbsorptivity)
        return Material.new(name=Constants.MaterialRoofingMaterial, type=Constants.MaterialTypeProperties, thick=0.031, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=0.094, dens=70, sh=0.35, tAbs=roofMatEmissivity, sAbs=roofMatAbsorptivity, vAbs=roofMatAbsorptivity)
    end

    def self.StudAndAir
        mat_2x4 = Material.Stud2x4
        u_stud_path = Constants.DefaultFramingFactorInterior / Material.Stud2x4.Rvalue
        u_air_path = (1 - Constants.DefaultFramingFactorInterior) / Gas.AirGapRvalue
        stud_and_air_Rvalue = 1 / (u_stud_path + u_air_path)
        mat_stud_and_air_wall = BaseMaterial.new(rho=(mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.Cp, cp=((mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.Cp * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.Cp * Gas.Air.Cp) / ((mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.Cp), k=(mat_2x4.thick / stud_and_air_Rvalue))
        return Material.new(name=Constants.MaterialStudandAirWall, type=Constants.MaterialTypeProperties, thick=mat_2x4.thick, thick_in=nil, width=nil, width_in=nil, mat_base=mat_stud_and_air_wall)
    end

end

class Construction

    def initialize(path_widths, name=nil, type=nil)
        @name = name
        @type = type
        @path_widths = path_widths
        @path_fracs = []
        path_widths.each do |path_width|
            @path_fracs << path_width / path_widths.inject{ |sum, n| sum + n }
        end     
        @layer_thicknesses = []
        @cond_matrix = []
        @matrix = []
    end
    
    def addlayer(thickness=nil, conductivity_list=nil, material=nil, material_list=nil)
        # Adds layer to the construction using a material name or a thickness and list of conductivities.
        if material
            thickness = material.thick
            conductivity_list = [material.k]
        end     
        begin
            if thickness and thickness > 0
                @layer_thicknesses << thickness

                if @layer_thicknesses.length == 1
                    # First layer

                    if conductivity_list.length == 1
                        # continuous layer
                        single_conductivity = conductivity_list[0] #strangely, this is necessary
                        (0...@path_fracs.length).to_a.each do |i|
                            @cond_matrix << [single_conductivity]
                        end                     
                    else
                        # layer has multiple materials
                        (0...@path_fracs.length).to_a.each do |i|
                            @cond_matrix << [conductivity_list[i]]
                        end
                    end
                else
                    # not first layer
                    if conductivity_list.length == 1
                        # continuous layer
                        (0...@path_fracs.length).to_a.each do |i|
                            @cond_matrix[i] << conductivity_list[0]
                        end
                    else
                        # layer has multiple materials
                        (0...@path_fracs.length).to_a.each do |i|
                            @cond_matrix[i] << conductivity_list[i]
                        end
                    end
                end
                
            end
        rescue
            runner.registerError("Wrong number of conductivity values specified (#{conductivity_list.length} specified); should be one if a continuous layer, or one per path for non-continuous layers (#{@path_fracs.length} paths).")    
            return false
        end
        
    end
        
    def Rvalue_parallel
        # This generic function calculates the total r-value of a wall/roof/floor assembly using parallel paths (R_2D = infinity).
         # layer_thicknesses = [0.5, 5.5, 0.5] # layer thicknesses
         # path_widths = [22.5, 1.5]     # path widths

        # gwb  =  Material(cond=0.17 *0.5779)
        # stud =  Material(cond=0.12 *0.5779)
        # osb  =  Material(cond=0.13 *0.5779)
        # ins  =  Material(cond=0.04 *0.5779)

        # cond_matrix = [[gwb.k, stud.k, osb.k],
                       # [gwb.k, ins.k, osb.k]]
        u_overall = 0
        @path_fracs.each_with_index do |path_frac,path_num|
            # For each parallel path, sum series:
            r_path = 0
            @layer_thicknesses.each_with_index do |layer_thickness,layer_num|
                r_path += layer_thickness / @cond_matrix[path_num][layer_num]
            end
                
            u_overall += 1.0 / r_path * path_frac
        
        end

        return 1.0 / u_overall
        
    end 

    def self.GetWallGapFactor(installGrade, framingFactor)

        if installGrade == 1
            return 0
        elsif installGrade == 2
            return 0.02 * (1 - framingFactor)
        elsif installGrade == 3
            return 0.05 * (1 - framingFactor)
        else
            return 0
        end

    end

    def self.GetWoodStudWallAssemblyR(wallCavityInsFillsCavity, wallCavityInsRvalueInstalled, 
                                      wallInstallGrade, wallCavityDepth, wallFramingFactor, 
                                      prefix, gypsumThickness, gypsumNumLayers, finishThickness, 
                                      finishConductivty, rigidInsThickness, rigidInsRvalue, hasOSB)

        if not wallCavityInsRvalueInstalled
            wallCavityInsRvalueInstalled = 0
        end
        if not wallFramingFactor
            wallFramingFactor = 0
        end

        # For foundation walls, only add OSB if there is wall insulation.
        # This is consistent with the NREMDB costs.
        if prefix != "WS" and wallCavityInsRvalueInstalled == 0 and rigidInsRvalue == 0
            hasOSB = false
        end

        mat_wood = BaseMaterial.Wood

        # Add air gap when insulation thickness < cavity depth
        if not wallCavityInsFillsCavity
            wallCavityInsRvalueInstalled += Gas.AirGapRvalue
        end

        gapFactor = Construction.GetWallGapFactor(wallInstallGrade, wallFramingFactor)

        path_fracs = [wallFramingFactor, 1 - wallFramingFactor - gapFactor, gapFactor]
        wood_stud_wall = Construction.new(path_fracs)

        # Interior Film
        wood_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.VerticalR])

        # Interior Finish (GWB) - Currently only include if cavity depth > 0
        if wallCavityDepth > 0
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[BaseMaterial.Gypsum.k])
        end

        # Only if cavity depth > 0, indicating a framed wall
        if wallCavityDepth > 0
            # Stud / Cavity Ins / Gap
            ins_k = OpenStudio::convert(wallCavityDepth,"in","ft").get / wallCavityInsRvalueInstalled
            gap_k = OpenStudio::convert(wallCavityDepth,"in","ft").get / Gas.AirGapRvalue
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(wallCavityDepth,"in","ft").get, conductivity_list=[mat_wood.k,ins_k,gap_k])       
        end

        # OSB sheathing
        if hasOSB
            wood_stud_wall.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood1_2in, material_list=nil)
        end

        # Rigid
        if rigidInsRvalue > 0
            rigid_k = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
        end

        # Exterior Finish
        if finishThickness > 0
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(finishConductivty,"in","ft").get])
            
            # Exterior Film - Assume below-grade wall if FinishThickness = 0
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.OutsideR])
        end

        # Get overall wall R-value using parallel paths:
        return wood_stud_wall.Rvalue_parallel

    end

    def self.GetFloorNonStudLayerR(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, carpetFloorFraction, carpetPadRValue)
        return (2.0 * AirFilms.FloorReducedR + Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat).Rvalue + (carpetPadRValue * carpetFloorFraction) + Material.Plywood3_4in.Rvalue)
    end
    
    def self.GetRimJoistAssmeblyR(rimJoistInsRvalue, ceilingJoistHeight, wallSheathingContInsThickness, wallSheathingContInsRvalue, drywallThickness, drywallNumLayers, rimjoist_framingfactor, finishThickness, finishConductivity)
        # Returns assembly R-value for crawlspace or unfinished/finished basement rimjoist, including air films.
        
        framingFactor = rimjoist_framingfactor
        
        mat_wood = BaseMaterial.Wood
        mat_2x = Material.Stud2x(ceilingJoistHeight)
        
        path_fracs = [framingFactor, 1 - framingFactor]
        
        prefix_rimjoist = Construction.new(path_fracs)
        
        # Interior Film 
        prefix_rimjoist.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.FloorReducedR])

        # Stud/cavity layer
        if rimJoistInsRvalue == 0
            cavity_k = (mat_2x.thick / air.R_air_gap)
        else
            cavity_k = (mat_2x.thick / rimJoistInsRvalue)
        end
            
        prefix_rimjoist.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k])
        
        # Rim Joist wood layer
        prefix_rimjoist.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_2in, material_list=nil)
        
        # Wall Sheathing
        if wallSheathingContInsRvalue > 0
            wallsh_k = (wallSheathingContInsThickness / wallSheathingContInsRvalue)
            prefix_rimjoist.addlayer(thickness=OpenStudio::convert(wallSheathingContInsThickness,"in","ft").get, conductivity_list=[wallsh_k])
        end
        prefix_rimjoist.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[finishConductivity])
        
        # Exterior Film
        prefix_rimjoist.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / AirFilms.FloorReducedR])
        
        return prefix_rimjoist.Rvalue_parallel

    end 
    
    def self.GetRimJoistNonStudLayerR
        return (AirFilms.VerticalR + AirFilms.OutsideR + Material.Plywood3_2in.Rvalue)
    end
    
    def self.GetBasementConductionFactor(bsmtWallInsulationHeight, bsmtWallInsulRvalue)
        if bsmtWallInsulationHeight == 4
            return (1.689 / (0.430 + bsmtWallInsulRvalue) ** 0.164)
        else
            return (2.494 / (1.673 + bsmtWallInsulRvalue) ** 0.488)
        end
    end

    
end

class BaseMaterial
	def initialize(rho, cp, k)
		@rho = rho
		@cp = cp
		@k = k
	end
		
	def rho
		return @rho
	end
	
	def Cp
		return @cp
	end
	
	def k
		return @k
	end

    def self.Gypsum
        return BaseMaterial.new(rho=50.0, cp=0.2, k=0.0926)
    end

    def self.Wood
        return BaseMaterial.new(rho=32.0, cp=0.29, k=0.0667)
    end
    
    def self.Concrete
        return BaseMaterial.new(rho=140.0, cp=0.2, k=0.7576)
    end

    def self.Gypcrete
        # http://www.maxxon.com/gyp-crete/data
        return BaseMaterial.new(rho=100.0, cp=0.223, k=0.3952)
    end

    def self.InsulationRigid
        return BaseMaterial.new(rho=2.0, cp=0.29, k=0.017)
    end
    
    def self.InsulationCelluloseDensepack
        return BaseMaterial.new(rho=3.5, cp=0.25, k=nil)
    end

    def self.InsulationCelluloseLoosefill
        return BaseMaterial.new(rho=1.5, cp=0.25, k=nil)
    end

    def self.InsulationFiberglassDensepack
        return BaseMaterial.new(rho=2.2, cp=0.25, k=nil)
    end

    def self.InsulationFiberglassLoosefill
        return BaseMaterial.new(rho=0.5, cp=0.25, k=nil)
    end

    def self.InsulationGenericDensepack
        return BaseMaterial.new(rho=(BaseMaterial.InsulationFiberglassDensepack.rho + BaseMaterial.InsulationCelluloseDensepack.rho) / 2.0, cp=0.25, k=nil)
    end

    def self.InsulationGenericLoosefill
        return BaseMaterial.new(rho=(BaseMaterial.InsulationFiberglassLoosefill.rho + BaseMaterial.InsulationCelluloseLoosefill.rho) / 2.0, cp=0.25, k=nil)
    end

    def self.Soil
        return BaseMaterial.new(rho=115.0, cp=0.1, k=1)
    end

end

class Liquid
    def initialize(rho, cp, k, mu, h_fg, t_frz, t_boil, t_crit)
        @rho    = rho       # Density (lb/ft3)
        @cp     = cp        # Specific Heat (Btu/lbm-R)
        @k      = k         # Thermal Conductivity (Btu/h-ft-R)
        @mu     = mu        # Dynamic Viscosity (lbm/ft-h)
        @h_fg   = h_fg      # Latent Heat of Vaporization (Btu/lbm)
        @t_frz  = t_frz     # Freezing Temperature (degF)
        @t_boil = t_boil    # Boiling Temperature (degF)
        @t_crit = t_crit    # Critical Temperature (degF)
    end

    def rho
        return @rho
    end

    def Cp
        return @cp
    end

    def k
        return @k
    end

    def mu
        return @mu
    end

    def H_fg
        return @h_fg
    end

    def T_frz
        return @t_frz
    end

    def T_boil
        return @t_boil
    end

    def T_crit
        return @t_crit
    end
  
    def self.H2O_l
        # From EES at STP
        return Liquid.new(62.32,0.9991,0.3386,2.424,1055,32.0,212.0,nil)
    end

    def self.R22_l
        # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
        return Liquid.new(nil,0.2732,nil,nil,100.5,nil,-41.35,204.9)
    end
  
end

class Gas
    def initialize(rho, cp, k, mu, m)
        @rho    = rho           # Density (lb/ft3)
        @cp     = cp            # Specific Heat (Btu/lbm-R)
        @k      = k             # Thermal Conductivity (Btu/h-ft-R)
        @mu     = mu            # Dynamic Viscosity (lbm/ft-h)
        @m      = m             # Molecular Weight (lbm/lbmol)
        if @m
            gas_constant = 1.9858 # Gas Constant (Btu/lbmol-R)
            @r  = gas_constant / m # Gas Constant (Btu/lbm-R)
        else
            @r = nil
        end
    end

    def rho
        return @rho
    end

    def Cp
        return @cp
    end

    def k
        return @k
    end

    def mu
        return @mu
    end

    def M
        return @m
    end

    def R
        return @r
    end
  
    def self.Air
        # From EES at STP
        return Gas.new(0.07518,0.2399,0.01452,0.04415,28.97)
    end
    
    def self.AirGapRvalue
        return 1.0 # hr*ft*F/Btu (Assume for all air gap configurations since there is no correction for direction of heat flow in the simulation tools)
    end

    def self.H2O_v
        # From EES at STP
        return Gas.new(nil,0.4495,nil,nil,18.02)
    end
    
    def self.R22_v
        # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
        return Gas.new(nil,0.1697,nil,nil,nil)
    end

    def self.PsychMassRat
        return Gas.H2O_v.M / Gas.Air.M
    end
end

class AirFilms

    def self.OutsideR
        return 0.197 # hr-ft-F/Btu
    end
  
    def self.VerticalR
        return 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FlatEnhancedR
        return 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FlatReducedR
        return 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FloorAverageR
        # For floors between conditioned spaces where heat does not flow across
        # the floor; heat transfer is only important with regards to the thermal
        return (AirFilms.FlatReducedR + AirFilms.FlatEnhancedR) / 2.0 # hr-ft-F/Btu
    end

    def self.FloorReducedR
        # For floors above unconditioned basement spaces, where heat will
        # always flow down through the floor.
        return AirFilms.FlatReducedR # hr-ft-F/Btu
    end
  
    def self.SlopeEnhancedR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        return 0.002 * Math::exp(0.0398 * highest_roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to film_flat_enhanced at 0 degrees, 0.62 at 45 degrees, and film_vertical at 90 degrees)
    end
  
    def self.SlopeReducedR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        return 0.32 * Math::exp(-0.0154 * highest_roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to film_flat_reduced at 0 degrees, 0.76 at 45 degrees, and film_vertical at 90 degrees)
    end
  
    def self.SlopeEnhancedReflectiveR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        return 0.00893 * Math::exp(0.0419 * highest_roof_pitch) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
    end
  
    def self.SlopeReducedReflectiveR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        return 2.999 * Math::exp(-0.0333 * highest_roof_pitch) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
    end
  
    def self.RoofR(highest_roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return AirFilms.SlopeEnhancedR(highest_roof_pitch) * hdd_frac + AirFilms.SlopeReducedR(highest_roof_pitch) * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        return (AirFilms.SlopeEnhancedR(highest_roof_pitch) + AirFilms.SlopeReducedR(highest_roof_pitch)) / 2.0 # hr-ft-F/Btu
    end
  
    def self.RoofRadiantBarrierR(highest_roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return AirFilms.SlopeEnhancedReflectiveR(highest_roof_pitch) * hdd_frac + AirFilms.SlopeReducedReflectiveR(highest_roof_pitch) * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        return (AirFilms.SlopeEnhancedReflectiveR(highest_roof_pitch) + AirFilms.SlopeReducedReflectiveR(highest_roof_pitch)) / 2.0 # hr-ft-F/Btu
    end
    
end

class EnergyGuideLabel

    def self.get_energy_guide_gas_cost(date)
        # Search for, e.g., "Representative Average Unit Costs of Energy for Five Residential Energy Sources (1996)"
        if date <= 1991
            # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
            return 60.54
        elsif date == 1992
            # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
            return 58.0
        elsif date == 1993
            # No data, use prev/next years
            return (58.0 + 60.40)/2.0
        elsif date == 1994
            # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
            return 60.40
        elsif date == 1995
            # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
            return 63.0
        elsif date == 1996
            # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
            return 62.6
        elsif date == 1997
            # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
            return 61.2
        elsif date == 1998
            # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
            return 61.9
        elsif date == 1999
            # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
            return 68.8
        elsif date == 2000
            # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
            return 68.8
        elsif date == 2001
            # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
            return 83.7
        elsif date == 2002
            # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086
            return 65.6
        elsif date == 2003
            # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
            return 81.6
        elsif date == 2004
            # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
            return 91.0
        elsif date == 2005
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
            return 109.2
        elsif date == 2006
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
            return 141.5
        elsif date == 2007
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
            return 121.8
        elsif date == 2008
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
            return 132.8
        elsif date == 2009
            # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
            return 111.2
        elsif date == 2010
            # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
            return 119.4
        elsif date == 2011
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
            return 110.1
        elsif date == 2012
            # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
            return 105.9
        elsif date == 2013
            # http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
            return 108.7
        elsif date == 2014
            # http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
            return 112.8
        elsif date >= 2015
            # http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
            return 100.3
        end
    end
  
    def self.get_energy_guide_elec_cost(date)
        # Search for, e.g., "Representative Average Unit Costs of Energy for Five Residential Energy Sources (1996)"
        if date <= 1991
            # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
            return 8.24
        elsif date == 1992
            # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
            return 8.25
        elsif date == 1993
            # No data, use prev/next years
            return (8.25 + 8.41)/2.0
        elsif date == 1994
            # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
            return 8.41
        elsif date == 1995
            # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
            return 8.67
        elsif date == 1996
            # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
            return 8.60
        elsif date == 1997
            # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
            return 8.31
        elsif date == 1998
            # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
            return 8.42
        elsif date == 1999
            # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
            return 8.22
        elsif date == 2000
            # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
            return 8.03
        elsif date == 2001
            # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
            return 8.29
        elsif date == 2002
            # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086 
            return 8.28
        elsif date == 2003
            # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
            return 8.41
        elsif date == 2004
            # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
            return 8.60
        elsif date == 2005
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
            return 9.06
        elsif date == 2006
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
            return 9.91
        elsif date == 2007
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
            return 10.65
        elsif date == 2008
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
            return 10.80
        elsif date == 2009
            # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
            return 11.40
        elsif date == 2010
            # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
            return 11.50
        elsif date == 2011
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
            return 11.65
        elsif date == 2012
            # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
            return 11.84
        elsif date == 2013
            # http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
            return 12.10
        elsif date == 2014
            # http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
            return 12.40
        elsif date >= 2015
            # http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
            return 12.70
        end
    end
  
end
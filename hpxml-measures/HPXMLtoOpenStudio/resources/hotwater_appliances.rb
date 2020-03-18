require_relative 'constants'
require_relative 'weather'

class HotWaterAndAppliances
  def self.apply(model, weather, living_space,
                 cfa, nbeds, ncfl, has_uncond_bsmnt, wh_setpoint,
                 cw_mef, cw_ler, cw_elec_rate, cw_gas_rate,
                 cw_agc, cw_cap, cw_space, cd_fuel, cd_ef, cd_control,
                 cd_space, dw_ef, dw_cap, fridge_annual_kwh, fridge_space,
                 cook_fuel_type, cook_is_induction, oven_is_convection,
                 has_low_flow_fixtures, dist_type, pipe_r,
                 std_pipe_length, recirc_loop_length,
                 recirc_branch_length, recirc_control_type,
                 recirc_pump_power, dwhr_present,
                 dwhr_facilities_connected, dwhr_is_equal_flow,
                 dwhr_efficiency, dhw_loop_fracs, eri_version,
                 dhw_map, hpxml_path)

    # Schedules init
    timestep_minutes = (60.0 / model.getTimestep.numberOfTimestepsPerHour).to_i
    start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, model.getYearDescription.assumedYear)
    timestep_day = OpenStudio::Time.new(1, 0)

    t_mix = 105.0 # F, Temperature of mixed water at fixtures

    # Map plant loops to sys_ids
    dhw_loops = {}
    dhw_map.each do |sys_id, dhw_objects|
      dhw_objects.each do |dhw_object|
        next unless dhw_object.is_a? OpenStudio::Model::PlantLoop

        dhw_loops[sys_id] = dhw_object
      end
    end

    if not dist_type.nil?

      water_use_connections = {}
      setpoint_scheds = {}

      dhw_loop_fracs.each do |sys_id, dhw_load_frac|
        dhw_loop = dhw_loops[sys_id]
        water_use_connections[dhw_loop] = OpenStudio::Model::WaterUseConnections.new(model)
        dhw_map[sys_id] << water_use_connections[dhw_loop]
        dhw_loop.addDemandBranchForComponent(water_use_connections[dhw_loop])

        # Get water heater setpoint schedule
        dhw_map[sys_id].each do |dhw_object|
          if dhw_object.is_a? OpenStudio::Model::WaterHeaterMixed
            setpoint_scheds[dhw_loop] = dhw_object.setpointTemperatureSchedule.get
          elsif dhw_object.is_a? OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser
            setpoint_scheds[dhw_loop] = dhw_object.compressorSetpointTemperatureSchedule
          end
        end
        fail 'Could not find setpoint schedule.' if setpoint_scheds[dhw_loop].nil?
      end

      # Calculate mixed water fractions
      dwhr_eff_adj, dwhr_iFrac, dwhr_plc, dwhr_locF, dwhr_fixF = get_dwhr_factors(nbeds, dist_type, std_pipe_length, recirc_branch_length, dwhr_is_equal_flow, dwhr_facilities_connected, has_low_flow_fixtures)
      daily_wh_inlet_temperatures = calc_water_heater_daily_inlet_temperatures(weather, dwhr_present, dwhr_iFrac, dwhr_efficiency, dwhr_eff_adj, dwhr_plc, dwhr_locF, dwhr_fixF)
      daily_wh_inlet_temperatures_c = daily_wh_inlet_temperatures.map { |t| UnitConversions.convert(t, 'F', 'C') }
      daily_mw_fractions = calc_mixed_water_daily_fractions(daily_wh_inlet_temperatures, wh_setpoint, t_mix)

      # Replace mains water temperature schedule with water heater inlet temperature schedule.
      # These are identical unless there is a DWHR.
      time_series_tmains = OpenStudio::TimeSeries.new(start_date, timestep_day, OpenStudio::createVector(daily_wh_inlet_temperatures_c), 'C')
      schedule_tmains = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_tmains, model).get
      schedule_tmains.setName('mains temperature schedule')
      model.getSiteWaterMainsTemperature.setTemperatureSchedule(schedule_tmains)
    end

    # Clothes washer
    if (not dist_type.nil?) && (not cw_mef.nil?)
      cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = calc_clothes_washer_energy_gpd(eri_version, nbeds, cw_ler, cw_elec_rate, cw_gas_rate, cw_agc, cw_cap)
      cw_name = Constants.ObjectNameClothesWasher
      cw_schedule = HotWaterSchedule.new(model, cw_name, nbeds)
      cw_peak_flow = cw_schedule.calcPeakFlowFromDailygpm(cw_gpd)
      cw_design_level_w = cw_schedule.calcDesignLevelFromDailykWh(cw_annual_kwh / 365.0)
      add_electric_equipment(model, cw_name, cw_space, cw_design_level_w, cw_frac_sens, cw_frac_lat, cw_schedule.schedule)
      dhw_loop_fracs.each do |sys_id, dhw_load_frac|
        dhw_loop = dhw_loops[sys_id]
        add_water_use_equipment(model, cw_name, cw_peak_flow * dhw_load_frac, cw_schedule.schedule, setpoint_scheds[dhw_loop], water_use_connections[dhw_loop])
      end
    end

    # Clothes dryer
    if (not cw_mef.nil?) && (not cd_ef.nil?)
      cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = calc_clothes_dryer_energy(nbeds, cd_fuel, cd_ef, cd_control, cw_ler, cw_cap, cw_mef)
      cd_name = Constants.ObjectNameClothesDryer
      cd_weekday_sch = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
      cd_monthly_sch = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      cd_schedule = MonthWeekdayWeekendSchedule.new(model, cd_name, cd_weekday_sch, cd_weekday_sch, cd_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
      cd_design_level_e = cd_schedule.calcDesignLevelFromDailykWh(cd_annual_kwh / 365.0)
      cd_design_level_f = cd_schedule.calcDesignLevelFromDailyTherm(cd_annual_therm / 365.0)
      add_electric_equipment(model, cd_name, cd_space, cd_design_level_e, cd_frac_sens, cd_frac_lat, cd_schedule.schedule)
      add_other_equipment(model, cd_name, cd_space, cd_design_level_f, cd_frac_sens, cd_frac_lat, cd_schedule.schedule, cd_fuel)
    end

    # Dishwasher
    if (not dist_type.nil?) && (not dw_ef.nil?)
      dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = calc_dishwasher_energy_gpd(eri_version, nbeds, dw_ef, dw_cap)
      dw_name = Constants.ObjectNameDishwasher
      dw_schedule = HotWaterSchedule.new(model, dw_name, nbeds)
      dw_peak_flow = dw_schedule.calcPeakFlowFromDailygpm(dw_gpd)
      dw_design_level_w = dw_schedule.calcDesignLevelFromDailykWh(dw_annual_kwh / 365.0)
      add_electric_equipment(model, dw_name, living_space, dw_design_level_w, dw_frac_sens, dw_frac_lat, dw_schedule.schedule)
      dhw_loop_fracs.each do |sys_id, dhw_load_frac|
        dhw_loop = dhw_loops[sys_id]
        add_water_use_equipment(model, dw_name, dw_peak_flow * dhw_load_frac, dw_schedule.schedule, setpoint_scheds[dhw_loop], water_use_connections[dhw_loop])
      end
    end

    # Refrigerator
    if not fridge_annual_kwh.nil?
      fridge_name = Constants.ObjectNameRefrigerator
      fridge_weekday_sch = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      fridge_monthly_sch = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
      fridge_schedule = MonthWeekdayWeekendSchedule.new(model, fridge_name, fridge_weekday_sch, fridge_weekday_sch, fridge_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
      fridge_design_level = fridge_schedule.calcDesignLevelFromDailykWh(fridge_annual_kwh / 365.0)
      add_electric_equipment(model, fridge_name, fridge_space, fridge_design_level, 1.0, 0.0, fridge_schedule.schedule)
    end

    # Cooking Range
    if not cook_fuel_type.nil?
      cook_annual_kwh, cook_annual_therm, cook_frac_sens, cook_frac_lat = calc_range_oven_energy(nbeds, cook_fuel_type, cook_is_induction, oven_is_convection)
      cook_name = Constants.ObjectNameCookingRange
      cook_weekday_sch = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
      cook_monthly_sch = '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
      cook_schedule = MonthWeekdayWeekendSchedule.new(model, cook_name, cook_weekday_sch, cook_weekday_sch, cook_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
      cook_design_level_e = cook_schedule.calcDesignLevelFromDailykWh(cook_annual_kwh / 365.0)
      cook_design_level_f = cook_schedule.calcDesignLevelFromDailyTherm(cook_annual_therm / 365.0)
      add_electric_equipment(model, cook_name, living_space, cook_design_level_e, cook_frac_sens, cook_frac_lat, cook_schedule.schedule)
      add_other_equipment(model, cook_name, living_space, cook_design_level_f, cook_frac_sens, cook_frac_lat, cook_schedule.schedule, cook_fuel_type)
    end

    if not dist_type.nil?
      # Fixtures (showers, sinks, baths) + distribution losses
      fx_gpd = get_fixtures_gpd(eri_version, nbeds, has_low_flow_fixtures, daily_mw_fractions)
      w_gpd = get_dist_waste_gpd(eri_version, nbeds, has_uncond_bsmnt, cfa, ncfl, dist_type, pipe_r, std_pipe_length, recirc_branch_length, has_low_flow_fixtures)
      fx_gpd += w_gpd
      fx_sens_btu, fx_lat_btu = get_fixtures_gains_sens_lat(nbeds)

      debug = false
      if debug
        puts "#{File.basename(hpxml_path)} cw_gpd #{cw_gpd}"
        puts "#{File.basename(hpxml_path)} dw_gpd #{dw_gpd}"
        avg_f_mix = daily_mw_fractions.inject(:+) / daily_mw_fractions.size
        puts "#{File.basename(hpxml_path)} fx_gpd #{fx_gpd * avg_f_mix}"
        puts "#{File.basename(hpxml_path)} w_gpd #{w_gpd * avg_f_mix}"
        puts "#{File.basename(hpxml_path)} tot_gpd #{cw_gpd + dw_gpd + (fx_gpd + w_gpd) * avg_f_mix}"
      end

      disaggregate_sinks_showers_baths = false
      if disaggregate_sinks_showers_baths
        fx_names = [Constants.ObjectNameShower,
                    Constants.ObjectNameSink,
                    Constants.ObjectNameBath]
      else
        fx_names = [Constants.ObjectNameFixtures]
      end

      fx_schedules = {}
      fx_names.each do |fx_name|
        fx_schedules[fx_name] = HotWaterSchedule.new(model, fx_name, nbeds)
      end

      # Calculate sum_total_flow
      sum_total_flow = 0.0
      fx_schedules.each do |fx_name, fx_schedule|
        sum_total_flow += fx_schedule.totalFlow
      end

      mw_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      mw_schedule.setValue(UnitConversions.convert(t_mix, 'F', 'C'))
      Schedule.set_schedule_type_limits(model, mw_schedule, Constants.ScheduleTypeLimitsTemperature)

      fx_schedules.each do |fx_name, fx_schedule|
        fx_name_sens = "#{fx_name} Sensible"
        fx_name_lat = "#{fx_name} Latent"

        fx_schedule = fx_schedules[fx_name]
        fx_frac = fx_schedule.totalFlow / sum_total_flow

        fx_peak_flow = fx_schedule.calcPeakFlowFromDailygpm(fx_gpd * fx_frac)
        fx_design_level_sens = fx_schedule.calcDesignLevelFromDailykWh(UnitConversions.convert(fx_sens_btu * fx_frac, 'Btu', 'kWh') / 365.0)
        fx_design_level_lat = fx_schedule.calcDesignLevelFromDailykWh(UnitConversions.convert(fx_lat_btu * fx_frac, 'Btu', 'kWh') / 365.0)

        dhw_loop_fracs.each do |sys_id, dhw_load_frac|
          dhw_loop = dhw_loops[sys_id]
          add_water_use_equipment(model, fx_name, fx_peak_flow * dhw_load_frac, fx_schedule.schedule, mw_schedule, water_use_connections[dhw_loop])
        end
        add_other_equipment(model, fx_name_sens, living_space, fx_design_level_sens, 1.0, 0.0, fx_schedule.schedule, nil)
        add_other_equipment(model, fx_name_lat, living_space, fx_design_level_lat, 0.0, 1.0, fx_schedule.schedule, nil)
      end

      # Recirculation pump
      dist_pump_annual_kwh = get_hwdist_recirc_pump_energy(dist_type, recirc_control_type, recirc_pump_power)
      if dist_pump_annual_kwh > 0
        dist_pump_name = Constants.ObjectNameHotWaterRecircPump
        dist_pump_weekday_sch = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
        dist_pump_monthly_sch = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
        dist_pump_schedule = MonthWeekdayWeekendSchedule.new(model, dist_pump_name, dist_pump_weekday_sch, dist_pump_weekday_sch, dist_pump_monthly_sch, 1.0, 1.0)
        dist_pump_design_level = dist_pump_schedule.calcDesignLevelFromDailykWh(dist_pump_annual_kwh / 365.0)
        dhw_loop_fracs.each do |sys_id, dhw_load_frac|
          dhw_loop = dhw_loops[sys_id]
          dist_pump = add_electric_equipment(model, dist_pump_name, living_space, dist_pump_design_level * dhw_load_frac, 0.0, 0.0, dist_pump_schedule.schedule)
          dhw_map[sys_id] << dist_pump unless dist_pump.nil?
        end
      end
    end
  end

  def self.get_range_oven_reference_is_induction()
    return false
  end

  def self.get_range_oven_reference_is_convection()
    return false
  end

  def self.calc_range_oven_energy(nbeds, fuel_type, is_induction, is_convection)
    if is_induction
      burner_ef = 0.91
    else
      burner_ef = 1.0
    end
    if is_convection
      oven_ef = 0.95
    else
      oven_ef = 1.0
    end
    if fuel_type != HPXML::FuelTypeElectricity
      annual_kwh = 22.6 + 2.7 * nbeds
      annual_therm = oven_ef * (22.6 + 2.7 * nbeds)
      tot_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(annual_therm, 'therm', 'Btu')
      gains_sens = (4086.0 + 488.0 * nbeds) * 365 # Btu
      gains_lat = (1037.0 + 124.0 * nbeds) * 365 # Btu
      frac_sens = gains_sens / tot_btu
      frac_lat = gains_lat / tot_btu
    else
      annual_kwh = burner_ef * oven_ef * (331 + 39.0 * nbeds)
      annual_therm = 0.0
      tot_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(annual_therm, 'therm', 'Btu')
      gains_sens = (2228.0 + 262.0 * nbeds) * 365 # Btu
      gains_lat = (248.0 + 29.0 * nbeds) * 365 # Btu
      frac_sens = gains_sens / tot_btu
      frac_lat = gains_lat / tot_btu
    end
    return annual_kwh, annual_therm, frac_sens, frac_lat
  end

  def self.get_dishwasher_reference_ef()
    return 0.46
  end

  def self.get_dishwasher_reference_cap()
    return 12.0 # number of place settings
  end

  def self.calc_dishwasher_energy_gpd(eri_version, nbeds, ef, cap)
    dwcpy = (88.4 + 34.9 * nbeds) * (12.0 / cap) # Eq 4.2-8a (dWcpy)
    annual_kwh = ((86.3 + 47.73 / ef) / 215.0) * dwcpy # Eq 4.2-8a
    tot_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu')

    gains_sens = (219.0 + 87.0 * nbeds) * 365 # Btu
    gains_lat = (219.0 + 87.0 * nbeds) * 365 # Btu
    frac_sens = gains_sens / tot_btu
    frac_lat = gains_lat / tot_btu

    if eri_version != '2014' # 2014 w/ Addendum A or newer
      gpd = dwcpy * (4.6415 * (1.0 / ef) - 1.9295) / 365.0 # Eq. 4.2-11 (DWgpd)
    else
      gpd = ((88.4 + 34.9 * nbeds) * 8.16 - (88.4 + 34.9 * nbeds) * 12.0 / cap * (4.6415 * (1.0 / ef) - 1.9295)) / 365.0 # Eq 4.2-8b
    end

    return annual_kwh, frac_sens, frac_lat, gpd
  end

  def self.calc_dishwasher_ef_from_annual_kwh(annual_kwh)
    return 215.0 / annual_kwh # 4.2.2.5.2.9. Dishwashers
  end

  def self.get_refrigerator_reference_annual_kwh(nbeds)
    annual_kwh = 637.0 + 18.0 * nbeds # kWh/yr
    return annual_kwh
  end

  def self.get_clothes_dryer_reference_cef(fuel_type)
    if fuel_type == HPXML::FuelTypeElectricity
      return 2.62
    else
      return 2.32
    end
  end

  def self.get_clothes_dryer_reference_control()
    return HPXML::ClothesDryerControlTypeTimer
  end

  def self.calc_clothes_dryer_energy(nbeds, fuel_type, ef, control_type, cw_ler, cw_cap, cw_mef)
    # Eq 4.2-6 (FU)
    field_util_factor = nil
    if control_type == HPXML::ClothesDryerControlTypeTimer
      field_util_factor = 1.18
    elsif control_type == HPXML::ClothesDryerControlTypeMoisture
      field_util_factor = 1.04
    end
    if fuel_type == HPXML::FuelTypeElectricity
      annual_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / ef) * ((cw_cap / cw_mef) - cw_ler / 392.0) / (0.2184 * (cw_cap * 4.08 + 0.24)) # Eq 4.2-6
      annual_therm = 0.0
    else
      annual_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / 3.01) * ((cw_cap / cw_mef) - cw_ler / 392.0) / (0.2184 * (cw_cap * 4.08 + 0.24)) # Eq 4.2-6
      annual_therm = annual_kwh * 3412.0 * (1.0 - 0.07) * (3.01 / ef) / 100000 # Eq 4.2-7a
      annual_kwh = annual_kwh * 0.07 * (3.01 / ef)
    end
    tot_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(annual_therm, 'therm', 'Btu')

    if fuel_type != HPXML::FuelTypeElectricity
      gains_sens = (738.0 + 209.0 * nbeds) * 365 # Btu
      gains_lat = (91.0 + 26.0 * nbeds) * 365 # Btu
    else
      gains_sens = (661.0 + 188.0 * nbeds) * 365 # Btu
      gains_lat = (73.0 + 21.0 * nbeds) * 365 # Btu
    end
    frac_sens = gains_sens / tot_btu
    frac_lat = gains_lat / tot_btu

    return annual_kwh, annual_therm, frac_sens, frac_lat
  end

  def self.calc_clothes_dryer_ef_from_cef(cef)
    return cef * 1.15 # Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF
  end

  def self.get_clothes_washer_reference_imef()
    return 0.331
  end

  def self.get_clothes_washer_reference_ler()
    return 704.0 # kWh/yr
  end

  def self.get_clothes_washer_reference_elec_rate()
    return 0.0803 # $/kWh
  end

  def self.get_clothes_washer_reference_gas_rate()
    return 0.58 # $/therm
  end

  def self.get_clothes_washer_reference_agc()
    return 23.0 # $
  end

  def self.get_clothes_washer_reference_cap()
    return 2.874 # ft^3
  end

  def self.calc_clothes_washer_energy_gpd(eri_version, nbeds, ler, elec_rate, gas_rate, agc, cap)
    # Eq 4.2-9a
    ncy = (3.0 / 2.847) * (164 + nbeds * 45.6)
    if eri_version != '2014' # 2014 w/ Addendum A or newer
      ncy = (3.0 / 2.847) * (164 + nbeds * 46.5)
    end
    acy = ncy * ((3.0 * 2.08 + 1.59) / (cap * 2.08 + 1.59)) # Adjusted Cycles per Year
    annual_kwh = ((ler / 392.0) - ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392.0) * 21.9825) * acy
    tot_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu')

    gains_sens = (95.0 + 26.0 * nbeds) * 365 # Btu
    gains_lat = (11.0 + 3.0 * nbeds) * 365 # Btu
    frac_sens = gains_sens / tot_btu
    frac_lat = gains_lat / tot_btu

    gpd = 60.0 * ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392.0) * acy / 365.0
    if eri_version == '2014' # 2014 w/o Addendum A
      gpd -= 3.97 # Section 4.2.2.5.2.10
    end

    return annual_kwh, frac_sens, frac_lat, gpd
  end

  def self.calc_clothes_washer_mef_from_imef(imef)
    return 0.503 + 0.95 * imef # Interpretation on ANSI/RESNET 301-2014 Clothes Washer IMEF
  end

  def self.get_dist_energy_consumption_adjustment(has_uncond_bsmnt, cfa, ncfl,
                                                  dist_type, recirc_control_type,
                                                  pipe_r, std_pipe_length, recirc_loop_length)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-16
    ew_fact = get_dist_energy_waste_factor(dist_type, recirc_control_type, pipe_r)
    o_frac = 0.25 # fraction of hot water waste from standard operating conditions
    oew_fact = ew_fact * o_frac # standard operating condition portion of hot water energy waste
    ocd_eff = 0.0
    sew_fact = ew_fact - oew_fact
    ref_pipe_l = get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    if dist_type == HPXML::DHWDistTypeStandard
      pe_ratio = std_pipe_length / ref_pipe_l
    elsif dist_type == HPXML::DHWDistTypeRecirc
      ref_loop_l = get_default_recirc_loop_length(ref_pipe_l)
      pe_ratio = recirc_loop_length / ref_loop_l
    end
    e_waste = oew_fact * (1.0 - ocd_eff) + sew_fact * pe_ratio
    return (e_waste + 128.0) / 160.0
  end

  def self.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    bsmnt = has_uncond_bsmnt ? 1 : 0
    return 2.0 * (cfa / ncfl)**0.5 + 10.0 * ncfl + 5.0 * bsmnt # Eq. 4.2-13 (refPipeL)
  end

  def self.get_default_recirc_loop_length(std_pipe_length)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    return 2.0 * std_pipe_length - 20.0 # Eq. 4.2-17 (refLoopL)
  end

  private

  def self.add_electric_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule)
    return if design_level_w == 0.0

    ee_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    ee = OpenStudio::Model::ElectricEquipment.new(ee_def)
    ee.setName(obj_name)
    ee.setEndUseSubcategory(obj_name)
    ee.setSpace(space)
    ee_def.setName(obj_name)
    ee_def.setDesignLevel(design_level_w)
    ee_def.setFractionRadiant(0.6 * frac_sens)
    ee_def.setFractionLatent(frac_lat)
    ee_def.setFractionLost(1.0 - frac_sens - frac_lat)
    ee.setSchedule(schedule)

    return ee
  end

  def self.add_other_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule, fuel_type)
    return if design_level_w == 0.0

    oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    oe = OpenStudio::Model::OtherEquipment.new(oe_def)
    oe.setName(obj_name)
    oe.setEndUseSubcategory(obj_name)
    if fuel_type.nil?
      oe.setFuelType('None')
    else
      oe.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
    end
    oe.setSpace(space)
    oe_def.setName(obj_name)
    oe_def.setDesignLevel(design_level_w)
    oe_def.setFractionRadiant(0.6 * frac_sens)
    oe_def.setFractionLatent(frac_lat)
    oe_def.setFractionLost(1.0 - frac_sens - frac_lat)
    oe.setSchedule(schedule)

    return oe
  end

  def self.add_water_use_equipment(model, obj_name, peak_flow, schedule, temp_schedule, water_use_connection)
    return if peak_flow == 0.0

    wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    wu = OpenStudio::Model::WaterUseEquipment.new(wu_def)
    wu.setName(obj_name)
    wu_def.setName(obj_name)
    wu_def.setPeakFlowRate(peak_flow)
    wu_def.setEndUseSubcategory(obj_name)
    wu.setFlowRateFractionSchedule(schedule)
    wu_def.setTargetTemperatureSchedule(temp_schedule)
    water_use_connection.addWaterUseEquipment(wu)

    return wu
  end

  def self.get_dwhr_factors(nbeds, dist_type, std_pipe_length, recirc_branch_length, is_equal_flow, facilities_connected, has_low_flow_fixtures)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-14

    eff_adj = 1.0
    if has_low_flow_fixtures
      eff_adj = 1.082
    end

    iFrac = 0.56 + 0.015 * nbeds - 0.0004 * nbeds**2 # fraction of hot water use impacted by DWHR

    if dist_type == HPXML::DHWDistTypeRecirc
      pLength = recirc_branch_length
    elsif dist_type == HPXML::DHWDistTypeStandard
      pLength = std_pipe_length
    end
    plc = 1 - 0.0002 * pLength # piping loss coefficient

    # Location factors for DWHR placement
    if is_equal_flow
      locF = 1.000
    else
      locF = 0.777
    end

    # Fixture Factor
    if facilities_connected == HPXML::DWHRFacilitiesConnectedAll
      fixF = 1.0
    elsif facilities_connected == HPXML::DWHRFacilitiesConnectedOne
      fixF = 0.5
    end

    return eff_adj, iFrac, plc, locF, fixF
  end

  def self.calc_water_heater_daily_inlet_temperatures(weather, dwhr_present = false, dwhr_iFrac = nil, dwhr_eff = nil,
                                                      dwhr_eff_adj = nil, dwhr_plc = nil, dwhr_locF = nil, dwhr_fixF = nil)

    # Get daily mains temperatures
    avgOAT = weather.data.AnnualAvgDrybulb
    maxDiffMonthlyAvgOAT = weather.data.MonthlyAvgDrybulbs.max - weather.data.MonthlyAvgDrybulbs.min
    tmains_daily = WeatherProcess.calc_mains_temperatures(avgOAT, maxDiffMonthlyAvgOAT, weather.header.Latitude)[2]

    wh_temps_daily = tmains_daily
    if dwhr_present
      # Adjust inlet temperatures
      dwhr_inT = 97.0 # F
      for day in 0..364
        dwhr_WHinTadj = dwhr_iFrac * (dwhr_inT - tmains_daily[day]) * dwhr_eff * dwhr_eff_adj * dwhr_plc * dwhr_locF * dwhr_fixF
        wh_temps_daily[day] = (wh_temps_daily[day] + dwhr_WHinTadj).round(3)
      end
    else
      for day in 0..364
        wh_temps_daily[day] = (wh_temps_daily[day]).round(3)
      end
    end

    return wh_temps_daily
  end

  def self.calc_mixed_water_daily_fractions(daily_wh_inlet_temperatures, tHot, tMix)
    adjFmix = []
    for day in 0..364
      adjFmix << (1.0 - ((tHot - tMix) / (tHot - daily_wh_inlet_temperatures[day]))).round(4)
    end

    return adjFmix
  end

  def self.get_hwdist_recirc_pump_energy(dist_type, recirc_control_type, recirc_pump_power)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(5) Annual electricity consumption factor for hot water recirculation system pumps
    if dist_type == HPXML::DHWDistTypeRecirc
      if (recirc_control_type == HPXML::DHWRecirControlTypeNone) || (recirc_control_type == HPXML::DHWRecirControlTypeTimer)
        return 8.76 * recirc_pump_power
      elsif recirc_control_type == HPXML::DHWRecirControlTypeTemperature
        return 1.46 * recirc_pump_power
      elsif recirc_control_type == HPXML::DHWRecirControlTypeSensor
        return 0.15 * recirc_pump_power
      elsif recirc_control_type == HPXML::DHWRecirControlTypeManual
        return 0.10 * recirc_pump_power
      end
    elsif dist_type == HPXML::DHWDistTypeStandard
      return 0.0
    end
    fail 'Unexpected hot water distribution system.'
  end

  def self.get_fixtures_effectiveness(has_low_flow_fixtures)
    f_eff = has_low_flow_fixtures ? 0.95 : 1.0
    return f_eff
  end

  def self.get_fixtures_gpd(eri_version, nbeds, has_low_flow_fixtures, daily_mw_fractions)
    if eri_version == '2014' # 2014 w/o Addendum A
      hw_gpd = 30.0 + 10.0 * nbeds # Table 4.2.2(1) Service water heating systems
      # Convert to mixed water gpd
      avg_mw_fraction = daily_mw_fractions.reduce(:+) / daily_mw_fractions.size.to_f
      return hw_gpd / avg_mw_fraction
    end

    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    ref_f_gpd = 14.6 + 10.0 * nbeds # Eq. 4.2-2 (refFgpd)
    f_eff = get_fixtures_effectiveness(has_low_flow_fixtures)
    return f_eff * ref_f_gpd
  end

  def self.get_fixtures_gains_sens_lat(nbeds)
    # Table 4.2.2(3). Internal Gains for Reference Homes
    sens_gains = -1227.0 - 409.0 * nbeds # Btu/day
    lat_gains = 1245.0 + 415.0 * nbeds # Btu/day
    return sens_gains * 365.0, lat_gains * 365.0
  end

  def self.get_dist_waste_gpd(eri_version, nbeds, has_uncond_bsmnt, cfa, ncfl,
                              dist_type, pipe_r, std_pipe_length,
                              recirc_branch_length, has_low_flow_fixtures)
    if eri_version == '2014' # 2014 w/o Addendum A
      return 0.0
    end

    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # 4.2.2.5.2.11 Service Hot Water Use

    # Table 4.2.2.5.2.11(2) Hot Water Distribution System Insulation Factors
    sys_factor = nil
    if (dist_type == HPXML::DHWDistTypeRecirc) && (pipe_r < 3.0)
      sys_factor = 1.11
    elsif (dist_type == HPXML::DHWDistTypeRecirc) && (pipe_r >= 3.0)
      sys_factor = 1.0
    elsif (dist_type == HPXML::DHWDistTypeStandard) && (pipe_r >= 3.0)
      sys_factor = 0.90
    elsif (dist_type == HPXML::DHWDistTypeStandard) && (pipe_r < 3.0)
      sys_factor = 1.0
    end

    ref_w_gpd = 9.8 * (nbeds**0.43) # Eq. 4.2-2 (refWgpd)
    o_frac = 0.25
    o_cd_eff = 0.0

    if dist_type == HPXML::DHWDistTypeRecirc
      p_ratio = recirc_branch_length / 10.0
    elsif dist_type == HPXML::DHWDistTypeStandard
      ref_pipe_l = get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
      p_ratio = std_pipe_length / ref_pipe_l
    end

    o_w_gpd = ref_w_gpd * o_frac * (1.0 - o_cd_eff) # Eq. 4.2-12
    s_w_gpd = (ref_w_gpd - ref_w_gpd * o_frac) * p_ratio * sys_factor # Eq. 4.2-13

    # Table 4.2.2.5.2.11(3) Distribution system water use effectiveness
    if dist_type == HPXML::DHWDistTypeRecirc
      wd_eff = 0.1
    elsif dist_type == HPXML::DHWDistTypeStandard
      wd_eff = 1.0
    end

    f_eff = get_fixtures_effectiveness(has_low_flow_fixtures)

    mw_gpd = f_eff * (o_w_gpd + s_w_gpd * wd_eff) # Eq. 4.2-11

    return mw_gpd
  end

  def self.get_dist_energy_waste_factor(dist_type, recirc_control_type, pipe_r)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(6) Hot water distribution system relative annual energy waste factors
    if dist_type == HPXML::DHWDistTypeRecirc
      if (recirc_control_type == HPXML::DHWRecirControlTypeNone) || (recirc_control_type == HPXML::DHWRecirControlTypeTimer)
        if pipe_r < 3.0
          return 500.0
        else
          return 250.0
        end
      elsif recirc_control_type == HPXML::DHWRecirControlTypeTemperature
        if pipe_r < 3.0
          return 375.0
        else
          return 187.5
        end
      elsif recirc_control_type == HPXML::DHWRecirControlTypeSensor
        if pipe_r < 3.0
          return 64.8
        else
          return 43.2
        end
      elsif recirc_control_type == HPXML::DHWRecirControlTypeManual
        if pipe_r < 3.0
          return 43.2
        else
          return 28.8
        end
      end
    elsif dist_type == HPXML::DHWDistTypeStandard
      if pipe_r < 3.0
        return 32.0
      else
        return 28.8
      end
    end
    fail 'Unexpected hot water distribution system.'
  end
end
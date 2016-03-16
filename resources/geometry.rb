require "#{File.dirname(__FILE__)}/constants"

class Geometry

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

    # Retrieves the finished floor area for the building
    def self.get_building_finished_floor_area(model, runner=nil)
        floor_area = 0
        model.getThermalZones.each do |zone|
            if self.zone_is_finished(zone)
                runner.registerWarning(zone.name.to_s)
                floor_area += OpenStudio.convert(zone.floorArea,"m^2","ft^2").get
            end
        end
        if floor_area == 0 and not runner.nil?
            runner.registerError("Could not find any finished floor area.")
            return nil
        end
        return floor_area
    end
    
    # Calculates the space height as the max z coordinate minus the min z coordinate
    def self.space_height(space)
        zvalues = Geometry.getSurfaceZValues(space.surfaces)
        minz = zvalues.min
        maxz = zvalues.max
        return OpenStudio.convert(maxz - minz, "m", "ft").get
    end
    
    # Calculates the surface height as the max z coordinate minus the min z coordinate
    def self.surface_height(surface)
        zvalues = Geometry.getSurfaceZValues([surface])
        minz = zvalues.min
        maxz = zvalues.max
        return OpenStudio.convert(maxz - minz, "m", "ft").get
    end
    
    def self.zone_is_finished(zone)
        # FIXME: Ugly hack until we can get finished zones from OS
        if zone.name.to_s == Constants.LivingZone or zone.name.to_s == Constants.FinishedBasementZone
            return true
        end
        return false
    end
    
    def self.space_is_unfinished(space)
        return !Geometry.space_is_finished(space)
    end
    
    def self.space_is_finished(space)
        if space.thermalZone.is_initialized
            return Geometry.zone_is_finished(space.thermalZone.get)
        end
        return false
    end
    
    # Returns true if space is fully above grade
    def self.space_is_above_grade(space)
        return !Geometry.space_is_below_grade(space)
    end
    
    # Returns true if space is either fully or partially below grade
    def self.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            if surface.isGroundSurface
                return true
            end
        end
        return false
    end
    
    def self.space_is_below_roof(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            next if surface.tilt != 0
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
    
    def self.get_space_from_surface(model, surface_s, runner, print_err=true)
        space_r = nil
        model.getSpaces.each do |space|
            space.surfaces.each do |s|
                if s.name.to_s == surface_s
                    space_r = space
                    break
                end
            end
        end
        if space_r.nil?
            if print_err
                runner.registerError("Could not find surface with the name '#{surface_s}'.")
            else
                runner.registerWarning("Could not find surface with the name '#{surface_s}'.")
            end
        end     
        return space_r
    end

    def self.get_space_type_from_surface(model, surface_s, runner, print_err=true)
        space_type_r = nil
        model.getSpaces.each do |space|
            space.surfaces.each do |s|
                if s.name.to_s == surface_s
                    space_type_r = space.spaceType.get
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
    
    def self.get_space_type_from_sub_surface(model, sub_surface_s, runner, print_err=true)
        space_type_r = nil
        model.getSpaces.each do |space|
            space.surfaces.each do |surface|
                surface.subSurfaces.each do |s|
                    if s.name.to_s == sub_surface_s
                        space_type_r = space.spaceType.get
                        break
                    end
                end
            end
        end
        if space_type_r.nil?
            if print_err
                runner.registerError("Could not find surface with the name '#{sub_surface_s}'.")
            else
                runner.registerWarning("Could not find surface with the name '#{sub_surface_s}'.")
            end
        end     
        return space_type_r
    end
   
    # Return an array of z values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
    def self.getSurfaceZValues(surfaceArray)
        zValueArray = []
        surfaceArray.each do |surface|
            surface.vertices.each do |vertex|
                zValueArray << vertex.z
            end
        end
        result = zValueArray
        return result
    end
    
    # Takes in a list of spaces and returns the average space height
    def self.spaces_avg_height(spaces)
        sum_height = 0
        spaces.each do |space|
            sum_height += Geometry.space_height(space)
        end
        return sum_height/spaces.size
    end
    
    # Takes in a list of spaces and returns the total floor area
    def self.calculate_floor_area(spaces)
        floor_area = 0
        spaces.each do |space|
            floor_area += space.floorArea
        end
        return OpenStudio.convert(floor_area, "m^2", "ft^2").get
    end
    
    # Takes in a list of spaces and returns the total wall area
    def self.calculate_wall_area(spaces)
        wall_area = 0
        spaces.each do |space|
            space.surfaces.each do |surface|
                if surface.surfaceType.downcase == "wall"
                    wall_area += surface.grossArea
                end
            end
        end
        return OpenStudio.convert(wall_area, "m^2", "ft^2").get
    end
    
    # Takes in a list of spaces and returns the wall area for the exterior perimeter
    def self.calculate_perimeter_wall_area(spaces)
        return Geometry.calculate_perimeter(spaces) * Geometry.calculate_wall_area(spaces)
    end
   
    # Takes in a list of spaces and checks for edges shared by a ground exposed floor and exterior exposed wall.
    def self.calculate_perimeter(spaces)

        perimeter = 0
        spaces.each do |space|
            # counter to use later
            edge_hash = {}
            edge_counter = 0
            space.surfaces.each do |surface|
                # get vertices
                vertex_hash = {}
                vertex_counter = 0
                surface.vertices.each do |vertex|
                    vertex_counter += 1
                    vertex_hash[vertex_counter] = [vertex.x,vertex.y,vertex.z]
                end
                # make edges
                counter = 0
                vertex_hash.each do |k,v|
                    edge_counter += 1
                    counter += 1
                    if vertex_hash.size != counter
                        edge_hash[edge_counter] = [v,vertex_hash[counter+1],surface,surface.outsideBoundaryCondition,surface.surfaceType]
                    else # different code for wrap around vertex
                        edge_hash[edge_counter] = [v,vertex_hash[1],surface,surface.outsideBoundaryCondition,surface.surfaceType]
                    end
                end
            end

            # check edges for matches (need opposite vertices and proper boundary conditions)
            edge_hash.each do |k1,v1|
                next if v1[3] != "Ground" # skip if not ground exposed floor
                next if v1[4] != "Floor"
                edge_hash.each do |k2,v2|
                    next if v2[3] != "Outdoors" # skip if not exterior exposed wall (todo - update to handle basement)
                    next if v2[4] != "Wall"
                    # see if edges have same geometry
                    next if not v1[0] == v2[1] # next if not same geometry reversed
                    next if not v1[1] == v2[0]
                    point_one = OpenStudio::Point3d.new(v1[0][0],v1[0][1],v1[0][2])
                    point_two = OpenStudio::Point3d.new(v1[1][0],v1[1][1],v1[1][2])
                    length = OpenStudio::Vector3d.new(point_one - point_two).length
                    perimeter += length
                end
            end
        end
    
        return OpenStudio.convert(perimeter, "m", "ft").get
    end
    
    def self.get_crawl_spaces(model)
        spaces = []
        model.getSpaces.each do |space|
            next if Geometry.space_is_above_grade(space)
            next if Geometry.space_height(space) >= Constants.MinimumBasementHeight
            spaces << space
        end
        return spaces
    end
    
    def self.get_finished_basement_spaces(model)
        spaces = []
        model.getSpaces.each do |space|
            next if Geometry.space_is_unfinished(space)
            next if Geometry.space_is_above_grade(space)
            next if Geometry.space_height(space) < Constants.MinimumBasementHeight
            spaces << space
        end
        return spaces
    end
    
    def self.get_unfinished_basement_spaces(model)
        spaces = []
        model.getSpaces.each do |space|
            next if Geometry.space_is_finished(space)
            next if Geometry.space_is_above_grade(space)
            next if Geometry.space_height(space) < Constants.MinimumBasementHeight
            spaces << space
        end
        return spaces
    end
   
    def self.get_unfinished_attic_spaces(model)
        spaces = []
        model.getSpaces.each do |space|
            next if Geometry.space_is_finished(space)
            next if !Geometry.space_is_below_roof(space)
            spaces << space
        end
        return spaces
    end
    
    def self.get_finished_attic_spaces(model)
        spaces = []
        model.getSpaces.each do |space|
            next if Geometry.space_is_unfinished(space)
            next if !Geometry.space_is_below_roof(space)
            spaces << space
        end
        return spaces
    end
    
end
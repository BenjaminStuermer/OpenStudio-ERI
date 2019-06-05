Software Connection
===================

In order to connect a software tool to the OpenStudio-ERI workflow, the software tool must be able to export its building description in `HPXML file <https://hpxml.nrel.gov/>`_ format.

HPXML Overview
--------------

HPXML is an open data standard for collecting and transferring home energy data. 
Requiring HPXML files as the input to the ERI workflow significantly reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.
It also simplifies the process of applying the ERI 301 ruleset.

The `HPXML Toolbox website <https://hpxml.nrel.gov/>`_ provides several resources for software developers, including:

#. An interactive schema validator
#. A data dictionary
#. An implementation guide

HPXML for ERI
-------------

HPXML is an flexible and extensible format, where nearly all fields in the schema are optional and custom fields can be included.
Because of this, an ERI Use Case for HPXML has been developed that specifies the HPXML fields or enumeration choices required to run the workflow.

The `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb>`_ is defined as a set of conditional XPath expressions.

It operates on top of **HPXML v3 (proposed)** files.

ERI Version
~~~~~~~~~~~

The version of the ERI calculation to be run is specified inside the HPXML file itself at ``/HPXML/SoftwareInfo/extension/ERICalculation/Version``. 
For example, a value of "2014AE" tells the workflow to use ANSI/RESNET/ICC© 301-2014 with both Addendum A (Amendment on Domestic Hot Water Systems) and Addendum E (House Size Index Adjustment Factors) included.

.. note:: 

  Valid choices for ERI version can be looked up in the `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb>`_.

Building Details
~~~~~~~~~~~~~~~~

The building description is entered in HPXML's ``/HPXML/Building/BuildingDetails``.

Building Summary
~~~~~~~~~~~~~~~~

This section describes fields specified in HPXML's ``BuildingSummary``. It is used for high-level building information needed for an ERI calculation including conditioned floor area, number of bedrooms, number of conditioned floors, etc.

The ``BuildingSummary/Site/FuelTypesAvailable`` field is used to determine whether the home has access to natural gas or fossil fuel delivery (specified by any value other than "electricity").
This information may be used for determining the heating system, as specified by the ERI 301 Standard.

Climate and Weather
~~~~~~~~~~~~~~~~~~~

This section describes fields specified in HPXML's ``ClimateandRiskZones``.

``ClimateandRiskZones/ClimateZoneIECC`` specifies the IECC climate zone(s) for years required by the ERI 301 Standard.

``ClimateandRiskZones/WeatherStation`` specifies the EnergyPlus weather file (EPW) to be used in the simulation. 
The ``WeatherStation/WMO`` must be one of the acceptable WMO station numbers found in the `weather/data.csv <https://github.com/NREL/OpenStudio-ERI/blob/master/weather/data.csv>`_ file.

.. note:: 

  In the future, we hope to provide an automated lookup capability based on a building's address/zipcode or similar information. But for now, each software tool is responsible for providing this information.

Enclosure
~~~~~~~~~

This section describes fields specified in HPXML's ``Enclosure``.

All surfaces that bound different space types in the building (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.
For software tools that do not collect sufficient inputs for every required surface, the software developers will need to make assumptions about these surfaces or collect additional input.

The space types used in the HPXML building description are:

============================  ===================================
Space Type                    Notes
============================  ===================================
living space                  Above-grade conditioned floor area.
attic - vented            
attic - unvented          
basement - conditioned        Below-grade conditioned floor area.
basement - unconditioned  
crawlspace - vented       
crawlspace - unvented     
garage                    
other housing unit            Used to specify adiabatic surfaces.
============================  ===================================

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth to be specified. 
Rather, only the windows/skylights themselves require an azimuth. 
Thus, software tools can use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

Air Leakage
***********

Building air leakage characterized by air changes per hour at 50 pascals pressure difference (ACH50) is entered at ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage/AirLeakage``. 
A value of "50" must be specified for ``AirInfiltrationMeasurement/HousePressure`` and a value of "ACH" must be specified for ``BuildingAirLeakage/UnitofMeasure``.

In addition, the building's volume associated with the air leakage measurement is provided in HPXML's ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/InfiltrationVolume``.

Vented Attics/Crawlspaces
*************************

The ventilation rate for vented attics (or crawlspaces) can be specified using an ``Attic`` (or ``Foundation``) element.
First, define the ``AtticType`` as ``Attic[Vented='true']`` (or ``FoundationType`` as ``Crawlspace[Vented='true']``).
Then use the ``VentilationRate[UnitofMeasure='SLA']/Value`` element to specify a specific leakage area (SLA).
If these elements are not provided, the ERI 301 Standard Reference Home defaults will be used.

Roofs
*****

Pitched or flat roof surfaces that are exposed to ambient conditions should be specified as an ``Enclosure/Roofs/Roof``. 
For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``Floor`` and not a ``Roof``.

Beyond the specification of typical heat transfer properties (insulation R-value, solar absorptance, emittance, etc.), note that roofs can be defined as having a radiant barrier.

Walls
*****

Any wall that has no contact with the ground and bounds a space type should be specified as an ``Enclosure/Walls/Wall``. Interior walls (for example, walls solely within the conditioned space of the building) are not required.

Walls are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.
The choice of ``WallType`` has a secondary effect on heat transfer in that it informs the assumption of wall thermal mass.

Rim Joists
**********

Rim joists, the perimeter of floor joists typically found between stories of a building or on top of a foundation wall, are specified as an ``Enclosure//RimJoists/RimJoist``.

The ``InteriorAdjacentTo`` element should typically be "living space" for rim joists between stories of a building and "basement - conditioned", "basement - unconditioned", "crawlspace - vented", or "crawlspace - unvented" for rim joists on top of a foundation wall.

Foundation Walls
****************

Any wall that is in contact with the ground should be specified as an ``Enclosure/FoundationWalls/FoundationWall``. 
Other walls (e.g., wood framed walls) that are connected to a below-grade space but have no contact with the ground should be specified as ``Walls`` and not ``FoundationWalls``.

*Exterior* foundation walls (i.e., those that fall along the perimeter of the building's footprint) should use "ground" for ``ExteriorAdjacentTo`` and the appropriate space type (e.g., "basement - unconditioned") for ``InteriorAdjacentTo``.

*Interior* foundation walls should be specified with two appropriate space types (e.g., "crawlspace - vented" and "garage", or "basement - unconditioned" and "crawlspace - unvented") for ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo``.
Interior foundation walls should never use "ground" for ``ExteriorAdjacentTo`` even if the foundation wall has some contact with the ground due to the difference in below-grade depths of the two adjacent space types.

Foundations must include a ``Height`` as well as a ``DepthBelowGrade``. 
For exterior foundation walls, the depth below grade is relative to the ground plane.
For interior foundation walls, the depth below grade **should not** be thought of as relative to the ground plane, but rather as the depth of foundation wall in contact with the ground.
For example, an interior foundation wall between an 8 ft conditioned basement and a 3 ft crawlspace has a height of 8 ft and a depth below grade of 5 ft.
Alternatively, an interior foundation wall between an 8 ft conditioned basement and an 8 ft unconditioned basement has a height of 8 ft and a depth below grade of 0 ft.

Foundation wall insulation can be described in two ways: 

Option 1. A continuous insulation layer with ``NominalRValue`` and ``DistanceToBottomOfInsulation``. 
An insulation layer is useful for describing foundation wall insulation that doesn't span the entire height (e.g., 4 ft of insulation for an 8 ft conditioned basement). 
When an insulation layer R-value is specified, it is modeled with a concrete wall (whose ``Thickness`` is provided) as well as air film resistances as appropriate.

Option 2. An ``AssemblyEffectiveRValue``. 
When instead providing an assembly effective R-value, the R-value should include the concrete wall and an interior air film resistance. 
The exterior air film resistance (for any above-grade exposure) or any soil thermal resistance should **not** be included.

Frame Floors
************

TODO

Slabs
*****

Any space type that borders the ground should include an ``Enclosure/Slabs/Slab`` surface with the appropriate ``InteriorAdjacentTo``. 
This includes basements, crawlspaces (even when there are dirt floors -- use zero for the ``Thickness``), garages, and slab-on-grade foundations.

A primary input for a slab is its ``ExposedPerimeter``. The exposed perimeter should include any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
So, a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.

Vertical insulation adjacent to the slab can be described by a ``PerimeterInsulation/Layer/NominalRValue`` and a ``PerimeterInsulationDepth``.

Horizontal insulation under the slab can be described by a ``UnderSlabInsulation/Layer/NominalRValue``. The insulation can either have a depth (``UnderSlabInsulationWidth``) or can span the entire slab (``UnderSlabInsulationSpansEntireSlab``).

Windows
*******

Any window or glass door area should be specified in an ``Enclosure/Windows/Window``.

Windows are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Windows must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Windows must also have an ``Azimuth`` specified, even if the attached wall does not.

Overhangs can optionally be defined for a window by specifying a ``Window/Overhangs`` element.
Overhangs are defined by the vertical distance between the overhang and the top of the window (``DistanceToTopOfWindow``), and the vertical distance between the overhang and the bottom of the window (``DistanceToBottomOfWindow``).
The difference between these two values equals the height of the window.

Skylights
*********

TODO

Doors
*****

TODO

Systems
~~~~~~~

This section describes fields specified in HPXML's ``Systems``.

Heating Systems
***************

TODO

Cooling Systems
***************

TODO

Heat Pumps
**********

TODO

Thermostat
**********

TODO

Ducts
*****

TODO

Mechanical Ventilation
**********************

TODO

Water Heating
*************

TODO

Photovoltaics
*************

TODO

Appliances
~~~~~~~~~~

This section describes fields specified in HPXML's ``Appliances``.
Many of the appliances' inputs are derived from EnergyGuide labels.

The ``Location`` for clothes washers, clothes dryers, and refrigerators can be provided, while dishwashers and cooking ranges are assumed to be in the living space.

Clothes Washer
**************

An ``Appliances/ClothesWasher`` element must be specified.
The efficiency of the clothes washer can either be entered as a ``ModifiedEnergyFactor`` or an ``IntegratedModifiedEnergyFactor``.
Several other inputs from the EnergyGuide label must be provided as well.

Clothes Dryer
*************

An ``Appliances/ClothesDryer`` element must be specified.
The dryer's ``FuelType`` and ``ControlType`` ("timer" or "moisture") must be provided.
The efficiency of the clothes dryer can either be entered as an ``EnergyFactor`` or ``CombinedEnergyFactor``.


Dishwasher
**********

An ``Appliances/Dishwasher`` element must be specified.
The dishwasher's ``PlaceSettingCapacity`` must be provided.
The efficiency of the dishwasher can either be entered as an ``EnergyFactor`` or ``RatedAnnualkWh``.

Refrigerator
************

An ``Appliances/Refrigerator`` element must be specified.
The efficiency of the refrigerator must be entered as ``RatedAnnualkWh``.

Cooking Range/Oven
******************

``Appliances/CookingRange`` and ``Appliances/Oven`` elements must be specified.
The ``FuelType`` of the range and whether it ``IsInduction``, as well as whether the oven ``IsConvection``, must be provided.

Lighting
~~~~~~~~

TODO

Ceiling Fans
~~~~~~~~~~~~

TODO

Validating & Debugging Errors
-----------------------------

TODO

Example Files
-------------

TODO

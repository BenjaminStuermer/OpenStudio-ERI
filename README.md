Residential OpenStudio Measures
===============

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-BEopt.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-BEopt)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-Beopt/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-Beopt?branch=master)

This project includes OpenStudio measures used to model residential buildings.

This project is a <b>work-in-progress</b>. The models are not fully completed nor tested. These measures will eventually be posted on the [Building Component Library](https://bcl.nrel.gov/)

Progress is tracked in this [spreadsheet](https://docs.google.com/spreadsheets/d/1vIwgJtkB-sCFCV2Tnp1OqnjXgA9vTaxtWXw0gpq_Lc4).

## Setup for Developers

See the [wiki page](https://github.com/NREL/OpenStudio-BEopt/wiki/Setup-for-Developers) for getting setup as a developer.

## New Construction Workflow for Users

The New Construction workflow illustrates how to build up a complete residential building model from an [empty seed model](https://github.com/NREL/OpenStudio-BEopt/blob/master/seeds/EmptySeedModel.osm). Note that some measures need to be called before others. For example, the Window Constructions measure must be called after windows have been added to the building. The list below documents the intended workflow for using these measures.

<nowiki>*</nowiki> Note: Nearly every measure is dependent on having the geometry defined first so this is not included in the table for readability purposes.

|Group|Measure|Dependencies*|
|:---|:---|:---|
|1. Location|1. Location| |
|2. Geometry|1. Geometry Single-Family Detached (or Single-Family Attached or Multifamily)| |
| |2. Number of Beds and Baths| |
| |3. Number of Occupants|Beds/Baths|
| |4. Orientation| |
| |5. Eaves| |
| |6. Door Area| |
| |7. Window Areas| |
| |8. Overhangs|Window Areas|
| |9. Neighbors| |
|3. Envelope Constructions|1. Ceilings/Roofs - Unfinished Attic Constructions (or Finished Roof)| |
| |2. Ceilings/Roofs - Roof Sheathing| |
| |3. Ceilings/Roofs - Roofing Material| |
| |4. Ceilings/Roofs - Radiant Barrier| |
| |5. Ceilings/Roofs - Ceiling Thermal Mass| |
| |6. Foundations/Floors - Unfinished Basement Construction (or Finished Basement, Crawlspace, Slab, or Pier & Beam)| |
| |7. Foundations/Floors - Interzonal Floor Construction| |
| |8. Foundations/Floors - Floor Covering| |
| |9. Foundations/Floors - Floor Sheathing| |
| |10. Foundations/Floors - Floor Thermal Mass| |
| |11. Walls - Wood Stud Construction (or Double Stud, CMU, etc.)| |
| |12. Walls - Interzonal Construction| |
| |13. Walls - Wall Sheathing| |
| |14. Walls - Exterior Finish| |
| |15. Walls - Exterior Thermal Mass| |
| |16. Walls - Partition Thermal Mass| |
| |17. Uninsulated Surfaces| |
| |18. Window Construction|Window Areas, Location|
| |19. Door Construction|Door Area|
| |20. Furniture Thermal Mass| |
|4. Domestic Hot Water|1. Water Heater (Electric Tank, Fuel Tankless, etc.)|Beds/Baths|
| |2. Hot Water Fixtures|Water Heater|
| |3. Hot Water Distribution|Hot Water Fixtures, Location|
|5. HVAC|1. Central Air Conditioner and Furnace (or ASHP, Boiler, MSHP, etc.)| |
| |2. Heating Setpoint|HVAC Equipment, Location|
| |3. Cooling Setpoint|HVAC Equipment, Location|
| |4. Ceiling Fan|Cooling Setpoint, Beds/Baths|
|6. Major Appliances|1. Refrigerator| |
| |2. Clothes Washer|Water Heater, Location|
| |3. Clothes Dryer (Electric or Fuel)|Beds/Baths, Clothes Washer|
| |4. Dishwasher|Water Heater, Location|
| |5. Cooking Range (Electric or Fuel)|Beds/Baths|
|7. Lighting|1. Lighting|Location|
|8. Misc Loads|1. Plug Loads|Beds/Baths|
| |2. Extra Refrigerator| |
| |3. Freezer| |
| |4. Hot Tub Heater (Electric or Gas)|Beds/Baths|
| |5. Hot Tub Pump|Beds/Baths|
| |6. Pool Heater (Electric or Gas)|Beds/Baths|
| |7. Pool Pump|Beds/Baths|
| |8. Well Pump|Beds/Baths|
| |9. Gas Fireplace|Beds/Baths|
| |10. Gas Grill|Beds/Baths|
| |11. Gas Lighting|Beds/Baths|
|9. Airflow|1. Airflow|Location, Beds/Baths, HVAC Equipment, Clothes Dryer|
|10. Renewables|1. Photovoltaics|Location|
|11. Sizing|1. HVAC Sizing|(lots of measures...)|

## Retrofit Workflow for Users

Most of these measures were written to be reusable for existing building retrofits. The intended workflow is to create the existing building from an empty seed model in the same way as the [New Construction Workflow](#new-construction-workflow-for-users). Once the existing building model has been created, the same measures can now be used to replace/modify building components as appropriate. 

For example, while the dishwasher measure added a dishwasher to the model when applied to an empty seed model, the same measure, when applied to the existing building model, will replace the existing dishwasher with the newly specified dishwasher (rather than add an additional dishwasher to the model). This example could be used to evaluate an EnergyStar dishwasher replacement, for example. Alternatively, if the existing building was never assigned a dishwasher, then the measure would indeed add a dishwasher to the model.

Note that some measures are dependent on others. For example, if the Clothes Washer measure were to be applied to the existing building model, such that the existing clothes washer is replaced, the Clothes Dryer measure would also need to be subsequently applied to the existing building model so that its energy use, as dependent on the clothes washer, is correct.

.. _outputs:

Outputs
=======

Upon completion of the ERI calculation, summary output files and simulation files are available.
See the `sample_results <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results>`_ directory for examples of these outputs.

Summary Files
-------------

Several summary files described below are found in the ``results`` directory.

ERI_Results.csv
~~~~~~~~~~~~~~~

The ``ERI_Results.csv`` file includes the ERI result as well as the high-level components (e.g., REUL, EC_r, EC_x, IAD_Save) that comprise the ERI calculation.
The file reflects the format of the Results tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

See the `example ERI_Results.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERI_Results.csv>`_.

ERI_Worksheet.csv
~~~~~~~~~~~~~~~~~

The ``ERI_Worksheet.csv`` file includes more detailed components that feed into the ERI_Results.csv values.
The file reflects the formate of the Worksheet tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

See the `example ERI_Worksheet.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERI_Worksheet.csv>`_.

ERI______Home.csv
~~~~~~~~~~~~~~~~~

A CSV file is written for each of the homes simulated (e.g., ``ERIReferenceHome.csv`` for the Reference home).
The CSV file includes multiple sections with different outputs.

1. At the top of the file are **total annual consumption values for each fuel type** as well as an ``Electricity: Net`` field that incorporates any renewable generation.

2. The next section includes **annual energy consumption values for each fuel type and end use**.
   Current fuel types are ``Electricity``, ``Natural Gas``, and ``Other Fuel`` (oil, propane, etc.).
   Current end uses are ``Heating``, ``Cooling``, ``Hot Water``, ``Hot Water Recirc Pump``, ``Lighting Interior``, ``Lighting Garage``, ``Lighting Exterior``, ``Mech Vent``, ``Refrigerator``, ``Dishwasher``, ``Clothes Washer``, ``Clothes Dryer``, ``Range/Oven``, ``Ceiling Fan``, ``Plug Loads``, and ``PV`` (negative value for generation).

3. The third section in the CSV includes the **annual building loads** for heating, cooling, and hot water.
   Heating and cooling loads include duct losses.
   Hot water loads are disaggregated into 1) Delivered (i.e., the load associated with the delivered hot water by the water heater), 2) Tank Losses, and 3) Desuperheater.

4. The fourth section in the CSV includes **unmet annual building loads** for heating and cooling.
   These numbers reflect the amount of heating/cooling load that is not met by the HVAC system, indicating the degree to which the HVAC system is undersized.
   An HVAC system with sufficient capacity to perfectly maintain the thermostat setpoints will report an unmet load of zero.

5. The fifth section in the CSV includes **total building peak electricity** in Watts for the summer and winter seasons.
   The summer season is defined by the hours of the year when the cooling system is operating, and the winter season is defined by the hours of the year when the heating system is operating.

6. The sixth section in the CSV includes **total building peak loads** in Watts for heating and cooling.
   Heating and cooling peak loads include duct losses.
   
7. The seventh section in the CSV includes **component building loads**.
   Component loads represent the estimated contribution of different building components (e.g., walls, windows, infiltration, ducts, internal gains, etc.) to the annual heating/cooling building load.
   The sum of component loads for heating (or cooling) will roughly equal the annual heating (or cooling) building load reported above.
   

See the `example ERIRatedHome.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERIRatedHome.csv>`_.

ERI______Home_Hourly.csv
~~~~~~~~~~~~~~~~~~~~~~~~

If the ``--hourly-output`` argument is provided when running the workflow, a CSV file of hourly outputs is written for each of the homes simulated (e.g., ``ERIReferenceHome_Hourly.csv`` for the Reference home).

The hourly output CSV files currently include:

- Average space temperatures (in deg-F) for each space modeled (e.g., living space, vented attic, garage, unconditioned basement, crawlspace, etc.).
- Whole-building site energy use for each fuel type (in kBtu for fossil fuels and kWh for electricity).

See the `example ERIRatedHome_Hourly.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERIRatedHome_Hourly.csv>`_.

ERI______Home.xml
~~~~~~~~~~~~~~~~~

A HPXML file is written for each of the homes simulated (e.g., ``ERIReferenceHome.xml`` for the Reference home).
The file reflects the configuration of the home after applying the ERI 301 ruleset.

See the `example ERIRatedHome.xml <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERIRatedHome.xml>`_.

Simulation Files
----------------

In addition, raw EnergyPlus simulation input/output files are available for each simulation (e.g., ``ERIRatedHome``, ``ERIReferenceHome``, etc. directories).

.. warning:: 

  It is highly discouraged for software tools to read the raw EnergyPlus output files. 
  The EnergyPlus input/output files are made available for inspection, but the outputs for certain situations can be misleading if one does not know how the model was created. 
  If there are additional outputs of interest that are not available in our summary output files, please send us a request.

See the `example ERIRatedHome directory <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/ERIRatedHome>`_.

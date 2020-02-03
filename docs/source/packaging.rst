Packaging
=========

The OpenStudio-ERI workflow is cross-platform and can be used in web or desktop applications.

Web Applications
----------------

Using the OpenStudio-ERI workflow in a web application is very straightforward.

First, OpenStudio must be available.
Web applications may wish to use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
Alternatively, the OpenStudio installer can be executed on the web server -- only the EnergyPlus and Command Line Interface (CLI) components are required.

Then grab the latest `OpenStudio-ERI release <https://github.com/NREL/OpenStudio-ERI/releases>`_.

Desktop Applications
--------------------

The OpenStudio-ERI workflow can also be packaged into a third-party software installer for distribution to desktop users.

First, OpenStudio must be bundled -- only the EnergyPlus and Command Line Interface (CLI) components are required.
Either the OpenStudio setup file can be automatically run as part of your install, or the OpenStudio application can be installed to a local computer and its contents can be re-bundled in your installer (there are no external dependencies required).
The only required OpenStudio contents are the ``openstudio/bin`` and ``openstudio/EnergyPlus`` directories.

Then grab the latest `OpenStudio-ERI release <https://github.com/NREL/OpenStudio-ERI/releases>`_.
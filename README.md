# Headway

Headway is a maps stack in a box, allowing you to run, for example, `make Amsterdam` then `docker-compose up` to bring up a fully functional maps stack for the Amsterdam metro area including a frontend, basemap, geocoder and routing engine. Over 200 different cities are currently supported.

See BUILD.md for more information about the build process.

### Status

Headway is currently capable of showing a map, searching for points of interest and addresses within an OpenStreetMap extract and providing directions between any two places within that extract. Currently it is capable of providing directions for driving, cycling and walking, but transit directions are a work in progress.

The project is missing a kubernetes config for production use. Contributions for productionization are very welcome! Please open an issue to discuss first though.

### System Requirements

The machine used for generation of the data files needs to have at least 8GB of memory, potentially more for larger areas. We also recommend at least 50GB of free disk space, even if the OpenStreetMap extract for the area of interest is much smaller than that. Plan ahead to avoid disk pressure.

### License

Headway is available freely under the terms of the Apache License, verion 2.0. Please consider opening a PR for any enhancements or bugfixes!

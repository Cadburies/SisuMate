title: GRIB download, import and parsing
desc: Free NOAA GFS wind/wave GRIB downloads for an area, Saildocs email queries for slow links, importing GRIB files, and parsing them for the viewer.
layer: network
keywords: grib, gfs, noaa, saildocs, download, import, parse
kind: service
looks: -
reach: Free GRIB download screen, GRIB viewer import, passage planner "Download free GRIBs"
needs: network=online
action: Builds the area request, downloads or composes the Saildocs email, parses GRIB grids for display offline.
expect: A downloaded or imported GRIB opens in the viewer.
uses: -
script: test/grib_parser_service_test.dart
source: lib/services/grib_download_service.dart (GribDownloadService, GribBBox); lib/services/grib_import_service.dart (GribImportService); lib/services/grib_parser_service.dart (GribGrid); lib/services/saildocs_query_service.dart (SaildocsQueryParams)

# DREIMT Database Processing

This repository contains a Compi pipeline to create the DREIMT database from the source files. 

A file with the available database versions is available at `http://static.sing-group.org/software/dreimt/database/sources/database-versions.txt`, indicating the name of the current version. ZIP files for each database version containing the source database files are available at `http://static.sing-group.org/software/dreimt/database/sources/<dbVersion.zip>`.

Each database version is available at a ZIP file (e.g. `v20190612.zip`), containing four folders: `Database`, `Inputs`, `Intermediate` and `Precalculated` (which, at the same time, can contain `signatures` and `genesets`).

The processing scripts are provided in the `scripts` directory, which also contains a complete README file with detailed documentation about these scripts and other technical details about the database.

# 1. Prerequisites to run the pipeline

Before running the pipeline, clone the [DREIMT Utils](https://github.com/sing-group/dreimt-utils) and [DREIMT backend](https://github.com/sing-group/dreimt-backend) projects. The paths to these projects are required to run the pipeline.

# 2. Running the Compi pipeline

Use the following command to run the `pipeline.xml` file with Compi (v1.3.0 or higher), indicating the path to a params file for the database to be created:

```bash
compi run -pa /path/to/params -o -r runner.xml 
```

An example of a params file is:
```
workingDirectory=/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/20200516/
dreimtUtilsPath=/home/hlfernandez/Investigacion/Desarrollos/Git/cnio/dreimt-utils/
dbZipName=v20200516.zip
dreimtDatabaseScriptsPath=/home/hlfernandez/Investigacion/Desarrollos/Git/cnio/dreimt-database/scripts
tauThreshold=80
dbVersionsDirectory=/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/
backendProjectPath=/home/hlfernandez/Investigacion/Desarrollos/Git/backends/dreimt-backend/
```

Where:
- The `workingDirectory` is where the file with name `dbZipName` will be downloaded (from `sftp://static.sing-group.org/home/hlfernandez/ftp_static/software/dreimt/database/sources/`) and uncompressed.
- The `dreimtUtilsPath` parameter specifies the location of the [DREIMT Utils project](https://github.com/sing-group/dreimt-utils).
- The `dreimtDatabaseScriptsPath` parameter specifies the path to this project (i.e. the directory where the `pipeline.xml` file is located).
- The `tauThreshold` specifies the TAU theshold used to filter the drug associations that will be included in the database. Only those associations with a |TAU| > `tauThreshold` will be used to populate the database.
- The `dbVersionsDirectory` is an optional parameter that specifies the location of the `dbVersionsFile` (whose default value is `database-versions.txt`). If not provided, this file will be automatically downloaded from `http://static.sing-group.org/software/dreimt/database/sources/database-versions.txt`.
- The `backendProjectPath` specifies the location of the [DREIMT backend project](https://github.com/sing-group/dreimt-backend).

# 3. Optional pipeline tasks

## 3.1 Upload the SQL files to the SING static server

```bash
compi run -pa /path/to/params -o -r runner.xml --single-task task-2-13-upload-sql -- --singUserName <your_SING_static_username>
```

## 3.2 Create the backend development database

```bash
compi run -pa /path/to/params -o --single-task task-3-development-database -- --developmentPrecalculatedExamples /path/to/Precalculated
```

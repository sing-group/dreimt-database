# 1. Running the compi pipeline

Use the following command to run the `pipeline.xml` file with compi, indicating the path to a params file for the database to be created:

```bash
compi run -pa /path/to/params -o -r runner.xml 
```

An example of a params file is:
```
workingDirectory=/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/20200516/
dreimtUtilsPath=/home/hlfernandez/Investigacion/Desarrollos/Git/cnio/dreimt-utils/
dbZipName=v20200516.zip
dreimtDatabaseScriptsPath=/home/hlfernandez/Investigacion/Desarrollos/Git/cnio/dreimt-database/
tauThreshold=80
dbVersionsDirectory=/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/
backendProjectPath=/home/hlfernandez/Investigacion/Desarrollos/Git/backends/dreimt-backend/
```

The `workingDirectory` is where the file with name `dbZipName` will be downloaded (from `sftp://static.sing-group.org/home/hlfernandez/ftp_static/software/dreimt/database/sources/`) and uncompressed. The `dreimtDatabaseScriptsPath` parameter specifies the parent location of this file and `dreimtUtilsPath` the location of the [Dreimt Utils project](https://dev.sing-group.org/gitlab/dreimt/dreimt-utils).

# 2. Optional pipeline tasks

## 2.1 Upload the SQL files to the SING static server

```bash
compi run -pa /path/to/params -o -r runner.xml --single-task task-2-13-upload-sql -- --singUserName <your_SING_static_username>
```

## 2.2 Create the backend development database

```bash
compi run -pa /path/to/params -o --single-task task-3-development-database -- --developmentPrecalculatedExamples /path/to/Precalculated
```

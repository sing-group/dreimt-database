# Running the compi pipeline

Use the following command to run the `pipeline.xml` file with compi, indicating the path to a params file for the database to be created:

```bash
compi run -pa /path/to/params -o -r runner.xml 
```

An example of a params file is:
```
workingDirectory=/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/20190612
dbZipName=v20190612.zip
dreimtUtilsPath=/home/hlfernandez/Investigacion/Desarrollos/Git/cnio/dreimt-utils/
dreimtDatabaseScriptsPath=/home/hlfernandez/Investigacion/Desarrollos/Git/cnio/dreimt-database/
```

The `workingDirectory` is where the file with name `dbZipName` will be downloaded (from `sftp://static.sing-group.org/home/hlfernandez/ftp_static/software/dreimt/database/sources/`) and uncompressed. The `dreimtDatabaseScriptsPath` parameter specifies the parent location of this file and `dreimtUtilsPath` the location of the [Dreimt Utils project](https://dev.sing-group.org/gitlab/dreimt/dreimt-utils).

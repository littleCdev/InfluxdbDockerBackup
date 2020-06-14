# InfluxdbDockerBackup
a simple bash script to backup specified or all databases from a influxdbserver 

use 
```bash 
BACKUP_ALL=true 
DATABASES_TO_EXCLUDE=("_config"); 
DATABASES_TO_BACKUP=(); 
``` 
to back up all databases, excluding _config

use 
```bash 
BACKUP_ALL=false 
DATABASES_TO_EXCLUDE=("_config"); 
DATABASES_TO_BACKUP=("mydatabase"); 
```
to backup only the specified "mydatabase"

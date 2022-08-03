#!/bin/sh
cd /data

S3_LOAD_DIR="/tmp/toLoadS3"

# Move clean-logs file
mv /virtuoso/clean-logs.sh /data/clean-logs.sh 2>/dev/null
chmod +x /data/clean-logs.sh
mkdir -p /data/dumps

# Create ini file, and convert env to ini entries
echo "Creating virtuoso.ini file..."
mv /virtuoso/virtuoso.ini /data/virtuoso.ini 2>/dev/null
echo "Converting environment variables to ini file..."
printenv | egrep "^VIRT_" | while read setting
do
  section=`echo "$setting" | egrep -o "^VIRT_[^_]+" | sed 's/^.\{5\}//g'`
  key=`echo "$setting" | egrep -o "_[^_]+=" | sed 's/[_=]//g'`
  value=`echo "$setting" | egrep -o "=.*$" | sed 's/^=//g'`
  echo "Registering $section[$key] to be $value"
  crudini --set /data/virtuoso.ini "$section" "$key" "$value"
done

# Create alternate config file for running virtuoso on another http port
# during data loading (if WAIT_LOADING_DATA is true)
cp /data/virtuoso.ini /tmp/virtuoso-dummy-http-port.ini
crudini --set /tmp/virtuoso-dummy-http-port.ini "HTTPServer" "ServerPort" "7000"
if [ "$WAIT_LOADING_DATA" = "true" ]; then CONFIG_FILE="/tmp/virtuoso-dummy-http-port.ini"; else CONFIG_FILE="/data/virtuoso.ini"; fi
echo "Use $CONFIG_FILE to configure and load data"


# Set dba password
touch /sql-query.sql
echo "Updating dba password and sparql update..."
if [ "$DBA_PASSWORD" ]; then echo "user_set_password('dba', '$DBA_PASSWORD');" >> /sql-query.sql ; fi
if [ "$SPARQL_UPDATE" = "true" ]; then echo 'GRANT SPARQL_UPDATE to "SPARQL";' >> /sql-query.sql ; fi
if [ "$SPARQL_UPDATE" = "true" ]; then echo 'GRANT execute on "DB.DBA.L_O_LOOK_NE" to "SPARQL";' >> /sql-query.sql ; fi
virtuoso-t +configfile ${CONFIG_FILE} +wait && isql-v -U dba -P dba < /virtuoso/dump_nquads_procedure.sql && isql-v -U dba -P dba < /sql-query.sql
kill $(ps ax | egrep '[v]irtuoso-t' | awk '{print $1}')

# Make sure killing is done
sleep 2


# Mount S3FS
if [ "$S3_SERVER_URL" ];
then
    mkdir -p $S3_LOAD_DIR

    # connect to S3 bucket
    echo "$S3_ACCESS_KEY_ID:$S3_SECRET_ACCESS_KEY" > /tmp/.passwd-s3fs
    chmod 600 /tmp/.passwd-s3fs
    s3fs ${S3_BUCKET_NAME} $S3_LOAD_DIR -o passwd_file=/tmp/.passwd-s3fs -o url=${S3_SERVER_URL} -o use_path_request_style -o allow_other
fi


# Load data
if [ -d "toLoad" ] || [ -d $S3_LOAD_DIR ] ;
then
    echo "Start data loading from toLoad/toLoadS3 folder..."
    echo `date +%Y-%m-%dT%H:%M:%S%:z` > .data_loaded_start
    pwd="dba"
    graph="http://localhost:8890/DAV"
    if [ "$DBA_PASSWORD" ]; then pwd="$DBA_PASSWORD" ; fi
    if [ "$DEFAULT_GRAPH" ]; then graph="$DEFAULT_GRAPH" ; fi
    if [ -d "toLoad" ]; then echo "ld_dir_all('toLoad', '*', '$graph');" >> /load_data.sql ; fi
    if [ -d $S3_LOAD_DIR ]; then echo "ld_dir_all('$S3_LOAD_DIR', '*', '$graph');" >> /load_data.sql ; fi
    echo "rdf_loader_run();" >> /load_data.sql
    echo "exec('checkpoint');" >> /load_data.sql
    echo "WAIT_FOR_CHILDREN; " >> /load_data.sql
    echo "$(cat /load_data.sql)"
    virtuoso-t +configfile ${CONFIG_FILE} +wait && isql-v -U dba -P "$pwd" < /load_data.sql
    kill $(ps ax | egrep '[v]irtuoso-t' | awk '{print $1}')
    echo "Data loaded!"
    echo `date +%Y-%m-%dT%H:%M:%S%:z` > .data_loaded_end
fi

# umount S3FS volume
if [ -d $S3_LOAD_DIR ] ;
then
    echo "Unmount ${S3_LOAD_DIR}"
    umount $S3_LOAD_DIR
    rm -r /tmp/.passwd-s3fs $S3_LOAD_DIR
fi

echo "Running virtuoso"
exec virtuoso-t +wait +foreground

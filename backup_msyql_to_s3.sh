#!/bin/sh
TMP_PATH=/tmp/
DATESTAMP=$(date +".%Y.%m.%d")

# change these variables to what you need
S3BUCKET=mysql-daily-exports

MYSQLHOST=localhost
MYSQLROOT=root
MYSQLPASS=password

# create list of databases to be individually exported
DATABASES=`echo "show databases;" | mysql -h $MYSQLHOST -u $MYSQLROOT -p$MYSQLPASS`
#abs and abs_prod are magento dbs! ignore!
SKIPDBS=(Database information_schema performance_schema)
for DB in $DATABASES
do
  if ! [[ ${SKIPDBS[*]} =~ $DB ]]
    then
      echo "Backing up: $DB"
      # Create FILENAME, ALIAS is from the RDS hostname/alias
      ALIAS=$(echo $MYSQLHOST | cut -d. -f1)
      FILENAME=${ALIAS}_${DB}
      # Export database and compress
      mysqldump --quick -h $MYSQLHOST -u $MYSQLROOT -p$MYSQLPASS $DB > ${TMP_PATH}${FILENAME}.sql
      tar czf ${TMP_PATH}${FILENAME}.tar.gz ${TMP_PATH}${FILENAME}.sql
      # Transfer to S3
      s3cmd put -f ${TMP_PATH}${FILENAME}.tar.gz s3://${S3BUCKET}/
      # Cleanup tmp files
      rm ${TMP_PATH}${FILENAME}.sql
      rm ${TMP_PATH}${FILENAME}.tar.gz
  fi
done
#!/bin/bash

chown -R root:www-data /app
chmod -R 650 /app
chmod -R 770 /app/wp-content/
chmod -R 660 /app/.htaccess
chmod    660 /app/wp-config.php

DB_HOST=${DB_PORT_3306_TCP_ADDR:-${DB_HOST}}
DB_HOST=${DB_1_PORT_3306_TCP_ADDR:-${DB_HOST}}
DB_PORT=${DB_PORT_3306_TCP_PORT:-${DB_PORT}}
DB_PORT=${DB_1_PORT_3306_TCP_PORT:-${DB_PORT}}

DATA_DB_NAME=${DATA_ENV_DATA_DB_NAME:-$DATA_DB_NAME}
DATA_DB_USER=${DATA_ENV_DATA_DB_USER:-$DATA_DB_USER}
DATA_DB_PASS=${DATA_ENV_DATA_DB_PASS:-$DATA_DB_PASS}

if [ "$DATA_DB_PASS" = "**ChangeMe**" ] && [ -n "$DB_1_ENV_MYSQL_PASS" ]; then
    DATA_DB_PASS="$DB_1_ENV_MYSQL_PASS"
fi

echo "=> Using the following MySQL/MariaDB configuration:"
echo "========================================================================"
echo "      Database Host Address:  $DB_HOST"
echo "      Database Port number:   $DB_PORT"
echo "      Database Name:          $DATA_DB_NAME"
echo "      Database Username:      $DATA_DB_USER"
echo "========================================================================"

if [ -f /.mysql_db_created ]; then
        exec /run.sh
        exit 1
fi

for ((i=0;i<10;i++))
do
    DB_CONNECTABLE=$(mysql -u$DATA_DB_USER -p$DATA_DB_PASS -h$DB_HOST -P$DB_PORT -e 'status' >/dev/null 2>&1; echo "$?")
    if [[ DB_CONNECTABLE -eq 0 ]]; then
        break
    fi
    sleep 5
done

if [[ $DB_CONNECTABLE -eq 0 ]]; then
    DB_EXISTS=$(mysql -u$DATA_DB_USER -p$DATA_DB_PASS -h$DB_HOST -P$DB_PORT -e "SHOW DATABASES LIKE '"$DATA_DB_NAME"';" 2>&1 |grep "$DATA_DB_NAME" > /dev/null ; echo "$?")

    if [[ DB_EXISTS -eq 1 ]]; then
        echo "=> Creating database $DATA_DB_NAME"
        RET=$(mysql -u$DATA_DB_USER -p$DATA_DB_PASS -h$DB_HOST -P$DB_PORT -e "CREATE DATABASE $DATA_DB_NAME")
        if [[ RET -ne 0 ]]; then
            echo "Cannot create database for wordpress"
            exit RET
        fi
        if [ -f /initial_db.sql ]; then
            echo "=> Loading initial database data to $DATA_DB_NAME"
            RET=$(mysql -u$DATA_DB_USER -p$DATA_DB_PASS -h$DB_HOST -P$DB_PORT $DATA_DB_NAME < /initial_db.sql)
            if [[ RET -ne 0 ]]; then
                echo "Cannot load initial database data for wordpress"
                exit RET
            fi
        fi
        echo "=> Done!"    
    else
        echo "=> Skipped creation of database $DATA_DB_NAME – it already exists."
    fi
else
    echo "Cannot connect to Mysql"
    exit $DB_CONNECTABLE
fi

touch /.mysql_db_created
exec /run.sh

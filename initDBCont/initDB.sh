#!/bin/sh
cd /initDB
mysql --user root --password='verysecretpassword' < employees.sql

#!/bin/sh
cd /initDB
mysql -u root -pverysecretpassword < employees.sql

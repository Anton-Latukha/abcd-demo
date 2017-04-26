# Data container to initialize DB
## (Can be removed after initialization process)
##
## As all in '/docker-entrypoint-initdb.d' going to be executed, we can't dump DB test suite there.
## We create a main entrance file 'initDB.sh' that triggers needed SQL initialization

FROM tianon/true
COPY ./initDB /initDB
COPY ./initDB.sh /docker-entrypoint-initdb.d/
#COPY ./processDB.sh /docker-entrypoint-initdb.d/

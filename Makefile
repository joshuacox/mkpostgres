.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container


# run a  container that requires postgresql temporarily
temp: POSTGRES_PASS NAME rm postgresqltemp

# import
import: NAME POSTGRES_PASS postgresqlimport

# run a  container that requires postgresql in production with persistent data
# HINT: use the grab recipe to grab the data directory automatically from the below postgresqltemp
prod: NAME POSTGRES_DATADIR POSTGRES_PASS rm postgresqlcid

# This one is ephemeral and will not persist data
postgresqltemp:
	docker run \
	--cidfile="postgresqltemp" \
	--name `cat NAME`-postgresqltemp \
	-e POSTGRES_ROOT_PASSWORD=`cat POSTGRES_PASS` \
	-d \
	postgres:9

# This one will import a sql file 
postgresqlimport:
	docker run \
	--cidfile="postgresqltemp" \
	--name `cat NAME`-postgresqltemp \
	-e postgresql_ROOT_PASSWORD=`cat postgresql_PASS` \
	-v ./docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d \
	-d \
	postgres:9

# This is the production block and will use the persistent data
postgresqlcid:
	$(eval POSTGRES_DATADIR := $(shell cat POSTGRES_DATADIR))
	docker run \
	--cidfile="postgresqlcid" \
	--name `cat NAME`-postgresql \
	-e POSTGRES_ROOT_PASSWORD=`cat POSTGRES_PASS` \
	-d \
	-v $(POSTGRES_DATADIR):/var/lib/postgresql \
	postgres:9

kill:
	-@docker kill `cat postgresqlcid`

rm-image:
	-@docker rm `cat postgresqlcid`
	-@rm postgresqlcid

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat postgresqlcid` /bin/bash

logs:
	docker logs -f `cat postgresqlcid`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

# POSTGRES additions
# use these to generate a postgresql container that may or may not be persistent

rmpostgresql: postgresqlcid-rmkill

postgresqlcid-rmkill:
	-@docker kill `cat postgresqlcid`
	-@docker rm `cat postgresqlcid`
	-@rm postgresqlcid

rmpostgresqltemp: postgresqltemp-rmkill

postgresqltemp-rmkill:
	-@docker kill `cat postgresqltemp`
	-@docker rm `cat postgresqltemp`
	-@rm postgresqltemp

rmall: rm rmpostgresqltemp rmpostgresql

grab: grabpostgresqldatadir

grabpostgresqldatadir:
	-mkdir -p datadir
	docker cp `cat postgresqltemp`:/var/lib/postgresql  - |sudo tar -C datadir/ -pxvf -
	echo `pwd`/datadir/postgresql > POSTGRES_DATADIR

POSTGRES_DATADIR:
	@while [ -z "$$POSTGRES_DATADIR" ]; do \
		read -r -p "Enter the destination of the postgresql data directory you wish to associate with this container [POSTGRES_DATADIR]: " POSTGRES_DATADIR; echo "$$POSTGRES_DATADIR">>POSTGRES_DATADIR; cat POSTGRES_DATADIR; \
	done ;

POSTGRES_PASS:
	@while [ -z "$$POSTGRES_PASS" ]; do \
		read -r -p "Enter the postgresql password you wish to associate with this container [POSTGRES_PASS]: " POSTGRES_PASS; echo "$$POSTGRES_PASS">>POSTGRES_PASS; cat POSTGRES_PASS; \
	done ;

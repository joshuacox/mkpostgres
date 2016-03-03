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
temp: POSTGRES_VERSION POSTGRES_USER POSTGRES_DB POSTGRES_PASSWORD NAME pull postgresqltemp

# import
import: POSTGRES_VERSION pull NAME POSTGRES_USER POSTGRES_DB POSTGRES_PASSWORD pull postgresqlimport

# run a  container that requires postgresql in production with persistent data
# HINT: use the grab recipe to grab the data directory automatically from the below postgresqltemp
prod: NAME POSTGRES_VERSION POSTGRES_DATADIR pull postgresqlcid

# This one is ephemeral and will not persist data
postgresqltemp:
	$(eval POSTGRES_VERSION := $(shell cat POSTGRES_VERSION))
	docker run \
	--cidfile="postgresqltemp" \
	--name `cat NAME`-postgresqltemp \
	-e POSTGRES_PASSWORD=`cat POSTGRES_PASSWORD` \
	-e POSTGRES_DB=`cat POSTGRES_DB` \
	-e POSTGRES_USER=`cat POSTGRES_USER` \
	-d \
	postgres:$(POSTGRES_VERSION)

# This one will import a sql file
postgresqlimport:
	$(eval POSTGRES_VERSION := $(shell cat POSTGRES_VERSION))
	docker run \
	--cidfile="postgresqltemp" \
	--name `cat NAME`-postgresqltemp \
	-e POSTGRES_PASSWORD=`cat POSTGRES_PASSWORD` \
	-e POSTGRES_DB=`cat POSTGRES_DB` \
	-e POSTGRES_USER=`cat POSTGRES_USER` \
	-v `pwd`/docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d \
	-d \
	postgres:$(POSTGRES_VERSION)

# This is the production block and will use the persistent data
postgresqlcid:
	$(eval POSTGRES_DATADIR := $(shell cat POSTGRES_DATADIR))
	$(eval POSTGRES_VERSION := $(shell cat POSTGRES_VERSION))
	docker run \
	--cidfile="postgresqlcid" \
	--name `cat NAME`-postgresql \
	-d \
	-v $(POSTGRES_DATADIR):/var/lib/postgresql \
	postgres:$(POSTGRES_VERSION)

pull:
	$(eval POSTGRES_VERSION := $(shell cat POSTGRES_VERSION))
	docker pull \
	postgres:$(POSTGRES_VERSION)
	date -I>pull

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

templogs:
	docker logs -f `cat postgresqltemp`

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

rmtemp: rmpostgresqltemp

rmall: rm rmpostgresqltemp rmpostgresql

grab: grabpostgresqldatadir

clean: rmall rmpull

rmpull:
	-@rm -f pull

grabpostgresqldatadir:
	-mkdir -p datadir
	docker cp `cat postgresqltemp`:/var/lib/postgresql  - |sudo tar -C datadir/ -pxvf -
	echo `pwd`/datadir/postgresql > POSTGRES_DATADIR

POSTGRES_DATADIR:
	@while [ -z "$$POSTGRES_DATADIR" ]; do \
		read -r -p "Enter the destination of the postgresql data directory you wish to associate with this container [POSTGRES_DATADIR]: " POSTGRES_DATADIR; echo "$$POSTGRES_DATADIR">>POSTGRES_DATADIR; cat POSTGRES_DATADIR; \
	done ;

POSTGRES_VERSION:
	@while [ -z "$$POSTGRES_VERSION" ]; do \
		read -r -p "Enter the version of the postgresql you wish to associate with this container, please see the official postgres docker image for available version tags [POSTGRES_VERSION]: " POSTGRES_VERSION; echo "$$POSTGRES_VERSION">>POSTGRES_VERSION; cat POSTGRES_VERSION; \
	done ;

POSTGRES_PASSWORD:
	@while [ -z "$$POSTGRES_PASSWORD" ]; do \
		read -r -p "Enter the postgresql password you wish to associate with this container [POSTGRES_PASSWORD]: " POSTGRES_PASSWORD; echo "$$POSTGRES_PASSWORD">>POSTGRES_PASSWORD; cat POSTGRES_PASSWORD; \
	done ;

POSTGRES_USER:
	@while [ -z "$$POSTGRES_USER" ]; do \
		read -r -p "Enter the postgresql user you wish to associate with this container [POSTGRES_USER]: " POSTGRES_USER; echo "$$POSTGRES_USER">>POSTGRES_USER; cat POSTGRES_USER; \
	done ;

POSTGRES_DB:
	@while [ -z "$$POSTGRES_DB" ]; do \
		read -r -p "Enter the postgresql db name you wish to associate with this container [POSTGRES_DB]: " POSTGRES_DB; echo "$$POSTGRES_DB">>POSTGRES_DB; cat POSTGRES_DB; \
	done ;

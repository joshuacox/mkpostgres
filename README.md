# mkpostgres
Make a persistent postgres container PDQ!


### Usage

#### Initialization or Temp use

`make temp` will make a temporary ephemeral fresh postgresql instance

`make templogs` to watch the postgresql process startup and initialize its databases

you now have a fresh postgres install to experiment with 
you can stop here and start playing with postgres IF you do not need persistent data

### Persisten Data

when the initialization of the temp container finishes (not before) you can then
`make grab` which will make a `datadir` in the current directory and copy out `/var/lib/postgresql` out
of the temporary container to be used in a persistent setup

at this point you can move the datadir wherever you so desire,
just be sure and update the `POSTGRES_DATADIR` file in this directory
as that is how the makefile knows where to mount from

#### Removal of the temp container

`make rmtemp` will clean up our temporary container, but will not delete the `datadir`

#### Production

We are now set to start our persistent database

`make prod` will then use the `datadir` and start up our container in persistent mode

#### Import

alternative to `make temp` is the `make import` which will mount docker-entrypoint-initdb.d into 
the container, at which point entry-point.sh will execute everything in there that ends in `.sh` or `.sql`

#### Restart

restart the container with `make rm` followed by `make prod`

#### Migration

to migrate simply tar up this directory along with the datadir and move to the new docker host

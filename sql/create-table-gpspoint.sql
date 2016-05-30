
DROP TABLE gpspoint;
CREATE TABLE gpspoint (
       id serial,
       timestamp timestamp with time zone,
       name varchar(64),
       lat float8,
       lon float8,
       epx float8,
       epy float8,
       epv float8,
       speed float8,
       heading int
)

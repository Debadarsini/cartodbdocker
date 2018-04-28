# cartodb-docker

This repo contains code for building cartodb docker image along with data analysis module.

Clone the repo and run below command to build docker container for cartodb 

  docker build -t carto .

Execute below command to start cartodb engine/sql api /windshaft and data analysis module

docker run -d -p 3000:3000 -p 8080:8080 -p 8181:8181 carto

Execute below command to create dns mapping

echo “127.0.0.1  development.localhost.lan" | sudo tee -a /etc/hosts

Then access cartodb dashboard at development.localhost.lan:3000.
Credentials for login are Development/pass1234.

By using following resp api a table can be created

http://development.localhost.lan:8080/api/v2/sql?q=create table testproperty (name text,type text)&api_key=xyz
Here query is : create table testproperty (name text)

Following api can be executed to cartofy the table created. With this api , the_geom column gets added to the table.

http://development.localhost.lan:8080/api/v2/sql?q=SELECT cdb_cartodbfytable('testproperty')&api_key=xyz

With following api geo cordinate/data can be added 

http://development.localhost.lan:8080/api/v2/sql?q=INSERT INTO testproperty(the_geom,name,type) VALUES (ST_SetSRID(ST_Point(-107.402437,36.684099),4326),'this is a random <a href="http://www.google.com">link</a>','red')&api_key=xyz

Once all the above done , testproperty can be seen from ui.

Sql api is authenticated using api_key , api key can be found from dashboard once installtion done.


To fill the internal geocoder run

docker exec -ti <carto docker container id> bash -c /cartodb/script/fill_geocoder.sh

This will run the scripts described at https://github.com/CartoDB/data-services/tree/master/geocoder
It will use at least 5.7+7.8Gb of diskspace to download the dumps and import them.


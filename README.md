<h1>What is this?</h1>

- A little script for fast-deploying mariaDB docker container with an option to restore the SQl dump with one command
- Might be useful for checking customer's database
- Script is also capable of deploying a tool called adminer. It is something like PhpMyAdmin but much better. Basically web interface GUI for database managing (http://adminer.org)

<h1>How to use it?</h1>

./db-ct.sh CT_NAME [OPTIONS]   <b>Note: Please stick to the syntax, the arg parsing here is not so smart :-)</b>

<b>There are following options:</b>


- --port         Local port to map to the database port inside the CT (default 6603)
- --dump         Optional path to the database dump file to restore
- --datadir      Local datadir folder to map to the one inside the CT (default \$HOME/mysql)
- --password     Mysql root password (default 123456)
- --adminer      Deploy a web interface container to manage the database
- --adminerport  Local port to map to the adminer port inside the CT (default 8080)
- --getip        Get local IP of the container based on its name in order to log into DB via adminer

<h1>Example</h1>

./db-ct.sh test-db-container --dump /path/to/dump.sql --password secretpass --adminer --port 1234 --datadir "~/mysql"

<h1>Notes</h1>

If you find any bugs or get any idea what/how to improve this, crete an issue. Thanks!

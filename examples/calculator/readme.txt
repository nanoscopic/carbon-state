To use the example you will need to update config.xml so that the web_request ip parameter is
set to the ip address of your mongrel2 server.

Also, you may need to update the 'base' setting in your config.xml so that it matches the directory you
are mapping in mongrel2 to point to zeromq.

Once you have updated those two settings, run 'perl web.pl'
You will then be able to reach the example at "http://[your server]/perl/calc"
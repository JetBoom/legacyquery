# legacyquery
GMod server browser code that uses the old master server protocol to return 100% of the servers rather than those limited to your geoip location. READ THE BELOW ITEMS AND BACKUP YOUR LUA/MENU FOLDER!

# REQUIREMENTS
You need GLSock2.

You can get it from https://code.google.com/p/mattmodules/source/browse/#svn%2Ftrunk%2Fgm_glsock%2FRelease

The binaries go in to garrysmod/lua/bin

# TODO: 
* Need to convert PHP script to Lua. The server list is actually from a php job so there's a high chance you're not even getting the updated server list.
* GLSock2 will probably need to be replaced due to occasional crashes I can't track down. bromsock is unstable. Try luasocket?
* Right now a socket is created for every request. I also tried a single socket for every request and both eventually stop working. Try making X worker sockets that can handle up to Y info requests at a time.
* Ping can be calculated by adding setting ["ip:port"] = CurTime() and doing the math.

# legacyquery
GMod server browser code that uses the old master server protocol to return 100% of the servers rather than those limited to your geoip location. READ THE BELOW ITEMS.

# TODO: 
* Need to convert PHP script to Lua. The server list is actually from a php job so there's a high chance you're not even getting the updated server list.
* GLSock2 will probably need to be replaced due to occasional crashes I can't track down.
* Rate limiting needs to be reworked because some people have their internet die (ex: DNS requests don't work) for a minute or two after querying for a while. This is also a problem with the Steam server browser as well so not a problem with my methods, I don't think.
* Ping is currently locked at 5 because for some reason assigning a StartTime member to the socket userdata causes crashes after a while.

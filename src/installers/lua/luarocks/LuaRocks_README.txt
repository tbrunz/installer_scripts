
LuaRocks - Package manager for the Lua programming language
================================================================================

LuaRocks allows you to install Lua modules as self-contained packages called 
"rocks", which also contain dependency information.  

LuaRocks supports both local and remote repositories, and multiple local rocks 
trees.

LuaRocks is free software and uses the same license as Lua.


Download and install LuaRocks on *nix and Windows:
https://github.com/keplerproject/luarocks/wiki/Installation-instructions-for-Unix

$ wget https://luarocks.org/releases/luarocks-X.Y.Z.tar.gz
$ tar zxpf luarocks-X.Y.Z.tar.gz
$ cd luarocks-X.Y.Z
$ ./configure; sudo make bootstrap
$ sudo luarocks install luasocket
$ lua
Lua 5.y.z Copyright (C) 1994-2018 Lua.org, PUC-Rio
> require "socket"

https://github.com/keplerproject/luarocks/wiki/Installation-instructions-for-Windows



Documentation is available from this wiki:
https://github.com/keplerproject/luarocks/wiki

Using LuaRocks:
https://github.com/keplerproject/luarocks/wiki/Using-LuaRocks


Links & info from the Lua users group:
http://lua-users.org/wiki/LuaRocks

The LuaRocks website:
https://luarocks.org/

Kepler Project version repository (for both *nix & Windows):
http://keplerproject.github.io/luarocks/releases



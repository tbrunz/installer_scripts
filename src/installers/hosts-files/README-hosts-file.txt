
Blocking Unwanted Parasites with a Hosts File
========================================================

Check this website monthly for updates:

http://www.mvps.org/winhelp2002/

http://www.mvps.org/winhelp2002/hosts.htm

-----

My strategy:

* Download just the hosts file for Linux use (or the zip for Windows use; you 
  can extract just the hosts file from the Windows zip file).

* Name the Windows hosts file something like "hosts-2010-0715.win".  Note that 
  this file uses the MSDOS style line terminations -- hence the extension.

* Use 'tofrodos' to convert the '.win' version to a Linux-style text document, 
  and name it something like "hosts-2010-0715" (no extension).

* Become root, then move the "hosts-2010-0715" file to '/etc', change its 
  ownership & permissions (root:root, 644), then copy it as "hosts-blocking".

* Edit "hosts-blocking" to do two things: 
  1) Remove the line "127.0.0.1  localhost" that appears just after the header 
     documentation, and 
  2) Copy the contents of your existing "/etc/hosts" file to the top of this 
     file.  (This will include the needed '127.0.0.1' line.)

* Rename "/etc/hosts" to "/etc/hosts-orig"; this file is your hosts file WITHOUT 
  any blocking effect -- you may need this for some problematic websites, so we 
  keep it around...

* Copy "/etc/hosts-blocking" to "/etc/hosts"; this file is your hosts file WITH 
  blocking.  Now we have four files:  The original Windows blocking file that 
  was downloaded, a version without blocking, a version with blocking, and a 
  version that's being applied.

* And, of course, this should be automated with a script.  :^)

-----

What this new hosts file does ...

The hosts file contains the mappings of IP addresses to host names.  This file 
is loaded into memory (cache) at startup; the OS checks the hosts file before 
it queries any DNS servers, which enables it to override addresses in the DNS.  
This prevents access to the listed sites by redirecting any connection attempts 
back to the local machine (which will not respond).  

Another feature of the hosts file is its ability to block applications from 
connecting to the Internet -- providing an entry it uses exists.  (Otherwise 
you'll need to set an entry in your firewall.)

You can use a hosts file to block ads, banners, pop-ups, 3rd-party cookies, 
3rd-party page counters, web bugs, spyware, malware, and most hijackers.  This 
is accomplished by blocking the connection(s) that supply these little gems.

For example, the entry "127.0.0.1 ad.doubleclick.net" blocks all files supplied 
by the DoubleClick server to the web page you are viewing.  This also prevents 
the server from tracking your movements.  Why? Because in certain cases, "ad 
servers" such as Doubleclick (and many others) will try silently to open a 
separate connection on the webpage you are viewing, record your movements, then 
(yes) follow you to additional sites you may visit.

In many cases, using a well-designed hosts file can speed the loading of web 
pages by not having to wait for these ads, annoying banners, hit counters, etc. 
to load along with the web page contents.  This also helps to protect your 
privacy and security by blocking sites that may track your viewing habits, also 
known as "click-thru trackers" or "data miners".  Simply using a hosts file is 
not a cure-all against all the dangers on the Internet, but it does provide 
another very effective "layer of protection".

-----


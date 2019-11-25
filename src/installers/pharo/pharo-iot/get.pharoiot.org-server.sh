#!/usr/bin/env bash
#<html><head><!--
# The line above makes a fake HTML document out of this bash script

# Getting pharoiot-server.zip This file has Pharo7, ARM VM and Pharo IoT server loaded;

wget get.pharoiot.org/server.zip
unzip server.zip 

# HTML HELP =====================================================================
HTML_HELP=<<HTML_HELP 
-->
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-5301477-18"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'UA-5301477-18');
</script>
<title>Pharo IoT Server Zeroconf Raspberry</title>
<style>
	BODY, TABLE { 
		font-family: Arial;
		line-height: 1.5em;
	}
	BODY { 
		background-color: white;
		margin-top: -1.5em;
	}
	TD { 
		vertical-align: top;
		padding: 0 1ex 0 0;
	}
	PRE, CODE { 
		background-color: #EEE;
		padding: 0.5ex 0.8ex;
		border-radius: 0.5ex;
	}
	A { 
		color: black;
	}
	</style>
<body>
<h1>Pharo IoT Server Zeroconf Raspberry</h1>
<p>This script downloads <code><a href="http://get.pharoiot.org/server.zip">server.zip</a></code> file that contain:</p>
<li>Pharo7 image 32 bit</li>
<li>Pharo ARM VM</li>
<li>Pharo IoT server installed</li>

<h2>Plattaform</h2>
<p>Raspberry Pi running Raspbian</p>

<h2>Usage</h2>
<code><a href="http://get.pharoiot.org/server">wget -O - get.pharoiot.org/server | bash</a></code>

<h2>Artifacts</h2>
<table><tr><td>pharo</td><td>Script to run Pharo in the headless mode</td></tr>
<tr><td>pharo-ui</td><td>Script to run Pharo in UI mode</td></tr>
<tr><td>pharo-server/</td><td>Start pharo in headless mode with TelePharo listening on port 40423 TCP</td></tr>
<tr><td>vm/</td><td>Directory containing the VM</td></tr></table>

<h2>Pharo IoT Server Example</h2>
<table><tr><td>Start Pharo IoT server:</td><td><code>./pharo-server</code></td></tr>
<tr><td>Open Pharo user interface:</td><td><code>./pharo-ui</code></td></tr>
<tr><td>Start the server (Playground):</td><td><code>TlpRemoteUIManager registerOnpPort:40423</code></td></tr></table>
<br><hr><br>
If you want to improve the content of this page, do the changes and make a Pull Request in the file <a href="https://github.com/pharo-iot/Ci/blob/master/docs/server/index.html">https://github.com/pharo-iot/Ci/blob/master/docs/server/index.html</a>
<!--
HTML_HELP
# --!></body></html>
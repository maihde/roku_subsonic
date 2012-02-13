#!/usr/bin/env python

print "Content-type: text/plain"
print

print """
function validate() {
	server = document.getElementById("server").value;
	if (server == null || server == "") {
		alert("You must specify a server name");
		return false;
	} else {
		return checkServerName(server);
	}
}

function checkServerName(server) {
	if (server.charAt(0) == '-') {
		alert("The server name cannot start with a hyphen");
		return false;
	} else if (server.charAt(server.length -1) == '-') {
                alert("The server name cannot end with a hyphen");
                return false;
        } else if (server.search('http://') >= 0 || server.search("https://") >= 0) {
		alert("Please enter only the server name portion of the URL");
		return false;
	} else if (server.charAt(0) == '.' || server.charAt(server.length - 1) == '.') {
		alert("One of the domain parts is missing from the server name");
		return false;
	}  else {
		invalid = /[^a-zA-Z0-9-]/
		parts = server.split(".");
		for (i in parts) {
			if (parts[i].match(invalid) != null) {
				alert("The server name is not a valid domain name");
				return false;
			}
		}
	}
	return true;
}
"""

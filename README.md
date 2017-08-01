Postfix Mail Relay
======================

Based on
[gdhnz/docker-mail-relay](https://github.com/gdhnz/docker-mail-relay)
which is a fork of
[alterrebe/docker-mail-relay](https://github.com/alterrebe/docker-mail-relay)
and converted to [Alpine Linux](https://www.alpinelinux.org) and
extended to require SMTP authentication prior to relaying mail.

Contains:

* Postfix, running in a simple relay mode
* RSyslog



Processes are managed by supervisord, including cronjobs

The container provides a simple proxy relay for environments like
Google Compute Engine where you can not have out-bound port 25/265/587
traffic. If you need to relay mail through e.g. your domain, you want
to have a TLS-encrypted authenticated relay available. This provides
that by requiring SMTP authentication prior to relaying mail.
The user in the SMTP authentication is arbitary and only known in the
Docker container. If you use port 25 (smtp, no authentication), the user
authentication is not used. The authentication requires a user ID and
a domain as well as a password. For example, `user@example.com` would 
have the user name `user` and domain `example.com`.


In the sample `RUN-sample` script, the 587 port is mapped to 2587. You could
test that connection  with e.g. `openssl s_client -connect yourhost:2587 -starttls smtp`


Exports
-------

* Postfix on `25`, `465` and `587`

Variables
---------

* `RELAY_HOST_NAME=relay.example.com`: A DNS name for this relay container (usually the same as the Docker's hostname)
* `ACCEPTED_NETWORKS=192.168.0.0/16 172.16.0.0/12 10.0.0.0/8`: A network (or a list of networks) to accept mail from
* `EXT_RELAY_HOST=email-smtp.us-east-1.amazonaws.com`: External relay DNS name
* `EXT_RELAY_PORT=25`: External relay TCP port
* `INCOMING_SMTP_AUTHLOGIN=`: Login for authentication to the SMTP relay
* `INCOMING_SMTP_AUTHDOM=`: Domain for the login to the SMTP relay
* `INCOMING_SMTP_AUTHPASSWORD=`: Password for authentication to the SMTP relay
* `OUTGOING_SMTP_LOGIN=`: Login to connect to the external relay (required, otherwise the container fails to start)
* `OUTGOING_SMTP_PASSWORD=`: Password to connect to the external relay (required, otherwise the container fails to start)
* `USE_TLS=`: Remote require tls. Might be "yes" or "no". Default: no.
* `TLS_VERIFY=`: Trust level for checking the remote side cert. (none, may, encrypt, dane, dane-only, fingerprint, verify, secure). Default: may.

Example
-------

Launch Postfix container:

    $ docker run -d -h relay.example.com --name="mailrelay" -e OUTGOING_SMTP_LOGIN=myLogin -e OUTGOING_SMTP_PASSWORD=myPassword -p 25:25 otagoweb/postfix-relay

See `RUN-sample` for more complete example.


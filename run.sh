#! /usr/bin/env ash
set -e # exit on error

# Variables
if [ -z "$OUTGOING_SMTP_LOGIN" -o -z "$OUTGOING_SMTP_PASSWORD" ] ; then
	echo "OUTGOING_SMTP_LOGIN and OUTGOING_SMTP_PASSWORD _must_ be defined"
	exit 1
fi
if [ -z "$INCOMING_SMTP_AUTHLOGIN" -o -z "$INCOMING_SMTP_AUTHPASSWORD" -o -z "$INCOMING_SMTP_AUTHDOM" ] ; then
	echo "INCOMING_SMTP_AUTHLOGIN and INCOMING_SMTP_AUTHPASSWORD _must_ be defined"
	exit 1
fi
if [ -z "$SSL_CERT_PEM" -o -z "$SSL_CERT_KEY" ] ; then
	echo "SSL_CERT_PEM and  SSL_CERT_KEY  _must_ be defined"
	exit 1
fi
export OUTGOING_SMTP_LOGIN OUTGOING_SMTP_PASSWORD
export INCOMING_SMTP_AUTHLOGIN INCOMING_SMTP_AUTHDOM INCOMING_SMTP_AUTHPASSWORD
export SSL_CERT_PEM SSL_CERT_KEY
export EXT_RELAY_HOST=${EXT_RELAY_HOST:-"email-smtp.us-east-1.amazonaws.com"}
export EXT_RELAY_PORT=${EXT_RELAY_PORT:-"25"}
export RELAY_HOST_NAME=${RELAY_HOST_NAME:-"relay.example.com"}
export ACCEPTED_NETWORKS=${ACCEPTED_NETWORKS:-"192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"}
export USE_TLS=${USE_TLS:-"yes"}
export TLS_VERIFY=${TLS_VERIFY:-"may"}

echo $RELAY_HOST_NAME > /etc/mailname

echo "$INCOMING_SMTP_AUTHPASSWORD" | saslpasswd2 -p -c -u "$INCOMING_SMTP_AUTHDOM" -a postfix "$INCOMING_SMTP_AUTHLOGIN"
chmod ugo+rwx /etc/sasldb2

HASHED=$(echo -ne "\000$INCOMING_SMTP_AUTHLOGIN@$INCOMING_SMTP_AUTHDOM\000$INCOMING_SMTP_AUTHPASSWORD" | openssl base64)
echo "Hashed AUTH PLAIN $HASHED"

/bin/mkdir -p /etc/ssl/certs /etc/ssl/private
echo "$SSL_CERT_PEM" > /etc/ssl/certs/ssl-cert-snakeoil.pem
echo "$SSL_CERT_KEY" > /etc/ssl/private/ssl-cert-snakeoil.key

# Templates
j2 /root/conf/postfix-main.cf > /etc/postfix/main.cf
j2 /root/conf/postfix-master.cf > /etc/postfix/master.cf
j2 /root/conf/sasl_passwd > /etc/postfix/sasl_passwd
j2 /root/conf/sasl2-smtpd.conf > /usr/lib/sasl2/smtpd.conf
postmap /etc/postfix/sasl_passwd

# Launch
rm -f /var/spool/postfix/pid/*.pid
exec /usr/bin/supervisord -n -c /etc/supervisord.conf

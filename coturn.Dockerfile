FROM mcr.microsoft.com/dotnet/aspnet:6.0-focal AS base
# https://help.hcltechsw.com/sametime/11.6/admin/turnserver_ubuntu.html
# https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker

RUN apt-get -y update
RUN apt-get -y install coturn openssl

#replace #TURNSERVER_ENABLED=1 -> TURNSERVER_ENABLED=1 #to allow  all stun and turn

RUN sed -i 's/#TURNSERVER_ENABLED=1/TURNSERVER_ENABLED=1/' /etc/default/coturn
#sudo openssl genrsa -out "/usr/local/etc/turn_server_pkey.pem" 4096
#sudo openssl req -new -x509 -days 36500 -key "/usr/local/etc/turn_server_pkey.pem" -out "/usr/local/etc/turn_server_cert.pem"
#sudo openssl x509 -in "/usr/local/etc/turn_server_cert.pem" -inform PEM -out "/usr/local/etc/turn_server_cert_x509.pem"
#sudo cat "/usr/local/etc/turn_server_pkey.pem" "/usr/local/etc/turn_server_cert.pem" > "/usr/local/etc/turn_server_cert_pkey.pem"
COPY  coturn_server_cert.pem /usr/local/etc/turn_server_cert.pem
COPY  coturn_server_pkey.pem /usr/local/etc/turn_server_pkey.pem
COPY  coturnserver.conf /etc/turnserver.conf

WORKDIR  /app

COPY coturnentrypoint.sh /app/coturnentrypoint.sh

EXPOSE 3478 3478/udp 5349 5349/udp 443 80

ENTRYPOINT ["/app/coturnentrypoint.sh"]

# sudo cp "/usr/local/etc/turn_server_pkey.pem" "/work/robot-english-learning/coturn_server_pkey.pem"
# sudo cp "/usr/local/etc/turn_server_cert.pem" "/work/robot-english-learning/coturn_server_cert.pem"
# sudo cp "/usr/local/etc/turn_server_cert_x509.pem" "/work/robot-english-learning/coturn_server_cert_x509.pem"
# sudo cp "/usr/local/etc/turn_server_cert_pkey.pem" "/work/robot-english-learning/coturn_server_cert_pkey.pem"
#sudo cat "/work/robot-english-learning/coturn_server_pkey.pem" "/work/robot-english-learning/coturn_server_cert.pem" > "/work/robot-english-learning/coturn_server_cert_pkey.pem"
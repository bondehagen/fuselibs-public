mkdir certs
cd certs
mkdir ca
openssl genrsa -aes256 -out ca/ca.key 4096 chmod 400 ca/ca.key
openssl req -new -x509 -sha256 -days 730 -key ca/ca.key -out ca/ca.crt
chmod 444 ca/ca.crt
openssl verify -CAfile ca/ca.crt server/receiver.crt
openssl x509 -noout -text -in ca/ca.crt

mkdir server
openssl genrsa -out server/receiver.key 2048
chmod 400 server/receiver.key
openssl req -new -key server/receiver.key -sha256 -out server/receiver.csr
openssl x509 -req -days 365 -sha256 -in server/receiver.csr -CA ca/ca.crt -CAkey ca/ca.key -set_serial 1 -out server/receiver.crt
chmod 444 server/receiver.crt
openssl verify -CAfile ca/ca.crt server/receiver.crt
openssl req -in server/receiver.csr -text -verify -noout
openssl pkcs12 -export -in server/receiver.crt -inkey server/receiver.key -out server/receiver.pfx -CAfile ca/ca.crt -chain

mkdir client
openssl genrsa -out client/sender.key 2048
chmod 400 client/sender.key
openssl req -new -key client/sender.key -out client/sender.csr
openssl x509 -req -days 365 -sha256 -in client/sender.csr -CA ca/ca.crt -CAkey ca/ca.key -set_serial 2 -out client/sender.crt
chmod 444 client/sender.crt
openssl verify -CAfile ca/ca.crt client/sender.crt
openssl req -in client/sender.csr -text -verify -noout
openssl pkcs12 -export -in client/sender.crt -inkey client/sender.key -out client/sender.pfx -CAfile ca/ca.crt -chain

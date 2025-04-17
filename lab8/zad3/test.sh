curl -X POST http://localhost/messages \
     -H "Content-Type: application/json" \
     -d '{"message":"Hello Redis!"}'

echo

curl http://localhost/messages

echo

curl -X POST http://localhost/users \
     -H "Content-Type: application/json" \
     -d '{"name":"Ala","email":"ala@example.com"}'

echo

curl http://localhost/users

echo

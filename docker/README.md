Para criar a network:

docker network create ascn_tp


Para criar o container da bd:

docker run --name my_postgres \
  -e POSTGRES_DB=mydatabase \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  --network ascn_tp \
  -p 5432:5432 \
  -d postgres

Criar a imagem do moonshot:

docker build -t moonshot .

Para arrancar o container do moonshot:

docker run --network ascn_tp -p 8000:8000 -it moonshot
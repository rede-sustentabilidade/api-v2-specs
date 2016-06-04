#!/bin/bash

db=${1-'rede_api_test'}
user=`whoami`
port=8888
exit_code=0

postgrest_bin='unknown'
unamestr=`uname`
ver='0.3.1.1'
dir='postgrest'

schema_log='logs/schema_load.log'
data_log='logs/data_load.log'

if [[ "$unamestr" == 'Linux' ]]; then
  postgrest_bin="postgrest-$ver-linux"
elif [[ "$unamestr" == 'Darwin' ]]; then
  postgrest_bin="postgrest-$ver-osx"
fi

if [[ "$postgrest_bin" == "unknown" ]]; then
  echo "Platform $unamestr is not supported by the postgrest binaries."
fi

echo "Initiating database users..."
createuser --no-login anonymous > /dev/null 2>&1
createuser --no-login web_user > /dev/null 2>&1
createuser --no-login admin > /dev/null 2>&1
createuser --no-login rs_role_admin_master > /dev/null 2>&1
createuser --no-login rs_role_afiliado > /dev/null 2>&1
createuser --no-login rs_role_coord_organizacao > /dev/null 2>&1
createuser --no-login rs_role_coord_executiva > /dev/null 2>&1
createuser --no-login rs_role_coord_geral > /dev/null 2>&1
createuser --no-login rs_role_coord_formacao > /dev/null 2>&1
createuser --no-login rs_role_coord_comunicacao > /dev/null 2>&1
createuser --no-login rs_role_coord_acao_institucional > /dev/null 2>&1
createuser --no-login rs_role_coord_politicas_pub > /dev/null 2>&1
createuser --no-login rs_role_coord_movimentos_sociais > /dev/null 2>&1
createuser --no-login rs_role_coord_ativismo > /dev/null 2>&1
createuser --no-login rs_role_coord_relacoes_int > /dev/null 2>&1
createuser --no-login rs_role_coord_vogal_executiva > /dev/null 2>&1
createuser rede -s > /dev/null 2>&1
createuser postgrest -g admin -g web_user -g anonymous > /dev/null 2>&1

echo "Initiating database schema..."
dropdb --if-exists $db
createdb $db
psql --set ON_ERROR_STOP=1 $db < ./database/schema.sql > $schema_log 2>&1
if [[ $? -ne 0 ]]; then
    echo "Error restoring test schema. Take a look at ${schema_log}:"
    tail -n 5 $schema_log
    exit 1
fi
psql --set ON_ERROR_STOP=1 -v db=$db $db < ./database/data.sql > $data_log 2>&1
if [[ $? -ne 0 ]]; then
    echo "Error restoring test data. Take a look at ${data_log}:"
    tail -n 5 $data_log
    exit 1
fi

echo "Initiating PostgREST server..."
./$dir/$postgrest_bin "postgres://postgrest@localhost/$db" -s "1" -a anonymous -p $port --jwt-secret gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C > logs/postgrest.log 2>&1 &

echo "Running tests..."
sleep 2
for f in test/*.yml
do
    echo ""
    echo "$f..."
    pyresttest http://localhost:$port $f
    if [[ $? -ne 0 ]]; then
        exit_code=1
    fi
done
echo ""

echo "Terminating PostgREST server..."
killall $postgrest_bin
echo "Done."
exit $exit_code

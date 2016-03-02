# Rede API specification 

## Requirements

* Mac OS X or Ubuntu Linux
* PostgreSQL 9.4+ with default contrib extensions
* Python 2.7.10+
* [pyresttest](https://github.com/svanoort/pyresttest)
* [click](http://click.pocoo.org/)

The scripts assume that you have a PostgreSQL running in your local environment
and that you have a database superuser with the same name as the user running the script.

You also need to be able to connect with any arbitrary PostgreSQL user without a password.

If you need to use a password to connect try setting up a [pgpass](http://www.postgresql.org/docs/current/static/libpq-pgpass.html) file.

## Installation

```
pip install -r requirements.txt
```

## Running tests

If everything is installed and configured properly you should be able to run the entire suite
using the command:

```
./api_spec.py run_tests
```

You can also pass one parameter with a different database name to use for testing.
The default name is **rede_api_test**.

## Updating the database schema

There is a script recreate_schema.sh in the database directory
that will read a given database and store its schema in the file database/schema.sql
After modifying the development database you should run this script
and run the tests to check if everything is still working.

```
./api_spec.py recreate_schema --name=database_name
```

## Adding tests

The tests are organized in files by endpoint, so you should
never test more than one endpoint per yml file.
Add the test file named after the endpoint you are testing, if you are
testing the endpoint **foo**, the test file will be **test/foo.yml**.

To bootstrap a basic get test against the foo endpoint use the command:

```
./api_spec.py generate_test --name=foo
```

## JWT testing

To test with JWT auth you can generate a token via jwt.io with the current test secret ```gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C```, we already have some pre generated tokens:

```
user_id 1 -> eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoid2ViX3VzZXIiLCJ1c2VyX2lkIjoiMSJ9.dEUw0q-niKR1r5UM6DbgCjThRVBSMZH02pT93DcmFwg
user_id 2 -> eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoid2ViX3VzZXIiLCJ1c2VyX2lkIjoiMiJ9.WZ7sSB1sTCaFoCpbBJ0GnyDNYHeWaZBbRQMypParGEc
user_id 3 -> eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoid2ViX3VzZXIiLCJ1c2VyX2lkIjoiMyJ9.etSjPXHxlxM3RqPt8z1GqqGbCJdVqzWPORh_9VU3xa4
user_id 4 -> eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoid2ViX3VzZXIiLCJ1c2VyX2lkIjoiNCJ9.ht-uAyQ5r5rfqtHpOWsfHLmeE-sykJFlW9pVEGAiKyQ
```

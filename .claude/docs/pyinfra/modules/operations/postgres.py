"""
The PostgreSQL modules manage PostgreSQL databases, users and privileges.

Requires the ``psql`` CLI executable on the target host(s).

All operations in this module take four optional arguments:
    + ``psql_user``: the username to connect to postgresql to
    + ``psql_password``: the password for the connecting user
    + ``psql_host``: the hostname of the server to connect to
    + ``psql_port``: the port of the server to connect to
    + ``psql_database``: the database on the server to connect to

See example/postgresql.py for detailed example

"""

from __future__ import annotations

from pyinfra import host
from pyinfra.api import MaskString, QuoteString, StringCommand, operation
from pyinfra.facts.postgres import (
    PostgresDatabases,
    PostgresRoles,
    make_execute_psql_command,
    make_psql_command,
)


@operation(is_idempotent=False)
def sql(
    sql: str,
    # Details for speaking to PostgreSQL via `psql` CLI
    psql_user: str | None = None,
    psql_password: str | None = None,
    psql_host: str | None = None,
    psql_port: int | None = None,
    psql_database: str | None = None,
):
    """
    Execute arbitrary SQL against PostgreSQL.

    + sql: SQL command(s) to execute
    + psql_*: global module arguments, see above
    """

    yield make_execute_psql_command(
        sql,
        user=psql_user,
        password=psql_password,
        host=psql_host,
        port=psql_port,
        database=psql_database,
    )


@operation()
def role(
    role: str,
    present=True,
    password: str | None = None,
    login=True,
    superuser=False,
    inherit=False,
    createdb=False,
    createrole=False,
    replication=False,
    connection_limit: int | None = None,
    # Details for speaking to PostgreSQL via `psql` CLI
    psql_user: str | None = None,
    psql_password: str | None = None,
    psql_host: str | None = None,
    psql_port: int | None = None,
    psql_database: str | None = None,
):
    """
    Add/remove PostgreSQL roles.

    + role: name of the role
    + present: whether the role should be present or absent
    + password: the password for the role
    + login: whether the role can login
    + superuser: whether role will be a superuser
    + inherit: whether the role inherits from other roles
    + createdb: whether the role is allowed to create databases
    + createrole: whether the role is allowed to create new roles
    + replication: whether this role is allowed to replicate
    + connection_limit: the connection limit for the role
    + psql_*: global module arguments, see above

    Updates:
        pyinfra will not attempt to change existing roles - it will either
        create or drop roles, but not alter them (if the role exists this
        operation will make no changes).

    **Example:**

    .. code:: python

        postgresql.role(
            name="Create the pyinfra PostgreSQL role",
            role="pyinfra",
            password="somepassword",
            superuser=True,
            login=True,
            sudo_user="postgres",
        )

    """

    roles = host.get_fact(
        PostgresRoles,
        psql_user=psql_user,
        psql_password=psql_password,
        psql_host=psql_host,
        psql_port=psql_port,
        psql_database=psql_database,
    )

    is_present = role in roles

    # User not wanted?
    if not present:
        if is_present:
            yield make_execute_psql_command(
                'DROP ROLE "{0}"'.format(role),
                user=psql_user,
                password=psql_password,
                host=psql_host,
                port=psql_port,
                database=psql_database,
            )
        else:
            host.noop("postgresql role {0} does not exist".format(role))
        return

    # If we want the user and they don't exist
    if not is_present:
        sql_bits = ['CREATE ROLE "{0}"'.format(role)]

        for key, value in (
            ("LOGIN", login),
            ("SUPERUSER", superuser),
            ("INHERIT", inherit),
            ("CREATEDB", createdb),
            ("CREATEROLE", createrole),
            ("REPLICATION", replication),
        ):
            if value:
                sql_bits.append(key)

        if connection_limit:
            sql_bits.append("CONNECTION LIMIT {0}".format(connection_limit))

        if password:
            sql_bits.append(MaskString("PASSWORD '{0}'".format(password)))

        yield make_execute_psql_command(
            StringCommand(*sql_bits),
            user=psql_user,
            password=psql_password,
            host=psql_host,
            port=psql_port,
            database=psql_database,
        )
    else:
        host.noop("postgresql role {0} exists".format(role))


@operation()
def database(
    database: str,
    present=True,
    owner: str | None = None,
    template: str | None = None,
    encoding: str | None = None,
    lc_collate: str | None = None,
    lc_ctype: str | None = None,
    tablespace: str | None = None,
    connection_limit: int | None = None,
    # Details for speaking to PostgreSQL via `psql` CLI
    psql_user: str | None = None,
    psql_password: str | None = None,
    psql_host: str | None = None,
    psql_port: int | None = None,
    psql_database: str | None = None,
):
    """
    Add/remove PostgreSQL databases.

    + name: name of the database
    + present: whether the database should exist or not
    + owner: the PostgreSQL role that owns the database
    + template: name of the PostgreSQL template to use
    + encoding: encoding of the database
    + lc_collate: lc_collate of the database
    + lc_ctype: lc_ctype of the database
    + tablespace: the tablespace to use for the template
    + connection_limit: the connection limit to apply to the database
    + psql_*: global module arguments, see above

    Updates:
        pyinfra will not attempt to change existing databases - it will either
        create or drop databases, but not alter them (if the db exists this
        operation will make no changes).

    **Example:**

    .. code:: python

        postgresql.database(
            name="Create the pyinfra_stuff database",
            database="pyinfra_stuff",
            owner="pyinfra",
            encoding="UTF8",
            sudo_user="postgres",
        )

    """

    current_databases = host.get_fact(
        PostgresDatabases,
        psql_user=psql_user,
        psql_password=psql_password,
        psql_host=psql_host,
        psql_port=psql_port,
        psql_database=psql_database,
    )

    is_present = database in current_databases

    if not present:
        if is_present:
            yield make_execute_psql_command(
                'DROP DATABASE "{0}"'.format(database),
                user=psql_user,
                password=psql_password,
                host=psql_host,
                port=psql_port,
                database=psql_database,
            )
        else:
            host.noop("postgresql database {0} does not exist".format(database))
        return

    # We want the database but it doesn't exist
    if present and not is_present:
        sql_bits = ['CREATE DATABASE "{0}"'.format(database)]

        for key, value in (
            ("OWNER", '"{0}"'.format(owner) if owner else owner),
            ("TEMPLATE", template),
            ("ENCODING", encoding),
            ("LC_COLLATE", lc_collate),
            ("LC_CTYPE", lc_ctype),
            ("TABLESPACE", tablespace),
            ("CONNECTION LIMIT", connection_limit),
        ):
            if value:
                sql_bits.append("{0} {1}".format(key, value))

        yield make_execute_psql_command(
            StringCommand(*sql_bits),
            user=psql_user,
            password=psql_password,
            host=psql_host,
            port=psql_port,
            database=psql_database,
        )
    else:
        host.noop("postgresql database {0} exists".format(database))


@operation(is_idempotent=False)
def dump(
    dest: str,
    # Details for speaking to PostgreSQL via `psql` CLI
    psql_user: str | None = None,
    psql_password: str | None = None,
    psql_host: str | None = None,
    psql_port: int | None = None,
    psql_database: str | None = None,
):
    """
    Dump a PostgreSQL database into a ``.sql`` file. Requires ``pg_dump``.

    + dest: name of the file to dump the SQL to
    + psql_*: global module arguments, see above

    **Example:**

    .. code:: python

        postgresql.dump(
            name="Dump the pyinfra_stuff database",
            dest="/tmp/pyinfra_stuff.dump",
            sudo_user="postgres",
        )

    """

    yield StringCommand(
        make_psql_command(
            executable="pg_dump",
            user=psql_user,
            password=psql_password,
            host=psql_host,
            port=psql_port,
            database=psql_database,
        ),
        ">",
        QuoteString(dest),
    )


@operation(is_idempotent=False)
def load(
    src: str,
    # Details for speaking to PostgreSQL via `psql` CLI
    psql_user: str | None = None,
    psql_password: str | None = None,
    psql_host: str | None = None,
    psql_port: int | None = None,
    psql_database: str | None = None,
):
    """
    Load ``.sql`` file into a database.

    + src: the filename to read from
    + psql_*: global module arguments, see above

    **Example:**

    .. code:: python

        postgresql.load(
            name="Import the pyinfra_stuff dump into pyinfra_stuff_copy",
            src="/tmp/pyinfra_stuff.dump",
            sudo_user="postgres",
        )

    """

    yield StringCommand(
        make_psql_command(
            user=psql_user,
            password=psql_password,
            host=psql_host,
            port=psql_port,
            database=psql_database,
        ),
        "<",
        QuoteString(src),
    )

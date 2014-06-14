## Configuration

Since it's only bash based we need a way to configure multiple endpoint
without complex configuration file.

An idea is to create a configuration file using the ``dlab`` command that
contains all the settings needed in order to do a deploy in a given server.

Each remote endpoint will have its own configuration file because of the
pretty limited way bash handle variables.

For example, suppose we want to configure a remote endpoint for the production
with its parameters: we should use the following command

    $ dlab remote add production user@domain public/ --key ~/.ssh/id_rsa_domain.pub

It is also possible to indicate some parameters for unusual value (like ``ssh``
port number).

The command above should create a configuration file named ``production.dlab`` with all
the informations needed for deploying.

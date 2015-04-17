Deploy Like A Boss
==================

The way Heroku has changed the deploying of web application is impressive,
but also if the code is open source in some cases is not allowed to use
their stack (containers, git repository on the remote side etc...) so
these are scripts to manage deploying having only ssh access to the
remote machine.

[![Build Status](https://travis-ci.org/gipi/dlab.svg?branch=master)](https://travis-ci.org/gipi/dlab)

Philosophy
----------

 - Use what already exist (ssh, tar)
 - Make all the possible local
 - Do all automagically
 - Allow to fallback to a shell when errors happen

Usage (not implemented yet)
---------------------------

First of all you need to install server side: edit a file name ``.deploy_ssh_config``
like a ``ssh`` config file; after that

    $ dlab init <public key path> <remote path> <project type>

``project type`` select the stack you want to manage with this application,
for now it's possible to manage ``static`` and ``python`` application. This
command asks for you connection password by ``ssh`` and save in the remote
``authorized_keys`` file the command to deploy.

After that is possible to deploy with a simple

    $ dlab deploy
    <- sending
    -> deploying revision: fb3c0ca -> 1e21e54 into /var/www/foobar/

VAGRANT
-------

It's possible to have a quick testing machine using vagrant: simply
start the box using

    $ vagrant up

and after that dump the ssh configuration file

    $ vagrant ssh-config > .vagrant_ssh_config

and use it to initialize the deploy

    $ DEPLOY_CONFIG_FILE=.vagrant_ssh_config ./dlab init <public key> /remote/path

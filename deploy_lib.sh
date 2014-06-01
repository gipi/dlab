#
# Simple utility script to manage deploy from client/server side
#
# usage:
#
#   $ source deploy_lib.sh "/path/to/web/root"
#   $ deploy
#

test -z "$1" && {
    echo 'use as first argument the directory where deploy'
    return;
}

DEPLOY_DIR=${1:-/tmp/app}

REMOTE_COMMAND=
REMOTE_COMMAND="ssh vagrant"
#DEPLOY_COMMAND=tar t
DEPLOY_COMMAND=". /vagrant/deploy/lib.sh ${DEPLOY_DIR} ;handle_deploy"
TAR_COMMAND="tar -C ${DEPLOY_DIR} -x"

pretty_print_stdout() {
    PP_PREFIX=$1
    while read line;
    do
        echo ${PP_PREFIX}${line}
    done
}

pretty_print_client() {
    pretty_print_stdout ' <- '
}

pretty_print_destination() {
    pretty_print_stdout ' -> '
}

deploy() {
    echo 'sending' | pretty_print_client
    (get_revision;get_deploy_path;get_archive) | ${REMOTE_COMMAND} ${DEPLOY_COMMAND} || {
        echo " FATAL: some error occured, have you set the correct host in .ssh/config?"
        return
    }
}

get_archive() {
    git archive HEAD
}

get_revision() {
    git describe --always --tags
}

get_deploy_path() {
    echo ${DEPLOY_DIR}
}

# to be used in the remote side
handle_deploy() {
    read version;
    read deploy_path;
    old_version=$(cat ${DEPLOY_DIR}/.version)

    echo 'deploying revision: '$old_version ' -> ' $version' into '$deploy_path | pretty_print_destination
    cat | ${TAR_COMMAND} 2>&1 | pretty_print_destination

    # after all, save into the deploy directory a .version with the revision
    echo $version > ${DEPLOY_DIR}/.version

    echo 'ok' | pretty_print_destination
}

#
# Simple utility script to manage deploy from client/server side
#
# usage:
#
#   $ source deploy_lib.sh "/path/to/web/root"
#   $ deploy
#
MAGIC='DLAB/0.0.1'
DEPLOY_CONFIG_FILE=${DEPLOY_CONFIG_FILE:-.deploy_ssh_config}

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
    (echo ${MAGIC};get_revision;get_deploy_path;get_archive) | ${REMOTE_COMMAND} ${DEPLOY_COMMAND} || {
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
    read magic;
    test "${magic}" == "${MAGIC}" || {
        echo 'fatal: signature not found'
        return 1
    }
    read version;
    read deploy_path;
    old_version=$(cat ${DEPLOY_DIR}/.version)

    echo 'deploying revision: '$old_version ' -> ' $version' into '$deploy_path | pretty_print_destination
    cat | ${TAR_COMMAND} 2>&1 | pretty_print_destination

    # after all, save into the deploy directory a .version with the revision
    echo $version > ${DEPLOY_DIR}/.version

    for hook in $(ls ${DEPLOY_DIR}/hooks/*);
    do
        ${hook}
    done

    echo 'ok' | pretty_print_destination
}

# the original version doesn't allow to pass all the parameters
# we need to ssh
_ssh_copy_id() {
    KEY="${1?"fatal: missing public key"}"
    echo -n "command=\"ls -l\" " | cat - ${KEY} | ssh -F "${DEPLOY_CONFIG_FILE}" default "
    umask 077;
    mkdir -p .ssh && cat >> .ssh/authorized_keys || exit 1;"
}

_dump_ssh_config() {
    HOST_KEY="default"
    # usage: <user> <host> <key> [<port>]
    USER=$1
    HOST=$2
    KEY=${3}
    PORT=${4:-22}
    cat >> ${DEPLOY_CONFIG_FILE} <<EOF
Host ${HOST_KEY}
  HostName ${HOST}
  User ${USER}
  Port ${PORT}
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile ${KEY}
  IdentitiesOnly yes
  LogLevel FATAL

EOF
}

init_deploy() {
    DEPLOY_DIR="$1"
    # check the destination directory doesn't exist
    test -d "${DEPLOY_DIR}" && {
        echo 'fatal: '${DEPLOY_DIR}' already exists' | pretty_print_destination
        return 1
    }

    mkdir -p "${DEPLOY_DIR}"
}

get_modified_files() {
    START="$1"
    END="$2"
    git diff --stat ${START}..${END} | sed '$d' | awk -F "|" '{print $1}'
}

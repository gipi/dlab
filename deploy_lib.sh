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

# copy the remote code necessary by tar
# initialize the ssh authorized key
init_deploy() {
    # First of all configure the key
    KEY_PATH="${1?"fatal: missing public key"}"
    DEPLOY_DIR="${2?"missing deploy directory value?"}"
    # we pass all the remaining arguments to SSH
    shift 2
    # create a temporary directory where do the stuff
    TEMPDIR=$(mktemp -d)
    git archive HEAD -- remote | tar -x -C "${TEMPDIR}"
    # copy
    cp ${KEY_PATH} "${TEMPDIR}"/id_rsa.pub

    # do the remote side stuff
    (cd ${TEMPDIR}; tar c .) | ssh "$@" "
    mkdir -p ${DEPLOY_DIR}/.deploy;
    cat | tar -x -C ${DEPLOY_DIR}/.deploy;
    umask 077;
    echo 'copying key'
    mkdir -p .ssh && cat ${DEPLOY_DIR}/.deploy/id_rsa.pub >> .ssh/authorized_keys;
    "
}

get_modified_files() {
    START="$1"
    END="$2"
    git diff --stat ${START}..${END} | sed '$d' | awk -F "|" '{print $1}'
}

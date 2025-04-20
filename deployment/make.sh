#!/bin/bash
# when first argument is not set
if [ -z "$1" ]; then
    echo "No action argument is supplied eg ./make.sh deploy"
    exit 1
fi

# DEPLOY
if [ "$1" == "deploy" ]; then
# get named arguments
while [ $# -gt 0 ]; do
    if [[ $1 == --* ]]; then
        if [[ "$1" == *=* ]]; then
            v="${1/--/}"
            declare "${v%%=*}"="${v#*=}"
        else
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
    fi
    shift
done

# if vault-password not in arguments exit
if [ -z "$vault_password" ]; then
    echo "--vault_password not set"
    exit 1
fi
# check which environment should be deployed
if [ -z "$environment" ]; then
    echo "--environment not set"
    exit 1
fi
# check which service should be deployed
if [ -z "$service" ]; then
    echo "--service not set, deploying all services"
    service="all"
fi
  hcloud_token=$(echo "$vault_password" | ansible-vault view hcloud_token_$environment --vault-password-file /bin/cat)
  echo "$vault_password" | HCLOUD_TOKEN=$hcloud_token ansible-playbook playbook.yml --vault-password-file /bin/cat --tags $service --skip-tags infrastructure
fi


# INFRASTRUCTURE
if [ "$1" == "infrastructure" ]; then
# get named arguments
while [ $# -gt 0 ]; do
    if [[ $1 == --* ]]; then
        if [[ "$1" == *=* ]]; then
            v="${1/--/}"
            declare "${v%%=*}"="${v#*=}"
        else
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
    fi
    shift
done

# if vault-password not in arguments exit
if [ -z "$vault_password" ]; then
    echo "--vault_password not set"
    exit 1
fi

# check that environment is production or staging
if [ "$environment" != "production" ] && [ "$environment" != "staging" ]; then
    echo "--environment must be production or staging"
    exit 1
fi
  hcloud_token=$(echo "$vault_password" | ansible-vault view hcloud_token_$environment --vault-password-file /bin/cat)
  echo "$vault_password" | HCLOUD_TOKEN=$hcloud_token ansible-playbook playbook.yml --vault-password-file /bin/cat --tags infrastructure -l $environment,provision-infrastructure
fi





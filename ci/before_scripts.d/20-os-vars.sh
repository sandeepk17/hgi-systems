REGION=${REGION:-}

if [[ -z "$REGION" ]]; then
    echo "REGION unset or empty, not setting any OS vars"
    return
fi

case $REGION in
    zeta)
        export OS_USERNAME=${ZETA_OS_USERNAME}
        export OS_PASSWORD=${ZETA_OS_PASSWORD}
        export OS_AUTH_URL=${ZETA_OS_AUTH_URL}
        >&2 echo "OS credentials for zeta set"
	    ;;
    *)
        >&2 echo "REGION '${REGION}' not recognized in 20-os-vars.sh, not setting OS_ vars"
        >&2 echo "Refusing to continue without recognized REGION"
        exit 1
        ;;
esac

function export_tenant_or_project {
    tenant_or_project=$1
    if [[ "${CI_JOB_STAGE}" == terraform* ]]; then
	unset OS_TENANT_NAME
        export OS_PROJECT_NAME="${tenant_or_project}"
        export OS_PROJECT_DOMAIN_NAME="Default"
        export OS_USER_DOMAIN_NAME="Default"
        >&2 echo "OS_PROJECT_NAME set to ${tenant_or_project} (using v3+ auth) (stage=${CI_JOB_STAGE})"
    else
        export OS_TENANT_NAME="${tenant_or_project}"
	unset OS_PROJECT_NAME
	unset OS_PROJECT_DOMAIN_NAME
	unset OS_USER_DOMAIN_NAME
        >&2 echo "OS_TENANT_NAME set to ${tenant_or_project} (using v2 auth) (stage=${CI_JOB_STAGE})"
    fi
}

if [[ -z "$SETUP" ]]; then
    >&2 echo "SETUP unset or empty, not setting tenant/project vars"
    return
fi

case $SETUP in
    hgi-ci|hgi-ci-*)
        export_tenant_or_project hgi-ci
        ;;
    hgi-dev|hgi-dev-*)
        export_tenant_or_project hgi-dev
        ;;
    hgi|hgi-*)
        export_tenant_or_project hgi
        ;;
    hgiarvados|hgiarvados-*)
        export_tenant_or_project hgiarvados
        ;;
    *)
        >&2 echo "SETUP '${SETUP}' not recognized in 20-os-vars.sh, not setting tenant/project vars"
        >&2 echo "Refusing to continue without recognized SETUP"
        exit 1
	    ;;
esac

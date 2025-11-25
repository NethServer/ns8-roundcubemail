*** Settings ***
Resource    api.resource
Library     SSHLibrary
Resource    ldap_providers.resource

*** Variables ***
${user_domain_ldap}      ldap.dom.test

*** Test Cases ***
Install account providers
    [Tags]    udom    add
    Configure LDAP user domain

Mail module installation
    [Tags]    module
    ${output}  ${rc} =    Execute Command    add-module ghcr.io/nethserver/mail:main 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${MID}    ${output.module_id}

Get defaults
    ${hostname} =    Execute Command    hostname -f
    ${mail_domain} =  Execute Command    hostname -d
    ${response} =    Run task     module/${MID}/get-defaults    {}    decode_json=${FALSE}

    Should Contain    ${response}    "name": "${user_domain_ldap}"
    Should Contain    ${response}    "hostname": "${hostname}"
    Should Contain    ${response}    "mail_domain": "${mail_domain}"


Configure mail server with OpenLDAP user domain
    Run task     module/${MID}/configure-module
    ...          {"hostname":"mail.domain.test","user_domain":"ldap.dom.test", "mail_domain": "domain.test"}

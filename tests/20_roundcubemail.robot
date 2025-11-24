*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${curl_timeout}    9

*** Keywords ***
Retry test
    [Arguments]    ${keyword}
    Wait Until Keyword Succeeds    60 seconds    1 second    ${keyword}

Backend URL is reachable
    ${rc} =    Execute Command    curl -f ${backend_url}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0


*** Test Cases ***
Check if roundcubemail is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${roundcubemail_module_id}    ${output.module_id}

Check if we can retrieve the mail module ID
    FOR    ${i}    IN RANGE    30
        ${ocfg} =   Run task    module/${roundcubemail_module_id}/get-configuration    {}
        Log    ${ocfg}
        Run Keyword If    ${ocfg}    Exit For Loop
        Sleep    2s
    END
    Set Suite Variable     ${mail_modules_id}    ${ocfg['mail_server_URL'][0]['value']}
    Should Not Be Empty    ${mail_modules_id}

Check if roundcubemail can be configured
    ${mail_server_uuid}    ${mail_domain}=    Evaluate    "${mail_modules_id}".split(",")
    ${rc} =    Execute Command    api-cli run module/${roundcubemail_module_id}/configure-module --data '{"host": "roundcubemail.domain.com","http2https": false,"lets_encrypt": false,"mail_domain": "${mail_domain}","mail_server": "${mail_server_uuid}","plugins": "","upload_max_filesize": 10}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Retrieve roundcubemail backend URL
    # Assuming the test is running on a single node cluster
    ${response} =    Run task     module/traefik1/get-route    {"instance":"${roundcubemail_module_id}"}
    Set Suite Variable    ${backend_url}    ${response['url']}

Check if roundcubemail works as expected
    Retry test    Backend URL is reachable

Verify roundcubemail frontend title
    ${output} =    Execute Command    curl -s ${backend_url}
    Should Contain    ${output}    <title>Roundcube Webmail

#Login to roundcubemail as user u1@domain.test
#    ${output}    ${err}    ${rc} =    Execute Command
#    ...    sh -c "token=$(curl -s -c \"/tmp/roundcube\" \"${backend_url}\" | grep 'name=\"_token\"' | sed -E 's/.*value=\"([^\"]+)\".*/\1/'); curl -s -b \"/tmp/roundcube\" -c \"/tmp/roundcube\" -X POST \"${backend_url}/?_task=login\" -d \"_token=$token\" -d \"_task=login\" -d \"_action=login\" -d \"_user=u1@domain.test\" -d \"_pass=Nethesis,1234\" -d \"_timezone=_default_\" -d \"_url=_task=login\"; curl -s -b \"/tmp/roundcube\" \"${backend_url}/?_task=mail\""
#    ...    return_rc=True
#    ...    return_stdout=True
#    ...    return_stderr=True
#    Log    Curl stdout: ${output}
#    Log    Curl stderr: ${err}
#    Log    Curl rc: ${rc}
#    # roundcubemail redirect to https://
#    #Should Be Equal As Integers    ${rc}    35
#    #Should Contain    ${err}    HTTP/1.1 302
#    # match the cookie of the authenticated session
#    #Should Contain    ${err}    Set-Cookie: JSESSIONID=

#Login to roundcube as user u1@domain.test
#    Put File    ${CURDIR}/test-login.sh    /tmp/test-login.sh
#    ${out}  ${err}  ${rc} =    Execute Command
#    ...    bash /tmp/test-login.sh ${backend_url}
#    ...    return_rc=True    return_stderr=True
#    Log    Mail helper stdout: ${out}
#    Log    Mail helper stderr: ${err}
#    Log    Mail helper stderr: ${rc}
#    #Should Be Equal As Integers    ${rc}  0

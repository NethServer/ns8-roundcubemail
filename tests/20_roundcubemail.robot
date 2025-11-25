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

Send email to the mail server
    Put File    ${CURDIR}/test-msa.sh    /tmp/test-msa.sh
    ${mail_server} =    Set Variable    smtp://127.0.0.1:10587
    ${from} =    Set Variable    u1@domain.test
    ${to} =    Set Variable    u3@domain.test
    ${out}  ${err}  ${rc} =    Execute Command
    ...    MAIL_SERVER=${mail_server} bash /tmp/test-msa.sh ${to} ${from}
    ...    return_rc=True    return_stderr=True
    Log    Mail helper stdout: ${out}
    Log    Mail helper stderr: ${err}
    Should Be Equal As Integers    ${rc}  0

Retrieve roundcubemail backend URL
    # Assuming the test is running on a single node cluster
    ${response} =    Run task     module/traefik1/get-route    {"instance":"${roundcubemail_module_id}"}
    Set Suite Variable    ${backend_url}    ${response['url']}

Check if roundcubemail works as expected
    Retry test    Backend URL is reachable

Verify roundcubemail frontend title
    ${output} =    Execute Command    curl -s ${backend_url}
    Should Contain    ${output}    <title>Roundcube Webmail :: Welcome to Roundcube Webmail</title>

Login to roundcube as user u3@domain.test
    Put File    ${CURDIR}/test-login.sh    /tmp/test-login.sh
    ${user} =    Set Variable    u3@domain.test
    ${out}  ${err}  ${rc} =    Execute Command
    ...    bash /tmp/test-login.sh ${backend_url} ${user}
    ...    return_rc=True    return_stderr=True
    Log    Login helper stdout: ${out}
    Log    Login helper stderr: ${err}
    Log    Login helper stderr: ${rc}
    Should Be Equal As Integers    ${rc}  0
    should Contain    ${err}    <title>Roundcube Webmail :: Inbox</title>

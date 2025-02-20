#!/bin/bash

set -ex

# Initialize
if [[ $1 == init ]]; then

    # Initialize pass
    gpg --generate-key --batch /protonmail/gpgparams
    pass init pass-key
    
    # Kill the other instance as only one can be running at a time.
    # This allows users to run entrypoint init inside a running conainter
    # which is useful in a k8s environment.
    # || true to make sure this would not fail in case there is no running instance.
    pkill protonmail-bridge || true

    # Login
    /protonmail/proton-bridge --cli $@

else
    # If the TLS_CERT_PATH file exists, also listen on TLS ports
#    if [[ -f "$TLS_CERT_PATH" ]]; then
#        # SMTP over TLS on port 25
#        socat OPENSSL-LISTEN:25,cert="$TLS_CERT_PATH",verify=0,fork TCP:127.0.0.1:1025 &
#        # IMAP over TLS on port 143
#        socat OPENSSL-LISTEN:143,cert="$TLS_CERT_PATH",verify=0,fork TCP:127.0.0.1:1143 &
#    else
#        echo "TLS_CERT_PATH is set to '$TLS_CERT_PATH', but the file was not found. TLS ports will not be opened."

        # socat will make the conn appear to come from 127.0.0.1
        # ProtonMail Bridge currently expects that.
        # It also allows us to bind to the real ports :)
        socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
        socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &
#    fi

    # Start protonmail
    # Fake a terminal, so it does not quit because of EOF...
    rm -f faketty
    mkfifo faketty
    cat faketty | /protonmail/proton-bridge --cli $@

fi

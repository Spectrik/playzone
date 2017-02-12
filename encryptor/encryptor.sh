#!/bin/bash

# parse arguments
while [[ $# -gt 0 ]]
do
    ENC_KEY="$1"

    case $ENC_KEY in
        --input)
            ENC_INPUT_FILES="$2"
            shift
        ;;

        --output)
            ENC_OUTPUT="$2"
            shift
        ;;

        --file)
            ENC_LIST="$2"
            shift
        ;;

        --password)
            ENC_PASSWORD="$2"
            shift
        ;;

        --decrypt)
            ENC_DECRYPT="yes"
        ;;

        *)
                # unknown option
        ;;
    esac
        shift
done

# encrypt function
function enc_encrypt
{
    FILENAME=$(basename $1)
    tar czf - "$1" | openssl des3 -salt -pass pass:"$3" | dd of="$2/$FILENAME.encrypted" > /dev/null 2>&1
    return 0

}

# decrypt function
function enc_decrypt
{
    dd if="$1" | openssl des3 -d -pass pass:"$3" | tar -xzf -
}

# Variables
ENC_CONFIGURATION_FILE="/etc/projects/playzone/encryptor.conf"

# Tests
if ! [ -e $ENC_CONFIGURATION_FILE ]; then
    echo "Configuration file $ENC_CONFIGURATION_FILE was not found!"
    exit 1
else
    source $ENC_CONFIGURATION_FILE
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "openssl program is not installed!"
    exit 1
fi

if [ -z "$ENC_INPUT_FILES" -o -z "$ENC_OUTPUT" -o -z "$ENC_PASSWORD" ]; then
    echo "Paramaters input, output and password are mandatory!"
    exit 1
fi

if ! [ -e $ENC_INPUT_FILES ]; then
    echo "File(s) to encrypt / decrypt were not found! Check the input path. Make sure the path is absolute!"
    exit 1
fi

if ! [ -e $ENC_OUTPUT ]; then
    echo "Output folder does not exist!"
    exit 1
fi

### Decrypting
if [ "$ENC_DECRYPT" == "yes" ]; then
    enc_decrypt $ENC_INPUT_FILES $ENC_OUTPUT $ENC_PASSWORD
    exit 0
fi

### Encrypting

# Encrypt single file or directory
enc_encrypt $ENC_INPUT_FILES $ENC_OUTPUT $ENC_PASSWORD

# Encrypt list of files...
if [ -n "$ENC_LIST" -a -e "$ENC_LIST" ]; then
    while read -r ENC_FILE
    do
        if [ -e "$ENC_FILE" ]; then
            enc_encrypt $ENC_FILE $ENC_OUTPUT $ENC_PASSWORD
        else
            echo "File $ENC_FILE was not found!"
            continue
        fi
    done < "$ENC_LIST"
fi

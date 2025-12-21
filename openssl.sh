#!/bin/sh


openssl_private_key()
{
  PRIVATE_KEY_FILENAME="$1"
  EXT="$2"

  if [ -z "$PRIVATE_KEY_FILENAME" ];
  then
      echo "Usage: $0 <PRIVATE_KEY_FILENAME> [EXT]" >&2
      exit 1
  fi

  if [ -z "$EXT" ];
  then
      EXT="pem"
  fi

  openssl genrsa -out "${PRIVATE_KEY_FILENAME}.${EXT}" 1024
}

openssl_public_key()
{
  PRIVATE_KEY_FILENAME="$1"
  PUBLIC_KEY_FILENAME="$2"
  EXT="$3"

  if [ -z "$PRIVATE_KEY_FILENAME" ];
  then
      echo "Usage: $0 <PRIVATE_KEY_FILENAME> <PUBLIC_KEY_FILENAME> [EXT]" >&2
      exit 1
  fi

  if [ -z "$EXT" ];
  then
      EXT="pem"
  fi

  openssl rsa -in "${PRIVATE_KEY_FILENAME}.${EXT}" -out "${PUBLIC_KEY_FILENAME}.${EXT}" -pubout
}

openssl_encrypt()
{
  public_key_file="${1}"
  file_to_encrypt="${2}"

  openssl pkeyutl -encrypt -pubin -inkey "${public_key_file}" -in "${file_to_encrypt}" -out "${file_to_encrypt}.enc"
}

openssl_decrypt()
{
  private_key_file="${1}"
  file_to_decrypt="${2}"

  openssl pkeyutl -decrypt -inkey "${private_key_file}" -in "${file_to_decrypt}" -out "${file_to_encrypt}.dec"
}

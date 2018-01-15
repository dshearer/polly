#!/bin/sh

EXPECTED_OUTPUT="meow! meow! meow! meow! meow! "
ACTUAL_OUTPUT=$(polly)
if [ "${EXPECTED_OUTPUT}" = "${ACTUAL_OUTPUT}" ]; then
    echo "PASS"
    exit 0
else
    echo "FAIL"
    exit 1
fi

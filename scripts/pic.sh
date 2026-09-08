#!/usr/bin/env bash

# pic.sh
# Qompass AI - screenshot pipeline (acli + geny)
# Copyright (C) 2026 Qompass AI, All rights reserved
# ----------------------------------------
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

./acli.sh setup-sdk
./acli.sh create-avd
./acli.sh start-emulator
./acli.sh full ontrack 4

./geny.sh devices
./geny.sh install
./geny.sh launch
./geny.sh screenshot ontrack-home

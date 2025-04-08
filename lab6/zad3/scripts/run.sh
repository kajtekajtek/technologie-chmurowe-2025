#!/bin/sh

set -e

source "$(dirname $0)/env.sh"

"$(dirname $0)/create_networks.sh"

"$(dirname $0)/run_database.sh"

"$(dirname $0)/run_backend.sh"

"$(dirname $0)/run_frontend.sh"

#!/bin/bash

set -e
echo

for feature in "${@}"; do
  echo -e "\n-- ${feature} --"

  for test in "test/${feature}/"*.sh; do
  $(

    test_name=$(echo ${test: 0:-3} | grep -o '[^/]\+$')
    echo "** Test: ${test_name} **"

    profile="${feature}--${test_name}"
    config_path="/tmp/${profile}.json"
    
    $(
      featurePath=../src/${feature}
      source "$test"
      configure
    ) > "${config_path}"

    if [ dcc build -p "${config_path}" -ne 0 ]; then
      
      exit 1
    fi

    dcc run -p "${config_path}" -- bash -c "
    FAILED=()
    check() {
      LABEL=$1
      shift

      echo -en "\n• testing [$LABEL]"
      if "$@"; then
        echo -e "\r\e[K\xE2\x9C\x93 passed  [$LABEL]"
        return 0
      else
        echo -e "\r\e[K\xE2\x9C\x97 failed  [$LABEL]"
        FAILED+=("$LABEL")
        return 1
      fi
    }

    reportResults() {
      if [ \${#FAILED[@]} -ne 0 ]; then
        echoStderr -e "\nFailed tests: \${FAILED[@]}"
        exit 1
      else
        echo -e "\nTest Passed!"
        exit 0
      fi
    }

source '${test}'
test
EOT
  )
  done
done

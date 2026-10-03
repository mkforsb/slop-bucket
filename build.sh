#!/bin/bash

IFS=$'\n'

function build_index() {
    local targetDir title includeCdup withFiles

    targetDir="$1"
    title="$2"
    includeCdup="$3"
    withFiles="$4"

    cat << EOF
<!DOCTYPE html>
<html>
    <head>
        <title>${title}/</title>
    </head>
    <body>
        <ul>
EOF

    if [ "${includeCdup}" == "cdup" ]; then
        echo "            <li><a href=\"..\">..</a></li>"
    fi

    for dir in $(find . -mindepth 1 -maxdepth 1 -type d ! -name .git -printf '%f\n' | sort); do
        echo "            <li><a href=\"./${dir}\">./${dir}</a></li>"
    done

    if [ "${withFiles}" == "withfiles" ]; then
        for dir in $(find . -mindepth 1 -maxdepth 1 -type f ! -name index.html -printf '%f\n' | sort); do
            echo "            <li><a href=\"./${dir}\">./${dir}</a></li>"
        done
    fi

    cat << EOF
        </ul>
    </body>
</html>
EOF
}

function build_subfolder() {
    local targetDir
    targetDir="$1"

    (cd "${targetDir}" && build_index "." "${targetDir}" "cdup" "withfiles")
}


build_index "." "slop-bucket" "nocdup" "nofiles" > index.html

for dir in $(find . -mindepth 1 -maxdepth 1 -type d ! -name .git -printf '%f\n' | sort); do
    build_subfolder "${dir}" > "${dir}/index.html"
done


#!/bin/bash

IFS=$'\n'

# keep '&' literal in ${var//pattern/replacement} (bash >= 5.2)
shopt -u patsub_replacement 2>/dev/null

cd "$(dirname "$0")" || exit 1

TEMPLATE="${PWD}/template.html"

function escape_html() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    s="${s//\"/&quot;}"
    printf '%s' "${s}"
}

function human_size() {
    awk -v b="$1" 'BEGIN {
        split("B KB MB GB", u); i = 1
        while (b >= 1024 && i < 4) { b /= 1024; i++ }
        printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i]
    }'
}

# "20261003-xenopalm-xp1" -> sets DATE="2026-10-03", NAME="xenopalm-xp1"
function split_name() {
    if [[ "$1" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})-(.+)$ ]]; then
        DATE="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        NAME="${BASH_REMATCH[4]}"
    else
        DATE=""
        NAME="$1"
    fi
}

function row() {
    local href lead name trail class
    href="$1"
    lead="$2"
    name="$3"
    trail="$4"
    class="$5"

    printf '                <li><a%s href="%s"><span class="lead">%s</span><span class="name">%s</span><span class="trail">%s</span></a></li>\n' \
        "${class:+ class=\"${class}\"}" "${href}" "${lead}" "${name}" "${trail}"
}

function render() {
    local title root crumbs heading meta rows out
    title="$1"
    root="$2"
    crumbs="$3"
    heading="$4"
    meta="$5"
    rows="$6"

    out="$(<"${TEMPLATE}")"
    out="${out//'{{TITLE}}'/"${title}"}"
    out="${out//'{{ROOT}}'/"${root}"}"
    out="${out//'{{CRUMBS}}'/"${crumbs}"}"
    out="${out//'{{HEADING}}'/"${heading}"}"
    out="${out//'{{META}}'/"${meta}"}"
    out="${out//'{{ROWS}}'/"${rows}"}"
    printf '%s\n' "${out}"
}

function list_dirs() {
    find . -mindepth 1 -maxdepth 1 -type d ! -name .git -printf '%f\n' | sort
}

function list_dirs_reverse() {
    find . -mindepth 1 -maxdepth 1 -type d ! -name .git -printf '%f\n' | sort --reverse
}

function list_files() {
    find . -mindepth 1 -maxdepth 1 -type f ! -name index.html -printf '%f\n' | sort
}

function build_root() {
    local title rows count dir

    title="$1"
    rows=""
    count=0

    for dir in $(list_dirs_reverse); do
        split_name "${dir}"
        rows+="$(row "./$(escape_html "${dir}")/" "${DATE}" "$(escape_html "${NAME}")" '<span class="arrow">&rarr;</span>')"$'\n'
        count=$((count + 1))
    done

    render "${title}" "./" "" "${title}" "${count} entries" "${rows%$'\n'}"
}

function build_subfolder() {
    local parent targetDir rows count entry ext

    parent="$1"
    targetDir="$2"
    rows="$(row ".." "" ".." "parent" "up")"$'\n'
    count=0

    cd "${targetDir}" || return 1

    for entry in $(list_dirs); do
        rows+="$(row "./$(escape_html "${entry}")/" "dir" "$(escape_html "${entry}")<span class=\"slash\">/</span>" '<span class="arrow">&rarr;</span>')"$'\n'
        count=$((count + 1))
    done

    for entry in $(list_files); do
        ext="file"
        [[ "${entry}" == *.* ]] && ext="${entry##*.}"
        rows+="$(row "./$(escape_html "${entry}")" "$(escape_html "${ext}")" "$(escape_html "${entry}")" "$(human_size "$(stat -c %s "${entry}")")")"$'\n'
        count=$((count + 1))
    done

    split_name "${targetDir}"

    render \
        "$(escape_html "${NAME}") · ${parent}" \
        "../" \
        "<a href=\"..\">${parent}</a><span class=\"sep\">/</span>$(escape_html "${targetDir}")" \
        "$(escape_html "${NAME}")" \
        "${DATE:+${DATE} · }${count} item$([ "${count}" -eq 1 ] || echo s)" \
        "${rows%$'\n'}"
}


build_root "slop-bucket" > index.html

for dir in $(list_dirs); do
    (build_subfolder "slop-bucket" "${dir}") > "${dir}/index.html"
done

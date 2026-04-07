#!/usr/bin/env bash
# =============================================================================
# install.sh — Install <TOOLSET_NAME> to a user IDL directory
#
# Usage:
#   ./install.sh                         # installs .pro files to default INSTALL_BASE
#   ./install.sh /path/to/idl/dir        # installs to specified directory
#   ./install.sh --docs                  # installs .pro files + idl_docs
#   ./install.sh /path/to/idl/dir --docs # both
# =============================================================================

# -----------------------------------------------------------------------------
# USER-DEFINED VARIABLES — edit these for each toolset
# -----------------------------------------------------------------------------

TOOLSET_NAME="nsp"          # name of the toolset; becomes the install subdir
INSTALL_BASE="${HOME}/idl/devel"        # default base install directory if none specified
BACKUP_EXISTING=true              # set to false to overwrite without backup
DOCS_SUBDIR="idl_docs"           # name of the documentation subdirectory in the repo

# -----------------------------------------------------------------------------
# DERIVED VARIABLES — do not edit below this line
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
DOCS_SRC_DIR="${SCRIPT_DIR}/${DOCS_SUBDIR}"
VERSION_FILE="${SCRIPT_DIR}/VERSION"

if [ -f "${VERSION_FILE}" ]; then
    VERSION=$(cat "${VERSION_FILE}")
else
    INSTALL_DATE=$(date +"%Y-%m-%d")
    VERSION="${TOOLSET_NAME}_no-version_installed-${INSTALL_DATE}"
    echo "WARNING: VERSION file not found in ${SCRIPT_DIR}"
    echo "         Using generated version string: ${VERSION}"
    echo ""
fi

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

INSTALL_DOCS=false

for arg in "$@"; do
    case "$arg" in
        --docs)
            INSTALL_DOCS=true
            ;;
        --*)
            echo "ERROR: Unknown option: $arg"
            echo "Usage: ./install.sh [destination] [--docs]"
            exit 1
            ;;
        *)
            # treat any non-flag argument as the destination
            INSTALL_BASE="$arg"
            ;;
    esac
done

INSTALL_DIR="${INSTALL_BASE}/${TOOLSET_NAME}"
DOCS_INSTALL_DIR="${INSTALL_DIR}/${DOCS_SUBDIR}"

# =============================================================================
# FUNCTIONS
# =============================================================================

# Check whether INSTALL_DIR appears in the IDL path environment.
# IDL_PATH is the shell env var that seeds !PATH at IDL startup.
# This is informational only — the install proceeds regardless.
check_idl_path() {
    echo ""
    echo "--- !PATH check (informational) ---"

    # Prefer a live IDL check if idl is available
    if command -v idl &>/dev/null; then
        IDL_PATH_LIVE=$(idl -quiet -e \
            "print, !PATH" 2>/dev/null | tail -1)
    fi

    # Fall back to the IDL_PATH environment variable
    SEARCH_PATH="${IDL_PATH_LIVE:-${IDL_PATH:-}}"

    if [ -z "$SEARCH_PATH" ]; then
        echo "  Could not determine IDL !PATH (IDL not found and IDL_PATH not set)."
        echo "  After installing, ensure the following is in your startup.pro:"
        echo "    !PATH = expand_path('+${INSTALL_DIR}') + ':' + !PATH"
    else
        if echo "$SEARCH_PATH" | grep -q "${INSTALL_DIR}"; then
            echo "  OK: ${INSTALL_DIR} is already on your IDL !PATH."
        else
            echo "  NOTE: ${INSTALL_DIR} was NOT found on your IDL !PATH."
            echo "  Add the following to your startup.pro:"
            echo "    !PATH = expand_path('+${INSTALL_DIR}') + ':' + !PATH"
        fi
    fi
    echo "-----------------------------------"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo "Installing ${TOOLSET_NAME} v${VERSION}"
echo "  Source      : ${SRC_DIR}"
echo "  Destination : ${INSTALL_DIR}"
echo "  Install docs: ${INSTALL_DOCS}"
echo ""

# --- validate source ---
if [ ! -d "${SRC_DIR}" ]; then
    echo "ERROR: Source directory not found: ${SRC_DIR}"
    exit 1
fi

# --- validate docs source if requested ---
if [ "${INSTALL_DOCS}" = true ] && [ ! -d "${DOCS_SRC_DIR}" ]; then
    echo "ERROR: Documentation directory not found: ${DOCS_SRC_DIR}"
    echo "       (remove --docs flag or create the directory)"
    exit 1
fi

# --- create destination ---
if [ ! -d "${INSTALL_DIR}" ]; then
    mkdir -p "${INSTALL_DIR}" || { echo "ERROR: Could not create ${INSTALL_DIR}"; exit 1; }
    echo "  Created directory: ${INSTALL_DIR}"
fi

# --- copy .pro files ---
INSTALLED=0
BACKED_UP=0

for f in "${SRC_DIR}"/*.pro; do
    [ -e "$f" ] || { echo "  WARNING: No .pro files found in ${SRC_DIR}"; break; }
    base=$(basename "$f")
    target="${INSTALL_DIR}/${base}"

    if [ -f "${target}" ] && [ "${BACKUP_EXISTING}" = true ]; then
        cp "${target}" "${target}.bak"
        echo "  backed up : ${base}.bak"
        BACKED_UP=$((BACKED_UP + 1))
    fi

    cp "$f" "${target}"
    echo "  installed : ${base}"
    INSTALLED=$((INSTALLED + 1))
done

# --- write version stub ---
VERSION_PRO="${INSTALL_DIR}/${TOOLSET_NAME}_version.pro"
cat > "${VERSION_PRO}" <<EOF
; Auto-generated by install.sh — do not edit
function ${TOOLSET_NAME}_version
  return, '${VERSION}'
end
EOF
echo "  installed : ${TOOLSET_NAME}_version.pro  (version stub)"

# --- copy documentation if requested ---
if [ "${INSTALL_DOCS}" = true ]; then
    echo ""
    echo "  Installing documentation → ${DOCS_INSTALL_DIR}"
    mkdir -p "${DOCS_INSTALL_DIR}" || { echo "ERROR: Could not create ${DOCS_INSTALL_DIR}"; exit 1; }
    cp -r "${DOCS_SRC_DIR}/." "${DOCS_INSTALL_DIR}/"
    DOC_COUNT=$(find "${DOCS_INSTALL_DIR}" -type f | wc -l | tr -d ' ')
    echo "  installed : ${DOC_COUNT} documentation file(s) in ${DOCS_SUBDIR}/"
fi

# --- summary ---
echo ""
echo "Done. ${INSTALLED} .pro file(s) installed, ${BACKED_UP} backup(s) created."
if [ "${INSTALL_DOCS}" = true ]; then
    echo "      Documentation installed in ${DOCS_INSTALL_DIR}"
fi

# --- !PATH check ---
check_idl_path

exit 0

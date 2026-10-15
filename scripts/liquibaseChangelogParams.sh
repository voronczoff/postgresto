# Changelog -D parameters from repo-root .env (PGSCHEMAS, VITE_*_TABLE).
# Source after .env is loaded. Sets LIQUIBASE_CHANGELOG_PARAMS for apply scripts.
# Pass AFTER the Liquibase command, e.g. liquibase … update "${LIQUIBASE_CHANGELOG_PARAMS[@]}"

PGSCHEMAS="${PGSCHEMAS:?PGSCHEMAS is required}"
VITE_CONFIG_TABLE="${VITE_CONFIG_TABLE:-config}"
VITE_MENU_TABLE="${VITE_MENU_TABLE:-menu}"
VITE_VIEW_TABLE="${VITE_VIEW_TABLE:-view}"
VITE_SEARCH_TABLE="${VITE_SEARCH_TABLE:-search}"

_lb_require_ident() {
  local name="$1" val="$2"
  if [[ ! "$val" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Invalid $name='$val' (expected a simple SQL identifier)" >&2
    exit 1
  fi
}

IFS=',' read -r -a _lb_schemas <<< "$PGSCHEMAS"
if [ "${#_lb_schemas[@]}" -eq 0 ]; then
  echo "PGSCHEMAS must contain at least one schema" >&2
  exit 1
fi

_lb_normalized_schemas=()
for _lb_schema in "${_lb_schemas[@]}"; do
  _lb_schema="${_lb_schema#"${_lb_schema%%[![:space:]]*}"}"
  _lb_schema="${_lb_schema%"${_lb_schema##*[![:space:]]}"}"
  _lb_require_ident PGSCHEMAS "$_lb_schema"
  _lb_normalized_schemas+=("$_lb_schema")
done
PGSCHEMAS="$(IFS=,; echo "${_lb_normalized_schemas[*]}")"
APPSCHEMA="${_lb_normalized_schemas[0]}"

_lb_require_ident VITE_CONFIG_TABLE "$VITE_CONFIG_TABLE"
_lb_require_ident VITE_MENU_TABLE "$VITE_MENU_TABLE"
_lb_require_ident VITE_VIEW_TABLE "$VITE_VIEW_TABLE"
_lb_require_ident VITE_SEARCH_TABLE "$VITE_SEARCH_TABLE"

LIQUIBASE_CHANGELOG_PARAMS=(
  -Dpgschemas="$PGSCHEMAS"
  -Dappschema="$APPSCHEMA"
  -Dconfig.table="$VITE_CONFIG_TABLE"
  -Dmenu.table="$VITE_MENU_TABLE"
  -Dview.table="$VITE_VIEW_TABLE"
  -Dsearch.table="$VITE_SEARCH_TABLE"
)

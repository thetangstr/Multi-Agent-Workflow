#!/bin/sh
# Multi-Agent-Workflow v6 — Interactive Setup
# POSIX sh compatible. Run from the MAW template root directory.
set -e

# ── Colors ──────────────────────────────────────────────────────────────────

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
  BOLD="$(tput bold)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  CYAN="$(tput setaf 6)"
  RESET="$(tput sgr0)"
else
  BOLD="" RED="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

info()    { printf '%s[INFO]%s  %s\n' "$CYAN"   "$RESET" "$1"; }
success() { printf '%s[OK]%s    %s\n' "$GREEN"  "$RESET" "$1"; }
warn()    { printf '%s[WARN]%s  %s\n' "$YELLOW" "$RESET" "$1"; }
error()   { printf '%s[ERROR]%s %s\n' "$RED"    "$RESET" "$1" >&2; }
fatal()   { error "$1"; exit 1; }

banner() {
  printf '\n%s%s══════════════════════════════════════════════════════════%s\n' "$BOLD" "$CYAN" "$RESET"
  printf '%s%s  Multi-Agent-Workflow v6 — Setup%s\n' "$BOLD" "$CYAN" "$RESET"
  printf '%s%s══════════════════════════════════════════════════════════%s\n\n' "$BOLD" "$CYAN" "$RESET"
}

separator() {
  printf '\n%s──────────────────────────────────────────────────────────%s\n\n' "$CYAN" "$RESET"
}

# ── Validation functions ────────────────────────────────────────────────────

validate_nonempty() {
  # $1 = value, $2 = field name
  if [ -z "$1" ]; then
    error "$2 cannot be empty."
    return 1
  fi
  return 0
}

validate_url() {
  # $1 = value, $2 = field name
  validate_nonempty "$1" "$2" || return 1
  case "$1" in
    https://*|http://*)
      return 0
      ;;
    *)
      error "$2 must start with http:// or https://"
      return 1
      ;;
  esac
}

validate_repo() {
  # $1 = value — must be owner/name format
  validate_nonempty "$1" "GitHub repo" || return 1
  case "$1" in
    */*)
      # At least one char on each side of the slash
      _owner="${1%%/*}"
      _name="${1#*/}"
      if [ -z "$_owner" ] || [ -z "$_name" ]; then
        error "GitHub repo must be in owner/name format (e.g., acme/my-app)."
        return 1
      fi
      return 0
      ;;
    *)
      error "GitHub repo must be in owner/name format (e.g., acme/my-app)."
      return 1
      ;;
  esac
}

validate_email() {
  # $1 = value
  validate_nonempty "$1" "Email" || return 1
  case "$1" in
    *@*.*)
      return 0
      ;;
    *)
      error "Email must contain @ and a domain (e.g., test@example.com)."
      return 1
      ;;
  esac
}

# ── Prompt with validation ──────────────────────────────────────────────────

# prompt_value VAR_NAME "prompt text" "default" validator [validator_arg]
prompt_value() {
  _var="$1"
  _prompt="$2"
  _default="$3"
  _validator="${4:-validate_nonempty}"
  _validator_label="${5:-$_prompt}"

  while true; do
    if [ -n "$_default" ]; then
      printf '%s%s%s [%s]: ' "$BOLD" "$_prompt" "$RESET" "$_default"
    else
      printf '%s%s%s: ' "$BOLD" "$_prompt" "$RESET"
    fi
    read -r _input
    _value="${_input:-$_default}"

    if "$_validator" "$_value" "$_validator_label"; then
      eval "$_var=\"\$_value\""
      return 0
    fi
  done
}

# ── Confirm yes/no ──────────────────────────────────────────────────────────

confirm() {
  # $1 = prompt, default is no
  printf '%s (y/N): ' "$1"
  read -r _ans
  case "$_ans" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Count placeholder occurrences ───────────────────────────────────────────

count_placeholder() {
  # $1 = placeholder pattern (e.g., {{ISSUE_PREFIX}})
  # Returns count via stdout
  _count=$(grep -r --include='*.md' --include='*.ts' --include='*.yml' --include='*.yaml' \
    --include='*.json' --include='*.sh' --include='*.js' --include='*.toml' \
    -l "$1" . 2>/dev/null | grep -v node_modules | grep -v '.git/' | wc -l)
  echo "$_count" | tr -d ' '
}

# ── Safe sed (macOS + GNU) ──────────────────────────────────────────────────

portable_sed() {
  # $1 = pattern, $2 = replacement, $3 = file
  # Uses a temp file to avoid sed -i portability issues
  _sedtmp="${3}.maw-sed-tmp"
  sed "s|$1|$2|g" "$3" > "$_sedtmp"
  mv "$_sedtmp" "$3"
}

# ── Replace a placeholder across all relevant files ─────────────────────────

replace_in_tree() {
  # $1 = placeholder (literal string, e.g., {{ISSUE_PREFIX}})
  # $2 = replacement value
  _placeholder="$1"
  _replacement="$2"
  _files_changed=0

  # Escape special characters in replacement for sed
  _escaped_replacement=$(printf '%s' "$_replacement" | sed 's|[&/\]|\\&|g')

  # Find files containing the placeholder (skip node_modules, .git, binaries)
  _matches=$(grep -r --include='*.md' --include='*.ts' --include='*.yml' --include='*.yaml' \
    --include='*.json' --include='*.sh' --include='*.js' --include='*.toml' \
    -l "$_placeholder" . 2>/dev/null | grep -v node_modules | grep -v '.git/' || true)

  for _file in $_matches; do
    portable_sed "$_placeholder" "$_escaped_replacement" "$_file"
    _files_changed=$((_files_changed + 1))
  done

  echo "$_files_changed"
}

# ════════════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════════════

banner

# ── Pre-flight checks ──────────────────────────────────────────────────────

MAW_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$MAW_ROOT"

if [ ! -d "commands" ] && [ ! -f "commands/workon.md" ]; then
  # Try one level up or current dir
  if [ -d "./commands" ]; then
    : # already in the right place
  else
    warn "No commands/ directory found in $MAW_ROOT."
    warn "Expected to run from the MAW template root."
    if ! confirm "Continue anyway?"; then
      exit 1
    fi
  fi
fi

info "Working directory: $MAW_ROOT"

# ── Detect existing config ──────────────────────────────────────────────────

if [ -f ".maw-config" ]; then
  warn "Existing .maw-config found."
  if ! confirm "Overwrite existing configuration?"; then
    info "Aborting. Existing config preserved."
    exit 0
  fi
fi

# ── Gather values ───────────────────────────────────────────────────────────

separator
info "Enter values for each placeholder. Press Enter to accept defaults (shown in brackets)."
printf '\n'

prompt_value ISSUE_PREFIX   "Issue prefix (Linear team prefix)"   ""  validate_nonempty  "Issue prefix"
prompt_value TEAM_NAME      "Team name"                           ""  validate_nonempty  "Team name"
prompt_value PRODUCTION_URL "Production URL"                      ""  validate_url       "Production URL"
prompt_value STAGING_URL    "Staging URL"                         ""  validate_url       "Staging URL"
prompt_value GITHUB_REPO    "GitHub repo (owner/name)"            ""  validate_repo      "GitHub repo"
prompt_value OTA_REGISTRY   "OTA registry URL"                    ""  validate_url       "OTA registry URL"
prompt_value TEST_EMAIL     "Test user email"                     ""  validate_email     "Test user email"
prompt_value TEST_PASSWORD  "Test user password"                  ""  validate_nonempty  "Test user password"

# ── Summary ─────────────────────────────────────────────────────────────────

separator
printf '%s%sSummary of replacements:%s\n\n' "$BOLD" "$CYAN" "$RESET"

printf '  %-24s  %s\n' "{{ISSUE_PREFIX}}"      "$ISSUE_PREFIX"
printf '  %-24s  %s\n' "{{TEAM_NAME}}"         "$TEAM_NAME"
printf '  %-24s  %s\n' "{{PRODUCTION_URL}}"     "$PRODUCTION_URL"
printf '  %-24s  %s\n' "{{STAGING_URL}}"        "$STAGING_URL"
printf '  %-24s  %s\n' "{{GITHUB_REPO}}"        "$GITHUB_REPO"
printf '  %-24s  %s\n' "{{OTA_REGISTRY_URL}}"   "$OTA_REGISTRY"
printf '  %-24s  %s\n' "{{TEST_USER_EMAIL}}"    "$TEST_EMAIL"
printf '  %-24s  %s\n' "{{TEST_USER_PASSWORD}}" "********"
printf '\n'

# Count occurrences before replacement
info "Scanning for placeholders..."

N_PREFIX=$(count_placeholder '{{ISSUE_PREFIX}}')
N_TEAM=$(count_placeholder '{{TEAM_NAME}}')
N_PROD=$(count_placeholder '{{PRODUCTION_URL}}')
N_STAGE=$(count_placeholder '{{STAGING_URL}}')
N_REPO=$(count_placeholder '{{GITHUB_REPO}}')
N_OTA=$(count_placeholder '{{OTA_REGISTRY_URL}}')
N_EMAIL=$(count_placeholder '{{TEST_USER_EMAIL}}')
N_PASS=$(count_placeholder '{{TEST_USER_PASSWORD}}')

printf '  %-24s  %s files\n' "{{ISSUE_PREFIX}}"      "$N_PREFIX"
printf '  %-24s  %s files\n' "{{TEAM_NAME}}"         "$N_TEAM"
printf '  %-24s  %s files\n' "{{PRODUCTION_URL}}"     "$N_PROD"
printf '  %-24s  %s files\n' "{{STAGING_URL}}"        "$N_STAGE"
printf '  %-24s  %s files\n' "{{GITHUB_REPO}}"        "$N_REPO"
printf '  %-24s  %s files\n' "{{OTA_REGISTRY_URL}}"   "$N_OTA"
printf '  %-24s  %s files\n' "{{TEST_USER_EMAIL}}"    "$N_EMAIL"
printf '  %-24s  %s files\n' "{{TEST_USER_PASSWORD}}" "$N_PASS"
printf '\n'

TOTAL=$((N_PREFIX + N_TEAM + N_PROD + N_STAGE + N_REPO + N_OTA + N_EMAIL + N_PASS))
if [ "$TOTAL" -eq 0 ]; then
  warn "No placeholder occurrences found in the current directory."
  warn "Either the placeholders have already been replaced, or you are in the wrong directory."
  if ! confirm "Continue with config file creation anyway?"; then
    exit 1
  fi
fi

if ! confirm "Apply these replacements?"; then
  info "Aborted."
  exit 0
fi

# ── Apply replacements ─────────────────────────────────────────────────────

separator
info "Applying replacements..."

R1=$(replace_in_tree '{{ISSUE_PREFIX}}'      "$ISSUE_PREFIX")
R2=$(replace_in_tree '{{TEAM_NAME}}'         "$TEAM_NAME")
R3=$(replace_in_tree '{{PRODUCTION_URL}}'    "$PRODUCTION_URL")
R4=$(replace_in_tree '{{STAGING_URL}}'       "$STAGING_URL")
R5=$(replace_in_tree '{{GITHUB_REPO}}'       "$GITHUB_REPO")
R6=$(replace_in_tree '{{OTA_REGISTRY_URL}}'  "$OTA_REGISTRY")
R7=$(replace_in_tree '{{TEST_USER_EMAIL}}'   "$TEST_EMAIL")
R8=$(replace_in_tree '{{TEST_USER_PASSWORD}}' "$TEST_PASSWORD")

TOTAL_CHANGED=$((R1 + R2 + R3 + R4 + R5 + R6 + R7 + R8))
success "Replaced placeholders across $TOTAL_CHANGED file(s)."

# ── Validation pass ─────────────────────────────────────────────────────────

separator
info "Running validation pass — checking for remaining {{ }} placeholders..."

REMAINING=$(grep -r --include='*.md' --include='*.ts' --include='*.yml' --include='*.yaml' \
  --include='*.json' --include='*.sh' --include='*.js' --include='*.toml' \
  -n '{{[A-Z_]*}}' . 2>/dev/null | grep -v node_modules | grep -v '.git/' | grep -v '.maw-config' || true)

if [ -n "$REMAINING" ]; then
  warn "Unreplaced placeholders found:"
  printf '\n'
  echo "$REMAINING" | while IFS= read -r line; do
    printf '  %s%s%s\n' "$YELLOW" "$line" "$RESET"
  done
  printf '\n'
  warn "You may need to replace these manually."
else
  success "No remaining placeholders. All clean."
fi

# ── Write .maw-config ──────────────────────────────────────────────────────

separator
info "Writing .maw-config..."

cat > .maw-config <<MAWEOF
# Multi-Agent-Workflow v6 configuration
# Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
#
# This file is for reference only. Values have already been applied
# to the template files. Do not commit secrets to version control.

ISSUE_PREFIX=$ISSUE_PREFIX
TEAM_NAME=$TEAM_NAME
PRODUCTION_URL=$PRODUCTION_URL
STAGING_URL=$STAGING_URL
GITHUB_REPO=$GITHUB_REPO
OTA_REGISTRY_URL=$OTA_REGISTRY
TEST_USER_EMAIL=$TEST_EMAIL
# TEST_USER_PASSWORD is omitted for security — stored at setup time only.
MAWEOF

success "Wrote .maw-config"

# ── Optional: copy commands/ to target project ─────────────────────────────

separator
if [ -d "commands" ]; then
  if confirm "Copy commands/ to a project's .claude/commands/ directory?"; then
    printf '%sTarget project root%s: ' "$BOLD" "$RESET"
    read -r TARGET_PROJECT

    # Expand ~ if present
    case "$TARGET_PROJECT" in
      "~"*) TARGET_PROJECT="$HOME${TARGET_PROJECT#\~}" ;;
    esac

    if [ ! -d "$TARGET_PROJECT" ]; then
      error "Directory does not exist: $TARGET_PROJECT"
    else
      TARGET_DIR="$TARGET_PROJECT/.claude/commands"
      mkdir -p "$TARGET_DIR"

      _copied=0
      for _cmd_file in commands/*.md; do
        [ -f "$_cmd_file" ] || continue
        _basename=$(basename "$_cmd_file")
        if [ -f "$TARGET_DIR/$_basename" ]; then
          warn "$_basename already exists in target. Overwriting."
        fi
        cp "$_cmd_file" "$TARGET_DIR/$_basename"
        _copied=$((_copied + 1))
      done

      success "Copied $_copied command file(s) to $TARGET_DIR"
    fi
  fi
fi

# ── Optional: set up GitHub Actions workflows ──────────────────────────────

separator
if [ -d "workflows" ]; then
  if confirm "Set up GitHub Actions workflows in a project?"; then
    printf '%sTarget project root%s (leave blank to reuse previous): ' "$BOLD" "$RESET"
    read -r WORKFLOW_PROJECT
    WORKFLOW_PROJECT="${WORKFLOW_PROJECT:-$TARGET_PROJECT}"

    case "$WORKFLOW_PROJECT" in
      "~"*) WORKFLOW_PROJECT="$HOME${WORKFLOW_PROJECT#\~}" ;;
    esac

    if [ -z "$WORKFLOW_PROJECT" ] || [ ! -d "$WORKFLOW_PROJECT" ]; then
      error "Directory does not exist: ${WORKFLOW_PROJECT:-<empty>}"
    else
      GH_DIR="$WORKFLOW_PROJECT/.github/workflows"
      mkdir -p "$GH_DIR"

      _wf_copied=0
      for _wf_file in workflows/*.yml workflows/*.yaml; do
        [ -f "$_wf_file" ] || continue
        _basename=$(basename "$_wf_file")
        if [ -f "$GH_DIR/$_basename" ]; then
          warn "$_basename already exists. Overwriting."
        fi
        cp "$_wf_file" "$GH_DIR/$_basename"
        _wf_copied=$((_wf_copied + 1))
      done

      if [ "$_wf_copied" -gt 0 ]; then
        success "Copied $_wf_copied workflow file(s) to $GH_DIR"
      else
        warn "No .yml/.yaml files found in workflows/."
      fi
    fi
  fi
fi

# ── Done ────────────────────────────────────────────────────────────────────

separator
printf '%s%s  Setup complete.%s\n\n' "$BOLD" "$GREEN" "$RESET"
info "Config saved to:  $MAW_ROOT/.maw-config"
if [ -n "$REMAINING" ]; then
  warn "Review the unreplaced placeholders listed above."
fi
info "Run your verification suite to confirm everything works."
printf '\n'

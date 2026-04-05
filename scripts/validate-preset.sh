#!/usr/bin/env bash
set -euo pipefail

PRESET_FILE="${1:-}"
if [[ -z "$PRESET_FILE" ]]; then
  echo "Usage: validate-preset.sh <path-to-preset.json>" >&2
  exit 1
fi

if [[ ! -f "$PRESET_FILE" ]]; then
  echo "ERROR: File not found: $PRESET_FILE" >&2
  exit 1
fi

# Verify valid JSON
if ! jq . "$PRESET_FILE" > /dev/null 2>&1; then
  echo "ERROR: $PRESET_FILE is not valid JSON" >&2
  exit 1
fi

check_field() {
  local field_name="$1"
  local jq_expr="$2"
  local expected_type="$3"
  if ! jq -e "$jq_expr" "$PRESET_FILE" > /dev/null 2>&1; then
    echo "ERROR: Missing or invalid field '$field_name' (expected: $expected_type)" >&2
    exit 1
  fi
}

# Top-level required fields
check_field "id"          '.id | type == "string"'                              "string"
check_field "name"        '.name | type == "string"'                            "string"
check_field "description" '.description | type == "string"'                     "string"
check_field "form"        '.form | type == "string"'                            "string"
check_field "version"     '.version | type == "string"'                         "string"
check_field "goals"       '.goals | type == "array" and length > 0'             "non-empty array"
check_field "stages"      '.stages | type == "array" and length > 2'            "array with at least 3 entries"

# Voice fields
check_field "voice"                '.voice | type == "object"'                  "object"
check_field "voice.tone"           '.voice.tone | type == "string"'             "string"
check_field "voice.formality"      '.voice.formality | type == "string"'        "string"
check_field "voice.sentenceLength" '.voice.sentenceLength | type == "string"'   "string"
check_field "voice.paragraphStyle" '.voice.paragraphStyle | type == "string"'   "string"
check_field "voice.rhetoricalStyle"'.voice.rhetoricalStyle | type == "string"'  "string"

# Structure fields
check_field "structure"                    '.structure | type == "object"'                              "object"
check_field "structure.expectedSections"   '.structure.expectedSections | type == "array" and length > 0' "non-empty array"
check_field "structure.sectionOrder"       '.structure.sectionOrder | type == "string"'                "string"
check_field "structure.paragraphPatterns"  '.structure.paragraphPatterns | type == "array" and length > 0' "non-empty array"
check_field "structure.introStyle"         '.structure.introStyle | type == "string"'                  "string"
check_field "structure.endingStyle"        '.structure.endingStyle | type == "string"'                 "string"

# Rubric fields
check_field "rubric"                   '.rubric | type == "object"'                             "object"
check_field "rubric.criteria"          '.rubric.criteria | type == "array" and length > 0'      "non-empty array"
check_field "rubric.passing_threshold" '.rubric.passing_threshold | type == "number"'           "number"
check_field "rubric.critical_criteria" '.rubric.critical_criteria | type == "array" and length > 0' "non-empty array"

# Constraints fields
check_field "constraints"                                  '.constraints | type == "object"'                   "object"
check_field "constraints.no_citation_invention"            '.constraints.no_citation_invention == true'        "true (boolean)"
check_field "constraints.no_stance_shift"                  '.constraints.no_stance_shift == true'              "true (boolean)"

# Transformations fields
check_field "transformations"               '.transformations | type == "object"'                      "object"
check_field "transformations.preserveVoice" '.transformations.preserveVoice | type == "boolean"'      "boolean"

# Examples field
check_field "examples" '.examples | type == "array"' "array"

# Verify rubric weights sum to 1.0 (within 0.01 tolerance)
WEIGHT_SUM=$(jq '[.rubric.criteria[].weight] | add' "$PRESET_FILE")
if ! echo "$WEIGHT_SUM" | awk '{ if ($1 < 0.99 || $1 > 1.01) exit 1 }'; then
  echo "ERROR: rubric.criteria weights sum to $WEIGHT_SUM -- must sum to 1.0 (+/- 0.01)" >&2
  exit 1
fi

# Verify critical_criteria contains required entries
if ! jq -e '.rubric.critical_criteria | contains(["factual_integrity", "voice_preservation"])' "$PRESET_FILE" > /dev/null 2>&1; then
  echo "ERROR: rubric.critical_criteria must include 'factual_integrity' and 'voice_preservation'" >&2
  exit 1
fi

# Verify each rubric criterion has name, description, weight
INVALID=$(jq '[.rubric.criteria[] | select(.name == null or .description == null or .weight == null)] | length' "$PRESET_FILE")
if [[ "$INVALID" -gt 0 ]]; then
  echo "ERROR: $INVALID rubric criteria missing required fields (name, description, weight)" >&2
  exit 1
fi

echo "OK: $PRESET_FILE is valid"

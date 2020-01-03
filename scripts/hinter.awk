BEGIN {
  n_matches = 0;
  n_lines = 0;

  finger_patterns = ENVIRON["FINGERS_PATTERNS"];
  fingers_compact_hints = ENVIRON["FINGERS_COMPACT_HINTS"];

  if (fingers_compact_hints)
    fingers_hint_position = ENVIRON["FINGERS_HINT_POSITION"];
  else
    fingers_hint_position = ENVIRON["FINGERS_HINT_POSITION_NOCOMPACT"];

  if (fingers_compact_hints) {
    hint_format = ENVIRON["FINGERS_HINT_FORMAT"]
    hint_format_nocolor = ENVIRON["FINGERS_HINT_FORMAT_NOCOLOR"]
    highlight_format = ENVIRON["FINGERS_HIGHLIGHT_FORMAT"]
    highlight_format_nocolor = ENVIRON["FINGERS_HIGHLIGHT_FORMAT_NOCOLOR"]
    selected_highlight_format = ENVIRON["FINGERS_SELECTED_HIGHLIGHT_FORMAT"]
    selected_highlight_format_nocolor = ENVIRON["FINGERS_SELECTED_HIGHLIGHT_FORMAT_NOCOLOR"]
    selected_hint_format = ENVIRON["FINGERS_SELECTED_HINT_FORMAT"]
    selected_hint_format_nocolor = ENVIRON["FINGERS_SELECTED_HINT_FORMAT_NOCOLOR"]
  } else {
    hint_format = ENVIRON["FINGERS_HINT_FORMAT_NOCOMPACT"]
    highlight_format = ENVIRON["FINGERS_HIGHLIGHT_FORMAT_NOCOMPACT"]
    hint_format_nocolor = ENVIRON["FINGERS_HINT_FORMAT_NOCOMPACT_NOCOLOR"]
    highlight_format_nocolor = ENVIRON["FINGERS_HIGHLIGHT_FORMAT_NOCOMPACT_NOCOLOR"]
    selected_highlight_format = ENVIRON["FINGERS_SELECTED_HIGHLIGHT_FORMAT_NOCOMPACT"]
    selected_highlight_format_nocolor = ENVIRON["FINGERS_SELECTED_HIGHLIGHT_FORMAT_NOCOMPACT_NOCOLOR"]
    selected_hint_format = ENVIRON["FINGERS_SELECTED_HINT_FORMAT_NOCOMPACT"]
    selected_hint_format_nocolor = ENVIRON["FINGERS_SELECTED_HINT_FORMAT_NOCOMPACT_NOCOLOR"]
  }

  if (fingers_hint_position == "left") {
    general_compound_format = hint_format highlight_format
    selected_compound_format = selected_hint_format selected_highlight_format
  } else {
    general_compound_format = highlight_format hint_format
    selected_compound_format = selected_highlight_format selected_hint_format
  }

  hint_lookup = ""

  split(ENVIRON["FINGERS_SELECTED_HINTS"], selected_hints_arr, ":")

  for (i = 1; i <= length(selected_hints_arr); ++i) {
    selected_hints_lookup[selected_hints_arr[i]] = 1
  }

}

{
  lines[n_lines] = $0

  pos = 0;
  n_tokens = 0

  line = $0

  while (match(line, finger_patterns)) {
    n_matches++
    col_pos = RSTART;

    pre_match = substr(line, 0, col_pos - 1);
    post_match = substr(line, col_pos + RLENGTH, length(line) - 1);
    match_token = substr(line, RSTART, RLENGTH);

    tokens_by_line[n_lines][n_tokens]["value"] = pre_match
    tokens_by_line[n_lines][n_tokens]["type"] = "text"

    n_tokens++

    tokens_by_line[n_lines][n_tokens]["value"] = match_token
    tokens_by_line[n_lines][n_tokens]["type"] = "match"

    n_tokens++

    line = post_match;
  }


  if (n_tokens == 0) {
    tokens_by_line[n_lines][n_tokens]["value"] = line
    tokens_by_line[n_lines][n_tokens]["type"] = "text"
  } else if (length(post_match) > 0) {
    tokens_by_line[n_lines][n_tokens]["value"] = post_match
    tokens_by_line[n_lines][n_tokens]["type"] = "text"

    n_tokens++
  }

  n_lines++
}

END {
  hints_path = ENVIRON["FINGERS_ALPHABET_DIR"] n_matches
  getline raw_hints < hints_path
  split(raw_hints, hints, " ")

  hint_index = 1

  for (line_index = 0; line_index < n_lines; line_index++) {
    tokens_in_this_line = length(tokens_by_line[line_index])

    for (token_index = 0; token_index < tokens_in_this_line; token_index++) {
      token = tokens_by_line[line_index][token_index]["value"]
      token_type = tokens_by_line[line_index][token_index]["type"]

      if (token_type == "match") {
        hint = hint_by_match[token]

        if (!hint) {
          hint = hints[hint_index]
          hint_by_match[token] = hint
          hint_index = hint_index + 1
          hint_lookup = hint_lookup hint ":" token "\n"
        }

        if (selected_hints_lookup[hint]) {
          this_hint_format_nocolor = selected_hint_format_nocolor
          this_compound_format = selected_compound_format
        } else {
          this_hint_format_nocolor = hint_format_nocolor
          this_compound_format = general_compound_format
        }

        if (fingers_compact_hints) {
          hint_len = length(sprintf(this_hint_format_nocolor, hint))
          if (fingers_hint_position == "left")
            token = substr(token, hint_len + 1, length(token) - hint_len);
          else
            token = substr(token, 1, length(token) - hint_len);
        }

        if (fingers_hint_position == "left")
          token = sprintf(this_compound_format, hint, token);
        else
          token = sprintf(this_compound_format, token, hint);
      }

      printf "%s", token
    }

    if (line_index < n_lines - 1) {
      printf "\n"
    }
  }

  print hint_lookup | "cat 1>&3"
}

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
  } else {
    hint_format = ENVIRON["FINGERS_HINT_FORMAT_NOCOMPACT"]
    highlight_format = ENVIRON["FINGERS_HIGHLIGHT_FORMAT_NOCOMPACT"]
    hint_format_nocolor = ENVIRON["FINGERS_HINT_FORMAT_NOCOMPACT_NOCOLOR"]
    highlight_format_nocolor = ENVIRON["FINGERS_HIGHLIGHT_FORMAT_NOCOMPACT_NOCOLOR"]
  }

  if (fingers_hint_position == "left")
    compound_format = hint_format highlight_format
  else
    compound_format = highlight_format hint_format

  hint_lookup = ""
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
  }

  n_lines++
}

END {
  # TODO read alphabet root dir from ENVIRON
  hints_path = "/home/morantron/hacking/tmux-fingers/alphabets/qwerty/" n_matches
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

        if (fingers_compact_hints) {
          hint_len = length(sprintf(hint_format_nocolor, hint))
          if (fingers_hint_position == "left")
            token = substr(token, hint_len + 1, length(token) - hint_len);
          else
            token = substr(token, 1, length(token) - hint_len);
        }

        if (fingers_hint_position == "left")
          token = sprintf(compound_format, hint, token);
        else
          token = sprintf(compound_format, token, hint);
      }

      printf token
    }

    if (line_index < n_lines - 1) {
      printf "\n"
    }
  }

  print hint_lookup | "cat 1>&3"
}

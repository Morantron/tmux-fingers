BEGIN {
  n_matches = 0;

  # get hints from FINGERS_HINT_LABELS environment variable
  split(ENVIRON["FINGERS_HINT_LABELS_NOCOLOR"], a, "[[:space:]]+")
  for (i=j=0; i<length(a); i++) if (a[i]) HINTS[j++] = a[i]

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
  output_line = $0;

  # insert hints into `output_line` and accumulate hints in `hint_lookup`
  line = output_line;
  pos = col_pos_correction = 0;
  while (match(line, finger_patterns)) {
    pos += RSTART;
    col_pos = pos + col_pos_correction
    pre_match = substr(output_line, 0, col_pos - 1);
    post_match = substr(output_line, col_pos + RLENGTH, length(line) - 1);
    line_match = substr(line, RSTART, RLENGTH);

    hint = hint_by_match[line_match]
    if (!hint) {
      hint = HINTS[n_matches++]
      hint_by_match[line_match] = hint
    }
    hint_lookup = hint_lookup hint ":" line_match "\n"

    if (fingers_compact_hints) {
      hint_len = length(sprintf(hint_format_nocolor, hint))

      if (fingers_hint_position == "left")
        line_match = substr(line_match, hint_len + 1, length(line_match) - hint_len);
      else
        line_match = substr(line_match, 1, length(line_match) - hint_len);
    }

    if (fingers_hint_position == "left")
      hint_match = sprintf(compound_format, hint, line_match);
    else
      hint_match = sprintf(compound_format, line_match, hint);

    output_line = pre_match hint_match post_match;

    col_pos_correction += length(sprintf(highlight_format, line_match)) + length(sprintf(hint_format, hint)) - 1;

    line = post_match;
  }

  printf "\n%s", output_line
}

END {
  print hint_lookup | "cat 1>&3"
}

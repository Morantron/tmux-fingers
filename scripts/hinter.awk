BEGIN {
  n_matches = 0;

  HINTS[0] = "p"
  HINTS[1] = "o"
  HINTS[2] = "i"
  HINTS[3] = "u"
  HINTS[4] = "l"
  HINTS[5] = "k"
  HINTS[6] = "j"
  HINTS[7] = "t"
  HINTS[8] = "r"
  HINTS[9] = "e"
  HINTS[10] = "wj"
  HINTS[11] = "wt"
  HINTS[12] = "wr"
  HINTS[13] = "we"
  HINTS[14] = "ww"
  HINTS[15] = "wg"
  HINTS[16] = "wf"
  HINTS[17] = "wd"
  HINTS[18] = "ws"
  HINTS[19] = "wa"
  HINTS[20] = "gp"
  HINTS[21] = "go"
  HINTS[22] = "gi"
  HINTS[23] = "gu"
  HINTS[24] = "gl"
  HINTS[25] = "gk"
  HINTS[26] = "gj"
  HINTS[27] = "gt"
  HINTS[28] = "gr"
  HINTS[29] = "ge"
  HINTS[30] = "gw"
  HINTS[31] = "gg"
  HINTS[32] = "gf"
  HINTS[33] = "gd"
  HINTS[34] = "gs"
  HINTS[35] = "ga"
  HINTS[36] = "fp"
  HINTS[37] = "fo"
  HINTS[38] = "fi"
  HINTS[39] = "fu"
  HINTS[40] = "fl"
  HINTS[41] = "fk"
  HINTS[42] = "fj"
  HINTS[43] = "ft"
  HINTS[44] = "fr"
  HINTS[45] = "fe"
  HINTS[46] = "fw"
  HINTS[47] = "fg"
  HINTS[48] = "ff"
  HINTS[49] = "fd"
  HINTS[50] = "fs"
  HINTS[51] = "fa"
  HINTS[52] = "dp"
  HINTS[53] = "do"
  HINTS[54] = "di"
  HINTS[55] = "du"
  HINTS[56] = "dl"
  HINTS[57] = "dk"
  HINTS[58] = "dj"
  HINTS[59] = "dt"
  HINTS[60] = "dr"
  HINTS[61] = "de"
  HINTS[62] = "dw"
  HINTS[63] = "dg"
  HINTS[64] = "df"
  HINTS[65] = "dd"
  HINTS[66] = "ds"
  HINTS[67] = "da"
  HINTS[68] = "sp"
  HINTS[69] = "so"
  HINTS[70] = "si"
  HINTS[71] = "su"
  HINTS[72] = "sl"
  HINTS[73] = "sk"
  HINTS[74] = "sj"
  HINTS[75] = "st"
  HINTS[76] = "sr"
  HINTS[77] = "se"
  HINTS[78] = "sw"
  HINTS[79] = "sg"
  HINTS[80] = "sf"
  HINTS[81] = "sd"
  HINTS[82] = "ss"
  HINTS[83] = "sa"
  HINTS[84] = "ap"
  HINTS[85] = "ao"
  HINTS[86] = "ai"
  HINTS[87] = "au"
  HINTS[88] = "al"
  HINTS[89] = "ak"
  HINTS[90] = "aj"
  HINTS[91] = "at"
  HINTS[92] = "ar"
  HINTS[93] = "ae"
  HINTS[94] = "aw"
  HINTS[95] = "ag"
  HINTS[96] = "af"
  HINTS[97] = "ad"
  HINTS[98] = "as"
  HINTS[99] = "aa"

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

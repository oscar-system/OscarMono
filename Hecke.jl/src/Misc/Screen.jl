set_cursor_col(n::Int = 0) = "\e[$(n)G"
clear_to_eol() = "\e[0J"
set_cursor_line(n::Int = 1) = "\e[$(n)F"

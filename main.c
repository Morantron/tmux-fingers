#include <mruby.h>
#include <mruby/irep.h>
#include <mruby/array.h>
#include "./build/bytecode.c"

int
main(int argc, char *argv[])
{
  mrb_state *mrb = mrb_open();
  if (!mrb) { /* handle error */ }

  // Create a new mrb_value array to hold the command-line arguments
  mrb_value args = mrb_ary_new_capa(mrb, argc);

  // Convert each command-line argument to an mrb_value and add it to the array
  for (int i = 0; i < argc; i++) {
    mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb, argv[i]));
  }

  // Set the ARGV constant to the array of command-line arguments
  mrb_define_global_const(mrb, "ARGV", args);

  mrb_load_irep(mrb, main_ruby);
  mrb_close(mrb);
  return 0;
}

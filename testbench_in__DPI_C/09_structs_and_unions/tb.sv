// Time-stamp: <2019-01-21 15:50:37 kmodi>
// http://www.testbench.in/DP_09_PASSING_STRUCTS_AND_UNIONS.html

program main;

  // Using arrays to populate packed struct
  typedef struct packed {
    int a;
    int b;
    byte c;
  } SV_struct;

  // Array of packed structs
  typedef struct packed {
    int p;
    int q;
    // byte r;
    int r;
  } PkdStruct;
  PkdStruct arr_data [0:4];

  typedef struct {
    int p;
    int q;
    int r;
  } UnPkdStruct;
  UnPkdStruct arr_data2 [0:4];

  export "DPI-C" function export_func;
  import "DPI-C" context function void import_func();
  import "DPI-C" function void send_arr_struct_pkd (input PkdStruct arr []);

  // I cannot map the same Nim function "send_arr_struct_pkd" to
  // "send_arr_struct_pkd" and "send_arr_struct_unpkd" which accept
  // different data types. So below won't work .. I get:
  //   xmsim: *E,SIGUSR: Unix Signal SIGSEGV raised from user application code.
  // import "DPI-C" send_arr_struct_pkd = function void send_arr_struct_unpkd (input UnPkdStruct arr []);
  //
  // But instead, within Nim, I can have send_arr_struct_unpkd call
  // the send_arr_struct_pkd proc, do the below mapping, and it will
  // work!
  import "DPI-C" function void send_arr_struct_unpkd (input UnPkdStruct arr []);

  function void export_func (input int arr[3]);
    SV_struct s_data;

    $display("  SV: arr = %p", arr);
    s_data.a = arr[0];
    s_data.b = arr[1];
    s_data.c = arr[2];
    $display("  SV: s_data = %p", s_data);
  endfunction

  initial begin
    import_func();
    $display("");

    // Mon Jan 21 15:24:16 EST 2019 - kmodi
    // FIXME: Cadence Xcelium
    // The order of elements in reversed in the packaged struct sent via
    // DPI-C.
    foreach (arr_data[i]) begin
      arr_data[i] = { $random, $random, $random };
      $display("SV: arr_data[%0d] = '{p = %0d, q = %0d, r = %0d}",
               i, arr_data[i].p, arr_data[i].q, arr_data[i].r);
    end
    send_arr_struct_pkd(arr_data);

    // But then I run the same function (it's the same function call
    // if you look in the Nim code) but this time passing an
    // *unpacked* struct, and this time the order of the struct
    // elements is correct!
    foreach (arr_data2[i]) begin
      arr_data2[i].p = $random;
      arr_data2[i].q = $random;
      arr_data2[i].r = $random;
      $display("SV: arr_data2[%0d] = '{p = %0d, q = %0d, r = %0d}",
               i, arr_data2[i].p, arr_data2[i].q, arr_data2[i].r);
    end
    send_arr_struct_unpkd(arr_data2);

    $finish;
  end

endprogram

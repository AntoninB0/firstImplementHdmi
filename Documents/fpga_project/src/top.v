module top (
    input wire        pix_clk,
    input wire        hdmi4_rst_n,
    output wire [11:0] h_count_in,    // Changé de 'reg' à 'wire'
    output wire [11:0] v_count_in,    // Changé de 'reg' à 'wire'
    output wire        frame_start    // Changé de 'reg' à 'wire'
);

pixel_counters timing_gen (
    .pixel_clk(pix_clk),
    .rst_n(hdmi4_rst_n),
    .h_total(12'd1650),    // 1280x720 timing
    .v_total(12'd750),
    .h_count(h_count_in),
    .v_count(v_count_in),
    .frame_start(frame_start)
);

endmodule
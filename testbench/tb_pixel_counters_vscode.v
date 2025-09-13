`timescale 1ns/1ps

module tb_pixel_counters_vscode;
    reg clk = 0;
    reg rst_n = 0;
    wire [11:0] h_count, v_count;
    wire frame_start,vsync,hsync;
    
    pixel_counters dut (
        .pixel_clk(clk),
        .rst_n(rst_n), 
        .h_total(12'd1650),
        .h_sync(40),
        .v_sync(5),
        .hsync(hsync),
        .vsync(vsync),
        .v_total(12'd750),
        .h_count(h_count),
        .v_count(v_count),
        .frame_start(frame_start)
    );
    
    // Horloge 74.25 MHz
    always #6.735 clk = ~clk;
    
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_pixel_counters_vscode);
        $display("=== VSCode + Icarus Test ===");

        // Reset synchro
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        
        repeat (100000) @(posedge clk);
        $display("=== Test Complete ===");
        $finish;
    end
    
    integer cycle = 0;
    always @(posedge clk) begin
        cycle = cycle + 1;
        if (cycle % 10 == 0) // affiche tous les 10 cycles
            $display("cycle=%0d, t=%0t ns: H=%d V=%d F=%b",
                      cycle, $time, h_count, v_count, frame_start);
    end
endmodule

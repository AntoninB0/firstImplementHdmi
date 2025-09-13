module tb_pixel_counters_vscode;
    // Signaux
    reg clk = 0;
    reg rst_n = 0;
    wire [11:0] h_count, v_count;
    wire frame_start;
    
    // Instance
    pixel_counters dut (
        .pixel_clk(clk),
        .rst_n(rst_n), 
        .h_total(12'd10),
        .v_total(12'd5),
        .h_count(h_count),
        .v_count(v_count),
        .frame_start(frame_start)
    );
    
    // Horloge
    always #5 clk = ~clk;
    
    // Test
    initial begin
        // Pour GTKWave
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_pixel_counters_vscode);
        
        // Test
        $display("=== VSCode + Icarus Test ===");
        rst_n = 0; #50; rst_n = 1;
        
        repeat (100) @(posedge clk);
        
        $display("=== Test Complete ===");
        $finish;
    end
    
    // Monitoring
    always @(posedge clk) begin
        if ($time % 100 == 0)
            $display("t=%0t: H=%d V=%d F=%b", $time, h_count, v_count, frame_start);
    end
endmodule
module pixel_counters (
    input wire        pixel_clk,      
    input wire        rst_n,          
    input wire [11:0] h_total,        
    input wire [11:0] v_total,        
    output reg [11:0] h_count,        
    output reg [11:0] v_count,        
    output reg        frame_start     
);

// Évite les modulos coûteux - utilise des comparaisons
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        h_count <= 12'd0;
        v_count <= 12'd0;
        frame_start <= 1'b0;
    end else begin
        // Compteur horizontal
        if (h_count >= h_total - 1) begin
            h_count <= 12'd0;
            
            // Compteur vertical
            if (v_count >= v_total - 1) begin
                v_count <= 12'd0;
                frame_start <= ~frame_start;  // Début de nouvelle trame
            end else begin
                v_count <= v_count + 1;
            end
        end else begin
            h_count <= h_count + 1;
        end
    end
end


endmodule
module pixel_counters (
    input wire        pixel_clk,      
    input wire        rst_n, 
    
    // h_total = [h_sync, h_front, h_active, h_back]
    input wire [11:0] h_total,
    input wire [11:0] h_sync, 
    input wire [11:0] h_back, 
    input wire [11:0] h_active, 
    
    input wire [11:0] v_total,
    input wire [11:0] v_sync, 
    input wire [11:0] v_back, 
    input wire [11:0] v_active, 
    
    input wire        h_sync_pol,     
    input wire        v_sync_pol,

    output reg [11:0] h_count,        
    output reg [11:0] v_count,     

    output reg        hsync,          // Signl HSYNC
    output reg        vsync,          // Signal VSYNC
    output reg        data_enable,
    
    output reg        frame_start     
);




// Évite les modulos coûteux - utilise des comparaisons
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        h_count <= 12'd0;
        v_count <= 12'd0;
        frame_start <= 1'b0;
        hsync <= 1'b0;
        vsync <= 1'b0;
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
            assign vsync = (v_count < v_sync) ? 1'b1 : 1'b0;
        end else begin
            h_count <= h_count + 1;
        end
        assign hsync = (h_count < h_sync) ? 1'b1 : 1'b0;
    end
    
end


endmodule
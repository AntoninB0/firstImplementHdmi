# Série d'Exercices - Création de Modules Vidéo FPGA

## Table des Matières

1. [Exercice 1 : Compteurs de Pixels](#exercice1)
2. [Exercice 2 : Génération des Signaux de Synchronisation](#exercice2)
3. [Exercice 3 : Zone Active et Data Enable](#exercice3)
4. [Exercice 4 : Générateur de Couleurs Simples](#exercice4)
5. [Exercice 5 : Motifs Géométriques](#exercice5)
6. [Exercice 6 : Animation et Mouvement](#exercice6)
7. [Exercice 7 : Gestion Multi-Résolution](#exercice7)
8. [Exercice 8 : Encodeur TMDS Basique](#exercice8)
9. [Exercice 9 : Interface de Contrôle](#exercice9)
10. [Exercice 10 : Module Complet Intégré](#exercice10)

---

## Exercice 1 : Compteurs de Pixels {#exercice1}

### 🎯 **Objectif**
Créer les compteurs fondamentaux pour parcourir l'écran pixel par pixel.

### 📚 **Théorie**
Un écran vidéo se parcourt ligne par ligne, de gauche à droite, puis de haut en bas. Il faut deux compteurs :
- **Compteur horizontal** (X) : compte les pixels sur une ligne
- **Compteur vertical** (Y) : compte les lignes

### 📋 **Cahier des Charges**
- Module : `pixel_counters`
- Horloge : `pixel_clk` (74.25 MHz pour 720p)
- Compteurs 12 bits (support jusqu'à 4096 pixels/lignes)
- Reset asynchrone

### 💻 **Code à Développer**

```verilog
module pixel_counters (
    input wire        pixel_clk,      // Horloge pixel
    input wire        rst_n,          // Reset actif bas
    input wire [11:0] h_total,        // Total horizontal (ex: 1650)
    input wire [11:0] v_total,        // Total vertical (ex: 750)
    output reg [11:0] h_count,        // Compteur horizontal
    output reg [11:0] v_count,        // Compteur vertical
    output wire       frame_start     // Pulse début de trame
);

// À COMPLÉTER :
// 1. Compteur horizontal qui se remet à 0 quand il atteint h_total-1
// 2. Compteur vertical qui s'incrémente à chaque fin de ligne
// 3. Signal frame_start quand les deux compteurs sont à 0

endmodule
```

### ✅ **Tests à Réaliser**
1. Anti-rebond des boutons (vérifier avec LED)
2. Navigation dans tous les menus
3. Modification des paramètres
4. Affichage OSD à l'écran
5. Contrôle en temps réel avec potentiomètres

### 🎮 **Interface Utilisateur**
```
[MODE] - Changer de menu
[UP]   - Augmenter valeur
[DOWN] - Diminuer valeur  
[SEL]  - Valider/Entrer dans sous-menu

Menu Principal:
├── PATTERN (motifs)
├── ANIMATION (mouvement)  
├── COLOR (couleurs)
├── RESOLUTION (formats)
└── SYSTEM (réglages)
```

---

## Exercice 10 : Module Complet Intégré {#exercice10}

### 🎯 **Objectif**
Intégrer tous les modules précédents dans un système vidéo complet.

### 📚 **Théorie**
L'intégration système nécessite :
- **Gestion des horloges** : PLL, division, distribution
- **Pipeline des données** : synchronisation multi-étages
- **Gestion des domaines** : horloges différentes
- **Debug et monitoring** : signaux de test internes

### 📋 **Cahier des Charges**
- Module : `complete_video_system`
- Intégration de tous les exercices 1-9
- Interface HDMI complète
- Contrôle utilisateur complet
- Monitoring et debug

### 💻 **Code à Développer**

```verilog
module complete_video_system (
    // Horloges et reset
    input wire        clk_27mhz,        // Horloge d'entrée
    input wire        rst_n,            // Reset système
    
    // Interface utilisateur
    input wire        btn_mode,
    input wire        btn_up,
    input wire        btn_down,
    input wire        btn_select,
    input wire [7:0]  pot_brightness,
    input wire [7:0]  pot_speed,
    
    // Sorties HDMI
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n,
    
    // Debug et monitoring
    output wire [7:0] debug_leds,
    output wire       debug_hsync,
    output wire       debug_vsync,
    output wire       debug_de
);

// === DÉCLARATION DES SIGNAUX INTERNES ===

// Horloges générées
wire pixel_clk;
wire serial_clk;  
wire pll_locked;

// Compteurs de pixels
wire [11:0] h_count;
wire [11:0] v_count;
wire        frame_start;

// Signaux de synchronisation
wire hsync;
wire vsync;
wire data_enable;

// Paramètres de résolution
wire [11:0] h_total, h_sync_width, h_back_porch, h_active;
wire [11:0] v_total, v_sync_width, v_back_porch, v_active;
wire        h_sync_pol, v_sync_pol;

// Paramètres de contrôle
wire [2:0]  pattern_mode;
wire [2:0]  anim_mode;
wire [7:0]  brightness;
wire [7:0]  anim_speed;
wire [1:0]  resolution;
wire [7:0]  fg_color_r, fg_color_g, fg_color_b;

// Position et paramètres d'animation
wire [11:0] obj_x, obj_y, obj_size;
wire [7:0]  obj_angle;

// Données pixel RGB
wire [7:0] pixel_r, pixel_g, pixel_b;

// Données TMDS
wire [9:0] tmds_r, tmds_g, tmds_b;

// === GÉNÉRATION DES HORLOGES ===

// PLL principal : 27MHz → pixel_clk + serial_clk
video_pll u_pll (
    .clk_in(clk_27mhz),
    .rst_n(rst_n),
    .resolution(resolution),
    .pixel_clk(pixel_clk),
    .serial_clk(serial_clk),
    .locked(pll_locked)
);

// Reset synchronisé avec PLL
wire system_rst_n = rst_n & pll_locked;

// === CONTRÔLEUR DE RÉSOLUTION ===

multi_resolution_controller u_res_ctrl (
    .resolution_mode(resolution),
    .h_total(h_total),
    .h_sync(h_sync_width),
    .h_back_porch(h_back_porch),
    .h_active(h_active),
    .v_total(v_total),
    .v_sync(v_sync_width),
    .v_back_porch(v_back_porch),
    .v_active(v_active),
    .h_sync_pol(h_sync_pol),
    .v_sync_pol(v_sync_pol)
);

// === COMPTEURS DE PIXELS ===

pixel_counters u_counters (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .h_total(h_total),
    .v_total(v_total),
    .h_count(h_count),
    .v_count(v_count),
    .frame_start(frame_start)
);

// === GÉNÉRATION SYNCHRONISATIONS ===

sync_generator u_sync_gen (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .h_count(h_count),
    .v_count(v_count),
    .h_sync_width(h_sync_width),
    .v_sync_width(v_sync_width),
    .h_sync_pol(h_sync_pol),
    .v_sync_pol(v_sync_pol),
    .hsync(hsync),
    .vsync(vsync)
);

// === DATA ENABLE ===

data_enable_generator u_de_gen (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .h_count(h_count),
    .v_count(v_count),
    .h_sync_width(h_sync_width),
    .h_back_porch(h_back_porch),
    .h_active(h_active),
    .v_sync_width(v_sync_width),
    .v_back_porch(v_back_porch),
    .v_active(v_active),
    .de_delay(4'd3),  // Pipeline TMDS
    .data_enable(data_enable)
);

// === CONTRÔLEUR D'ANIMATION ===

animation_controller u_anim_ctrl (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .frame_sync(frame_start),
    .screen_width(h_active),
    .screen_height(v_active),
    .anim_mode(anim_mode),
    .speed(anim_speed),
    .obj_x(obj_x),
    .obj_y(obj_y),
    .obj_size(obj_size),
    .obj_angle(obj_angle)
);

// === GÉNÉRATEUR DE MOTIFS ===

// Pipeline des compteurs pour synchronisation
reg [11:0] h_count_d1, h_count_d2, h_count_d3;
reg [11:0] v_count_d1, v_count_d2, v_count_d3;
reg        data_enable_d1, data_enable_d2;

always @(posedge pixel_clk) begin
    // Pipeline étage 1
    h_count_d1 <= h_count;
    v_count_d1 <= v_count;
    data_enable_d1 <= data_enable;
    
    // Pipeline étage 2
    h_count_d2 <= h_count_d1;
    v_count_d2 <= v_count_d1;
    data_enable_d2 <= data_enable_d1;
    
    // Pipeline étage 3
    h_count_d3 <= h_count_d2;
    v_count_d3 <= v_count_d2;
end

// Générateur combiné motifs + géométrie
combined_pattern_generator u_pattern_gen (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .h_count(h_count_d2),
    .v_count(v_count_d2),
    .data_enable(data_enable_d2),
    .pattern_mode(pattern_mode),
    .h_active(h_active),
    .v_active(v_active),
    // Paramètres animation
    .obj_x(obj_x),
    .obj_y(obj_y),
    .obj_size(obj_size),
    // Couleurs
    .fg_color_r(fg_color_r),
    .fg_color_g(fg_color_g),
    .fg_color_b(fg_color_b),
    .brightness(brightness),
    // Sortie
    .pixel_r(pixel_r),
    .pixel_g(pixel_g),
    .pixel_b(pixel_b)
);

// === ENCODEURS TMDS ===

tmds_encoder u_tmds_r (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .data_in(pixel_r),
    .data_enable(data_enable_d2),
    .control_bit0(1'b0),
    .control_bit1(1'b0),
    .tmds_out(tmds_r)
);

tmds_encoder u_tmds_g (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .data_in(pixel_g),
    .data_enable(data_enable_d2),
    .control_bit0(1'b0),
    .control_bit1(1'b0),
    .tmds_out(tmds_g)
);

tmds_encoder u_tmds_b (
    .pixel_clk(pixel_clk),
    .rst_n(system_rst_n),
    .data_in(pixel_b),
    .data_enable(data_enable_d2),
    .control_bit0(hsync),     // C0 = HSYNC
    .control_bit1(vsync),     // C1 = VSYNC
    .tmds_out(tmds_b)
);

// === SÉRIALISEUR TMDS ===

tmds_serializer u_serializer (
    .pixel_clk(pixel_clk),
    .serial_clk(serial_clk),
    .rst_n(system_rst_n),
    .tmds_data_r(tmds_r),
    .tmds_data_g(tmds_g),
    .tmds_data_b(tmds_b),
    .tmds_clk_p(tmds_clk_p),
    .tmds_clk_n(tmds_clk_n),
    .tmds_data_p(tmds_data_p),
    .tmds_data_n(tmds_data_n)
);

// === INTERFACE DE CONTRÔLE ===

video_control_interface u_ctrl (
    .clk(clk_27mhz),  // Domaine d'horloge séparé
    .rst_n(rst_n),
    .btn_mode(btn_mode),
    .btn_up(btn_up),
    .btn_down(btn_down),
    .btn_select(btn_select),
    .pot_brightness(pot_brightness),
    .pot_speed(pot_speed),
    .uart_rx(1'b1),  // Non utilisé
    .uart_tx(),      // Non utilisé
    // Sorties
    .pattern_mode(pattern_mode),
    .anim_mode(anim_mode),
    .brightness(brightness),
    .anim_speed(anim_speed),
    .resolution(resolution),
    .fg_color_r(fg_color_r),
    .fg_color_g(fg_color_g),
    .fg_color_b(fg_color_b),
    // OSD (future extension)
    .osd_enable(),
    .osd_text_line1(),
    .osd_text_line2()
);

// === DEBUG ET MONITORING ===

// LEDs de statut
assign debug_leds = {
    2'b00,              // Bits 7:6 - réservés
    resolution,         // Bits 5:4 - mode résolution
    pattern_mode[2:1],  // Bits 3:2 - mode motif
    pll_locked,         // Bit 1 - PLL verrouillé
    frame_start         // Bit 0 - début de trame
};

// Signaux de debug
assign debug_hsync = hsync;
assign debug_vsync = vsync;
assign debug_de = data_enable;

endmodule

// === MODULES SUPPLÉMENTAIRES NÉCESSAIRES ===

// Module PLL adaptatif
module video_pll (
    input wire       clk_in,
    input wire       rst_n,
    input wire [1:0] resolution,
    output reg       pixel_clk,
    output reg       serial_clk,
    output reg       locked
);

// À implémenter selon le FPGA cible
// Gowin, Xilinx, Altera ont des primitives différentes

endmodule

// Module sérialiseur TMDS
module tmds_serializer (
    input wire        pixel_clk,
    input wire        serial_clk,
    input wire        rst_n,
    input wire [9:0]  tmds_data_r,
    input wire [9:0]  tmds_data_g,
    input wire [9:0]  tmds_data_b,
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n
);

// À implémenter avec les primitives SERDES du FPGA

endmodule

// Module générateur combiné
module combined_pattern_generator (
    input wire        pixel_clk,
    input wire        rst_n,
    input wire [11:0] h_count,
    input wire [11:0] v_count,
    input wire        data_enable,
    input wire [2:0]  pattern_mode,
    input wire [11:0] h_active,
    input wire [11:0] v_active,
    input wire [11:0] obj_x,
    input wire [11:0] obj_y,
    input wire [11:0] obj_size,
    input wire [7:0]  fg_color_r,
    input wire [7:0]  fg_color_g,
    input wire [7:0]  fg_color_b,
    input wire [7:0]  brightness,
    output reg [7:0]  pixel_r,
    output reg [7:0]  pixel_g,
    output reg [7:0]  pixel_b
);

// Combinaison des générateurs des exercices 4 et 5
// À implémenter en combinant les modules précédents

endmodule
```

### ✅ **Tests à Réaliser**
1. **Test de base** : Affichage simple 720p
2. **Test multi-résolution** : Commutation VGA/SVGA/720p
3. **Test motifs** : Tous les modes de pattern
4. **Test animation** : Mouvement fluide
5. **Test interface** : Contrôle temps réel
6. **Test performance** : Utilisation ressources FPGA
7. **Test timing** : Violations de setup/hold
8. **Test compatibilité** : Différents écrans HDMI

### 🔧 **Optimisations Avancées**

#### 1. Pipeline Performance
```verilog
// Pipeline 5 étages pour haute fréquence
reg [7:0] pixel_r_pipe [0:4];
reg [7:0] pixel_g_pipe [0:4];  
reg [7:0] pixel_b_pipe [0:4];

genvar i;
generate
    for (i=0; i<4; i=i+1) begin : pipeline_loop
        always @(posedge pixel_clk) begin
            pixel_r_pipe[i+1] <= pixel_r_pipe[i];
            pixel_g_pipe[i+1] <= pixel_g_pipe[i];
            pixel_b_pipe[i+1] <= pixel_b_pipe[i];
        end
    end
endgenerate
```

#### 2. Réduction des Ressources
```verilog
// Partage des multiplicateurs
reg [7:0] mult_a, mult_b;
wire [15:0] mult_result;

mult_shared u_mult (
    .clk(pixel_clk),
    .a(mult_a),
    .b(mult_b),
    .result(mult_result)
);

// Time-multiplexing des calculs
always @(posedge pixel_clk) begin
    case (mult_phase)
        0: begin mult_a <= obj_x; mult_b <= sine_lut; end
        1: begin mult_a <= obj_y; mult_b <= cosine_lut; end
        // ...
    endcase
end
```

### 📊 **Métriques de Performance**

| Résolution | Pixel Clock | Bandwidth | LUT Usage | FF Usage | BRAM Usage |
|-----------|-------------|-----------|-----------|----------|------------|
| VGA       | 25.2 MHz    | 76 MB/s   | ~2000     | ~1500    | 2-4        |
| SVGA      | 40 MHz      | 120 MB/s  | ~2500     | ~1800    | 2-4        |
| 720p      | 74.25 MHz   | 222 MB/s  | ~3000     | ~2200    | 4-8        |
| 1080p     | 148.5 MHz   | 445 MB/s  | ~3500     | ~2800    | 8-16       |

### 🚀 **Extensions Futures**

#### 1. Support Audio HDMI
- Intégration I2S
- Packets audio dans blanking
- Synchronisation A/V

#### 2. Framebuffer DDR
- Contrôleur mémoire
- Double buffering
- Accélération graphique

#### 3. Interface réseau
- Streaming vidéo IP
- Contrôle web
- Mise à jour OTA

## 🎓 **Conclusion des Exercices**

Félicitations ! Vous avez maintenant créé un système vidéo HDMI complet de A à Z. Cette série d'exercices vous a permis de maîtriser :

### **Compétences Acquises**
✅ Génération des signaux de timing vidéo
✅ Création de motifs et animations
✅ Encodage TMDS pour HDMI  
✅ Architecture pipeline haute performance
✅ Interface utilisateur temps réel
✅ Intégration système complexe
✅ Optimisation et debug FPGA

### **Prochaines Étapes**
1. **Portage** : Adapter à votre FPGA (Xilinx, Altera, Lattice)
2. **Optimisation** : Performance et utilisation ressources
3. **Extensions** : Audio, mémoire, réseau
4. **Projets** : Oscilloscope, analyseur, console de jeu

### **Ressources pour Aller Plus Loin**
- **HDMI 2.0 Spec** : Support 4K et HDR
- **DisplayPort** : Alternative à HDMI
- **Video over IP** : Streaming réseau
- **GPU Architecture** : Accélération graphique

Vous avez maintenant toutes les bases pour créer vos propres projets vidéo innovants ! 🚀
```

### ✅ **Tests à Réaliser**
1. Vérifier que h_count va de 0 à h_total-1
2. Vérifier que v_count s'incrémente correctement
3. Tester le signal frame_start
4. Simuler avec h_total=10, v_total=5 pour validation

### 🎁 **Solution Type**
```verilog
// Compteur horizontal
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n)
        h_count <= 12'd0;
    else if (h_count >= h_total - 1'b1)
        h_count <= 12'd0;
    else
        h_count <= h_count + 1'b1;
end

// Compteur vertical  
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n)
        v_count <= 12'd0;
    else if ((v_count >= v_total - 1'b1) && (h_count >= h_total - 1'b1))
        v_count <= 12'd0;
    else if (h_count >= h_total - 1'b1)
        v_count <= v_count + 1'b1;
end

assign frame_start = (h_count == 12'd0) && (v_count == 12'd0);
```

---

## Exercice 2 : Génération des Signaux de Synchronisation {#exercice2}

### 🎯 **Objectif**
Générer les signaux de synchronisation HSYNC et VSYNC selon le standard vidéo.

### 📚 **Théorie**
Les signaux de sync délimitent les zones de l'écran :
- **HSYNC** : synchronisation horizontale (fin de ligne)
- **VSYNC** : synchronisation verticale (fin d'image)
- **Polarité** : peut être positive ou négative selon le standard

### 📋 **Cahier des Charges**
- Module : `sync_generator`
- Utiliser les compteurs de l'exercice 1
- Configurable : durée des impulsions, polarité
- Support des standards VGA, SVGA, 720p, 1080p

### 💻 **Code à Développer**

```verilog
module sync_generator (
    input wire        pixel_clk,
    input wire        rst_n,
    input wire [11:0] h_count,        // Depuis exercice 1
    input wire [11:0] v_count,        // Depuis exercice 1
    input wire [11:0] h_sync_width,   // Largeur pulse H (ex: 40)
    input wire [11:0] v_sync_width,   // Largeur pulse V (ex: 5)
    input wire        h_sync_pol,     // Polarité H (1=positive)
    input wire        v_sync_pol,     // Polarité V (1=positive)
    output wire       hsync,          // Signal HSYNC
    output wire       vsync           // Signal VSYNC
);

// À COMPLÉTER :
// 1. Générer hsync quand h_count < h_sync_width
// 2. Générer vsync quand v_count < v_sync_width  
// 3. Appliquer la polarité (inverser si pol=0)

endmodule
```

### ✅ **Tests à Réaliser**
1. Tester avec les timings 720p :
   - h_sync_width = 40
   - v_sync_width = 5
2. Vérifier les deux polarités
3. Mesurer la durée des impulsions
4. Vérifier la fréquence de répétition

### 🧮 **Calculs de Référence (720p)**
- Fréquence ligne : 74.25MHz / 1650 = 45 kHz
- Fréquence image : 45kHz / 750 = 60 Hz
- Durée HSYNC : 40 / 74.25MHz = 539 ns

---

## Exercice 3 : Zone Active et Data Enable {#exercice3}

### 🎯 **Objectif**
Créer le signal DATA_ENABLE qui indique quand les pixels sont visibles à l'écran.

### 📚 **Théorie**
Le signal Data Enable (DE) est haut uniquement dans la zone visible de l'écran :
- **Front Porch** : zone après les données, avant sync
- **Sync** : impulsion de synchronisation  
- **Back Porch** : zone après sync, avant données
- **Active** : zone visible (DE = 1)

### 📋 **Cahier des Charges**
- Module : `data_enable_generator`
- Signal DE précis dans la zone active
- Prise en compte des porches avant/arrière
- Délais configurables pour compensation

### 💻 **Code à Développer**

```verilog
module data_enable_generator (
    input wire        pixel_clk,
    input wire        rst_n,
    input wire [11:0] h_count,
    input wire [11:0] v_count,
    input wire [11:0] h_sync_width,   // 40 pour 720p
    input wire [11:0] h_back_porch,   // 220 pour 720p
    input wire [11:0] h_active,       // 1280 pour 720p
    input wire [11:0] v_sync_width,   // 5 pour 720p
    input wire [11:0] v_back_porch,   // 20 pour 720p
    input wire [11:0] v_active,       // 720 pour 720p
    input wire [3:0]  de_delay,       // Délai pipeline (0-15)
    output reg        data_enable     // Signal DE
);

// À COMPLÉTER :
// 1. Calculer zone active horizontale
// 2. Calculer zone active verticale
// 3. DE = zone_h_active ET zone_v_active
// 4. Ajouter le délai pipeline avec shift register

wire h_active_zone = (h_count >= (h_sync_width + h_back_porch)) && 
                     (h_count < (h_sync_width + h_back_porch + h_active));

// ... À compléter

endmodule
```

### ✅ **Tests à Réaliser**
1. Vérifier les bornes de la zone active
2. Tester le délai pipeline (important pour TMDS)
3. Compter le nombre de pixels DE=1 par ligne
4. Compter le nombre de lignes DE=1 par image

### 📊 **Valeurs de Test (720p)**
- Zone H active : pixels 260 à 1539 (1280 pixels)
- Zone V active : lignes 25 à 744 (720 lignes)
- Total pixels actifs : 1280 × 720 = 921,600

---

## Exercice 4 : Générateur de Couleurs Simples {#exercice4}

### 🎯 **Objectif**
Créer un générateur de couleurs et motifs de base pour tester l'affichage.

### 📚 **Théorie**
Les couleurs vidéo sont codées en RGB :
- **R, G, B** : 8 bits chacun (0-255)
- **Couleurs primaires** : Rouge (255,0,0), Vert (0,255,0), Bleu (0,0,255)
- **Couleurs secondaires** : Jaune (255,255,0), Magenta (255,0,255), Cyan (0,255,255)

### 📋 **Cahier des Charges**
- Module : `color_generator`
- Modes : couleur unie, barres colorées, damier
- Configurable par paramètres d'entrée
- Synchronisé avec data_enable

### 💻 **Code à Développer**

```verilog
module color_generator (
    input wire        pixel_clk,
    input wire        rst_n,
    input wire [11:0] h_count,
    input wire [11:0] v_count,
    input wire        data_enable,
    input wire [2:0]  pattern_mode,   // Mode de motif
    input wire [7:0]  solid_r,        // Rouge uni
    input wire [7:0]  solid_g,        // Vert uni  
    input wire [7:0]  solid_b,        // Bleu uni
    input wire [11:0] h_active,       // Largeur active
    output reg [7:0]  pixel_r,        // Sortie rouge
    output reg [7:0]  pixel_g,        // Sortie verte
    output reg [7:0]  pixel_b         // Sortie bleue
);

// Paramètres des modes
localparam MODE_BLACK      = 3'd0;
localparam MODE_SOLID      = 3'd1;
localparam MODE_COLOR_BARS = 3'd2;
localparam MODE_CHECKERS   = 3'd3;
localparam MODE_GRADIENT   = 3'd4;

// À COMPLÉTER :
// 1. Mode couleur unie
// 2. Mode barres colorées (8 couleurs)
// 3. Mode damier (carreaux 32x32)
// 4. Mode dégradé horizontal
// 5. Sortir noir si data_enable = 0

endmodule
```

### ✅ **Tests à Réaliser**
1. Mode noir : tout à zéro
2. Mode couleur unie : couleur constante
3. Mode barres : 8 bandes de couleurs différentes
4. Mode damier : alternance noir/blanc
5. Vérifier que DE=0 → sortie noire

### 🎨 **Couleurs de Référence (Barres)**
```verilog
// 8 couleurs standards de test
localparam WHITE   = 24'hFFFFFF;
localparam YELLOW  = 24'hFFFF00;
localparam CYAN    = 24'h00FFFF;
localparam GREEN   = 24'h00FF00;
localparam MAGENTA = 24'hFF00FF;
localparam RED     = 24'hFF0000;
localparam BLUE    = 24'h0000FF;
localparam BLACK   = 24'h000000;
```

---

## Exercice 5 : Motifs Géométriques {#exercice5}

### 🎯 **Objectif**
Créer des générateurs de motifs géométriques plus complexes.

### 📚 **Théorie**
Les motifs géométriques nécessitent des calculs de distance et d'appartenance :
- **Cercle** : (x-cx)² + (y-cy)² ≤ r²
- **Rectangle** : x1 ≤ x ≤ x2 ET y1 ≤ y ≤ y2
- **Ligne** : équation y = ax + b

### 📋 **Cahier des Charges**
- Module : `geometric_patterns`
- Motifs : cercle, rectangle, grille, croix
- Paramètres configurables (position, taille, couleur)
- Optimisé pour la synthèse FPGA

### 💻 **Code à Développer**

```verilog
module geometric_patterns (
    input wire        pixel_clk,
    input wire        rst_n,
    input wire [11:0] h_count,
    input wire [11:0] v_count,
    input wire        data_enable,
    input wire [2:0]  pattern_select,
    // Paramètres configurables
    input wire [11:0] center_x,       // Centre X
    input wire [11:0] center_y,       // Centre Y
    input wire [11:0] radius,         // Rayon/largeur
    input wire [7:0]  fg_color_r,     // Couleur premier plan
    input wire [7:0]  fg_color_g,
    input wire [7:0]  fg_color_b,
    input wire [7:0]  bg_color_r,     // Couleur arrière-plan
    input wire [7:0]  bg_color_g,
    input wire [7:0]  bg_color_b,
    output reg [7:0]  pixel_r,
    output reg [7:0]  pixel_g,
    output reg [7:0]  pixel_b
);

localparam PATTERN_CIRCLE    = 3'd0;
localparam PATTERN_SQUARE    = 3'd1;
localparam PATTERN_CROSS     = 3'd2;
localparam PATTERN_GRID      = 3'd3;

// À COMPLÉTER :
// 1. Fonction cercle (approximation sans multiplication)
// 2. Fonction carré
// 3. Fonction croix (lignes H et V)
// 4. Fonction grille (lignes multiples)

// Astuce : Utiliser des comparaisons au lieu de multiplications
// |x-cx| + |y-cy| ≤ r (approximation cercle → losange)

endmodule
```

### ✅ **Tests à Réaliser**
1. Cercle centré à l'écran
2. Carré de différentes tailles
3. Croix centrée
4. Grille 16x16 pixels
5. Test des couleurs premier/arrière-plan

### 🔧 **Optimisations FPGA**
```verilog
// Éviter les multiplications coûteuses
// Au lieu de : distance² = (x-cx)² + (y-cy)²
// Utiliser : distance = |x-cx| + |y-cy| (Manhattan)

wire [11:0] dx = (h_count > center_x) ? 
                 (h_count - center_x) : (center_x - h_count);
wire [11:0] dy = (v_count > center_y) ? 
                 (v_count - center_y) : (center_y - v_count);
wire in_circle = (dx + dy) <= radius;
```

---

## Exercice 6 : Animation et Mouvement {#exercice6}

### 🎯 **Objectif**
Ajouter le mouvement et l'animation aux motifs générés.

### 📚 **Théorie**
L'animation se base sur la variation de paramètres dans le temps :
- **Compteur de trames** : incrémente à chaque image
- **Mouvement linéaire** : position = vitesse × temps
- **Mouvement rebond** : inversion de direction aux bords
- **Mouvement rotatoire** : angle = vitesse_angulaire × temps

### 📋 **Cahier des Charges**
- Module : `animation_controller`
- Types : translation, rotation, rebond, zoom
- Vitesses configurables
- Détection des collisions avec les bords

### 💻 **Code à Développer**

```verilog
module animation_controller (
    input wire        pixel_clk,
    input wire        rst_n,
    input wire        frame_sync,     // Pulse début de trame
    input wire [11:0] screen_width,   // 1280 pour 720p
    input wire [11:0] screen_height,  // 720 pour 720p
    input wire [2:0]  anim_mode,      // Type d'animation
    input wire [7:0]  speed,          // Vitesse (1-255)
    output reg [11:0] obj_x,          // Position X objet
    output reg [11:0] obj_y,          // Position Y objet
    output reg [11:0] obj_size,       // Taille objet
    output reg [7:0]  obj_angle       // Angle rotation
);

localparam ANIM_STATIC     = 3'd0;
localparam ANIM_LINEAR_X   = 3'd1;
localparam ANIM_LINEAR_Y   = 3'd2;
localparam ANIM_BOUNCE     = 3'd3;
localparam ANIM_CIRCULAR   = 3'd4;
localparam ANIM_ZOOM       = 3'd5;

// Variables internes
reg [31:0] frame_counter;
reg [11:0] velocity_x, velocity_y;
reg        direction_x, direction_y;

// À COMPLÉTER :
// 1. Compteur de trames
// 2. Mise à jour position selon le mode
// 3. Détection rebond aux bords
// 4. Mouvement circulaire (LUT sinus)

always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_counter <= 32'd0;
        obj_x <= screen_width >> 1;   // Centre
        obj_y <= screen_height >> 1;
        // ... initialisation
    end else if (frame_sync) begin
        frame_counter <= frame_counter + 1'b1;
        
        case (anim_mode)
            ANIM_LINEAR_X: begin
                // À COMPLÉTER
            end
            ANIM_BOUNCE: begin
                // À COMPLÉTER : rebond
            end
            // ... autres modes
        endcase
    end
end

endmodule
```

### ✅ **Tests à Réaliser**
1. Mouvement horizontal linéaire
2. Rebond sur les bords verticaux
3. Mouvement circulaire
4. Zoom in/out
5. Vérifier la fluidité (60 FPS)

### 📐 **Tables de Sinus (LUT)**
```verilog
// Approximation sinus par LUT 64 points
reg [7:0] sin_lut [0:63];
initial begin
    sin_lut[0]  = 8'd128;  // sin(0°) + 128
    sin_lut[16] = 8'd255;  // sin(90°) + 128
    sin_lut[32] = 8'd128;  // sin(180°) + 128
    sin_lut[48] = 8'd0;    // sin(270°) + 128
    // ... autres valeurs
end
```

---

## Exercice 7 : Gestion Multi-Résolution {#exercice7}

### 🎯 **Objectif**
Créer un module configurable supportant différentes résolutions vidéo.

### 📚 **Théorie**
Chaque résolution a ses propres timings :
- **VGA** : 640×480 @ 60Hz, pixel_clk = 25.175 MHz
- **SVGA** : 800×600 @ 60Hz, pixel_clk = 40 MHz  
- **720p** : 1280×720 @ 60Hz, pixel_clk = 74.25 MHz
- **1080p** : 1920×1080 @ 60Hz, pixel_clk = 148.5 MHz

### 📋 **Cahier des Charges**
- Module : `multi_resolution_controller`
- Support VGA, SVGA, 720p, 1080p
- Sélection par paramètre d'entrée
- Adaptation automatique des motifs

### 💻 **Code à Développer**

```verilog
module multi_resolution_controller (
    input wire [1:0]  resolution_mode, // 00=VGA, 01=SVGA, 10=720p, 11=1080p
    output reg [11:0] h_total,
    output reg [11:0] h_sync,
    output reg [11:0] h_back_porch,
    output reg [11:0] h_active,
    output reg [11:0] v_total,
    output reg [11:0] v_sync,
    output reg [11:0] v_back_porch,
    output reg [11:0] v_active,
    output reg        h_sync_pol,
    output reg        v_sync_pol
);

localparam RES_VGA   = 2'b00;
localparam RES_SVGA  = 2'b01;
localparam RES_720P  = 2'b10;
localparam RES_1080P = 2'b11;

// À COMPLÉTER : Table des timings
always @(*) begin
    case (resolution_mode)
        RES_VGA: begin
            h_total      = 12'd800;   // Total H
            h_sync       = 12'd96;    // Sync H
            h_back_porch = 12'd48;    // Back porch H
            h_active     = 12'd640;   // Active H
            v_total      = 12'd525;   // Total V
            // ... à compléter
        end
        RES_720P: begin
            h_total      = 12'd1650;
            h_sync       = 12'd40;
            h_back_porch = 12'd220;
            h_active     = 12'd1280;
            // ... à compléter
        end
        // ... autres résolutions
    endcase
end

endmodule
```

### ✅ **Tests à Réaliser**
1. Commutation entre résolutions
2. Vérification des fréquences de sortie
3. Adaptation des motifs à la résolution
4. Test de tous les modes

### 📊 **Table des Timings de Référence**

| Résolution | H_total | H_sync | H_bp | H_active | V_total | V_sync | V_bp | V_active | Pixel_CLK |
|-----------|---------|--------|------|----------|---------|--------|------|----------|-----------|
| VGA       | 800     | 96     | 48   | 640      | 525     | 2      | 33   | 480      | 25.175    |
| SVGA      | 1056    | 128    | 88   | 800      | 628     | 4      | 23   | 600      | 40        |
| 720p      | 1650    | 40     | 220  | 1280     | 750     | 5      | 20   | 720      | 74.25     |
| 1080p     | 2200    | 44     | 148  | 1920     | 1125    | 5      | 36   | 1080     | 148.5     |

---

## Exercice 8 : Encodeur TMDS Basique {#exercice8}

### 🎯 **Objectif**
Comprendre et implémenter l'encodage TMDS pour la transmission HDMI.

### 📚 **Théorie**
Le TMDS (Transition-Minimized Differential Signaling) :
- **8 bits → 10 bits** : Chaque octet RGB devient 10 bits
- **Réduction transitions** : Minimise l'EMI
- **Équilibrage DC** : Balance les 1 et les 0
- **3 canaux** : Rouge, Vert, Bleu + Horloge

### 📋 **Cahier des Charges**
- Module : `tmds_encoder`
- Encodage 8b/10b standard HDMI
- Équilibrage DC automatique
- Pipeline pour performance

### 💻 **Code à Développer**

```verilog
module tmds_encoder (
    input wire       pixel_clk,
    input wire       rst_n,
    input wire [7:0] data_in,      // Données 8 bits
    input wire       data_enable,   // DE
    input wire       control_bit0,  // C0 (HSYNC pour canal bleu)
    input wire       control_bit1,  // C1 (VSYNC pour canal bleu)
    output reg [9:0] tmds_out      // Sortie 10 bits
);

// Variables internes pour équilibrage DC
reg signed [4:0] dc_balance;  // Balance DC (-16 to +16)
reg [8:0] q_m;               // Données après minimisation
reg [3:0] n1_q_m, n0_q_m;   // Nombre de 1 et 0 dans q_m

// À COMPLÉTER :
// 1. Étape 1 : Minimisation des transitions (XOR/XNOR)
// 2. Étape 2 : Équilibrage DC 
// 3. Étape 3 : Gestion des signaux de contrôle

// Étape 1 : Minimisation transitions
wire [3:0] n1_data = data_in[0] + data_in[1] + data_in[2] + data_in[3] +
                     data_in[4] + data_in[5] + data_in[6] + data_in[7];

always @(*) begin
    if (n1_data > 4 || (n1_data == 4 && data_in[0] == 0)) begin
        // Utiliser XNOR
        q_m[0] = data_in[0];
        q_m[1] = q_m[0] ~^ data_in[1];
        q_m[2] = q_m[1] ~^ data_in[2];
        // ... à compléter
        q_m[8] = 1'b0;
    end else begin
        // Utiliser XOR
        q_m[0] = data_in[0];
        q_m[1] = q_m[0] ^ data_in[1];
        // ... à compléter
        q_m[8] = 1'b1;
    end
end

// À COMPLÉTER : Étapes 2 et 3

endmodule
```

### ✅ **Tests à Réaliser**
1. Test avec données constantes (0x00, 0xFF)
2. Vérification de l'équilibrage DC
3. Test des signaux de contrôle
4. Validation avec analyseur HDMI

### 🔍 **Signaux de Contrôle TMDS**
```verilog
// Pendant data_enable = 0
case ({control_bit1, control_bit0})
    2'b00: tmds_out = 10'b1101010100;
    2'b01: tmds_out = 10'b0010101011;
    2'b10: tmds_out = 10'b0101010100;
    2'b11: tmds_out = 10'b1010101011;
endcase
```

---

## Exercice 9 : Interface de Contrôle {#exercice9}

### 🎯 **Objectif**
Créer une interface utilisateur pour contrôler les paramètres vidéo.

### 📚 **Théorie**
Interface de contrôle typique :
- **Boutons** : sélection mode, navigation menu
- **Potentiomètres** : ajustement continu (luminosité, vitesse)
- **Display** : affichage des paramètres (7-segments, LCD)
- **Protocole série** : contrôle depuis PC (UART)

### 📋 **Cahier des Charges**
- Module : `video_control_interface`
- 4 boutons : Mode, Up, Down, Select
- 2 potentiomètres ADC 8 bits
- Interface UART optionnelle
- Menu OSD (On-Screen Display)

### 💻 **Code à Développer**

```verilog
module video_control_interface (
    input wire        clk,
    input wire        rst_n,
    // Interface boutons (avec anti-rebond)
    input wire        btn_mode,
    input wire        btn_up,
    input wire        btn_down,  
    input wire        btn_select,
    // Interface potentiomètres
    input wire [7:0]  pot_brightness,
    input wire [7:0]  pot_speed,
    // Interface UART (optionnel)
    input wire        uart_rx,
    output wire       uart_tx,
    // Paramètres de sortie
    output reg [2:0]  pattern_mode,
    output reg [2:0]  anim_mode,
    output reg [7:0]  brightness,
# Tutoriel Complet - Implémentation HDMI sur FPGA de A à Z

## Table des Matières

1. [Introduction et Vue d'ensemble](#introduction)
2. [Prérequis Matériels et Logiciels](#prerequis)
3. [Architecture du Système HDMI](#architecture)
4. [Structure des Fichiers du Projet](#structure-fichiers)
5. [Étape 1 : Générateur de Motifs de Test](#etape1-testpattern)
6. [Étape 2 : Gestion des Horloges (PLL)](#etape2-pll)
7. [Étape 3 : Module DVI/HDMI TX](#etape3-dvi-tx)
8. [Étape 4 : Module Principal (Top Level)](#etape4-top-level)
9. [Étape 5 : Contraintes Physiques et Timing](#etape5-contraintes)
10. [Compilation et Tests](#compilation)
11. [Troubleshooting](#troubleshooting)
12. [Extensions Possibles](#extensions)

## 1. Introduction et Vue d'ensemble {#introduction}

Ce tutoriel vous guide dans la création d'une implémentation HDMI complète sur FPGA. Le projet génère un signal HDMI 720p (1280x720 @ 74.25MHz) avec différents motifs de test.

### Objectifs du Projet
- Générer des signaux HDMI/DVI compatibles
- Afficher des motifs de test colorés
- Comprendre le protocole TMDS (Transition-Minimized Differential Signaling)
- Maîtriser la synchronisation vidéo

### Technologies Utilisées
- **FPGA** : Gowin GW2A-18C
- **Résolution** : 1280x720 (720p)
- **Fréquence pixel** : 74.25 MHz
- **Interface** : HDMI/DVI via TMDS

## 2. Prérequis Matériels et Logiciels {#prerequis}

### Matériel Requis
- Carte de développement FPGA Gowin GW2A-18C
- Connecteur HDMI
- Écran/Moniteur HDMI
- Câble HDMI

### Logiciels Requis
- Gowin EDA (version 1.9.8+)
- Éditeur de texte pour Verilog
- Oscilloscope (optionnel, pour debug)

## 3. Architecture du Système HDMI {#architecture}

```
[Horloge 27MHz] -> [PLL] -> [Horloge Pixel 74.25MHz]
                           [Horloge Serial 371.25MHz]
                                    |
[Générateur] -> [Données RGB] -> [Encodeur TMDS] -> [Sortie HDMI]
[de Motifs]     [Signaux Sync]                     [Différentielle]
```

### Composants Principaux
1. **PLL (Phase-Locked Loop)** : Génération des horloges
2. **Générateur de Motifs** : Création des données de test
3. **Encodeur TMDS** : Conversion vers le format HDMI
4. **Interface Différentielle** : Sortie physique HDMI

## 4. Structure des Fichiers du Projet {#structure-fichiers}

```
projet_hdmi/
├── src/
│   ├── video_top.v         # Module principal
│   ├── testpattern.v       # Générateur de motifs
│   ├── dvi_tx/
│   │   └── dvi_tx.v       # Module DVI/HDMI TX
│   ├── gowin_rpll/
│   │   ├── TMDS_rPLL.v    # PLL pour les horloges
│   │   ├── TMDS_rPLL.ipc  # Configuration IP
│   │   └── TMDS_rPLL.mod  # Modèle PLL
│   ├── dk_video.cst       # Contraintes physiques
│   └── dk_video.sdc       # Contraintes de timing
└── dk_video.gprj          # Fichier projet Gowin
```

## 5. Étape 1 : Générateur de Motifs de Test {#etape1-testpattern}

### Fonction du Module `testpattern.v`

Ce module génère les signaux de synchronisation vidéo et les motifs de test.

#### Paramètres de Résolution 720p
```verilog
// Paramètres pour 1280x720 @ 60Hz
.I_h_total   (12'd1650),  // Total horizontal
.I_h_sync    (12'd40),    // Pulse sync horizontal
.I_h_bporch  (12'd220),   // Back porch horizontal
.I_h_res     (12'd1280),  // Résolution horizontale
.I_v_total   (12'd750),   // Total vertical
.I_v_sync    (12'd5),     // Pulse sync vertical
.I_v_bporch  (12'd20),    // Back porch vertical
.I_v_res     (12'd720),   // Résolution verticale
```

#### Types de Motifs Générés
1. **Barres de couleur** : 8 couleurs standards (Blanc, Jaune, Cyan, Vert, Magenta, Rouge, Bleu, Noir)
2. **Grille** : Motif de grille pour test de géométrie
3. **Gris** : Dégradé de gris
4. **Couleur unie** : Couleur configurable

#### Signaux de Sortie
- `O_de` : Data Enable (zone active)
- `O_hs` : Synchronisation horizontale
- `O_vs` : Synchronisation verticale
- `O_data_r/g/b` : Données RGB 8 bits chacune

### Code Clé - Génération des Compteurs
```verilog
// Compteur horizontal
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
    if(!I_rst_n)
        H_cnt <= 12'd0;
    else if(H_cnt >= (I_h_total-1'b1))
        H_cnt <= 12'd0;
    else
        H_cnt <= H_cnt + 1'b1;
end

// Compteur vertical
always@(posedge I_pxl_clk or negedge I_rst_n)
begin
    if(!I_rst_n)
        V_cnt <= 12'd0;
    else if((V_cnt >= (I_v_total-1'b1)) && (H_cnt >= (I_h_total-1'b1)))
        V_cnt <= 12'd0;
    else if(H_cnt >= (I_h_total-1'b1))
        V_cnt <= V_cnt + 1'b1;
end
```

## 6. Étape 2 : Gestion des Horloges (PLL) {#etape2-pll}

### Configuration du PLL TMDS

Le module `TMDS_rPLL.v` génère les horloges nécessaires à partir de 27 MHz :

#### Calculs de Fréquences
```
Fréquence d'entrée : 27 MHz
Fréquence de sortie : 27 × (54/3) ÷ 2 = 243 MHz
```

**Note** : Dans le code, la configuration réelle est :
- IDIV_SEL = 3 (division par 4)
- FBDIV_SEL = 54 (multiplication par 55)
- ODIV_SEL = 2 (division par 2)

### Division d'Horloge
```verilog
CLKDIV u_clkdiv (
    .RESETN(hdmi4_rst_n),
    .HCLKIN(serial_clk),    // Horloge ×5
    .CLKOUT(pix_clk),       // Horloge pixel ×1
    .CALIB(1'b1)
);
defparam u_clkdiv.DIV_MODE="5";
```

### Synchronisation des Resets
```verilog
assign hdmi4_rst_n = I_rst_n & pll_lock;
```

## 7. Étape 3 : Module DVI/HDMI TX {#etape3-dvi-tx}

### Interface du Module DVI_TX_Top
```verilog
module DVI_TX_Top (
    input       I_rst_n,        // Reset asynchrone
    input       I_serial_clk,   // Horloge série (×5)
    input       I_rgb_clk,      // Horloge pixel
    input       I_rgb_vs,       // Sync verticale
    input       I_rgb_hs,       // Sync horizontale
    input       I_rgb_de,       // Data Enable
    input [7:0] I_rgb_r,        // Rouge
    input [7:0] I_rgb_g,        // Vert
    input [7:0] I_rgb_b,        // Bleu
    output      O_tmds_clk_p,   // Horloge TMDS+
    output      O_tmds_clk_n,   // Horloge TMDS-
    output[2:0] O_tmds_data_p,  // Données TMDS+ {R,G,B}
    output[2:0] O_tmds_data_n   // Données TMDS- {R,G,B}
);
```

### Fonctionnement de l'Encodeur TMDS
1. **Encodage 8b/10b** : Chaque octet RGB devient 10 bits
2. **Minimisation des transitions** : Réduction de l'EMI
3. **Équilibrage DC** : Maintien de l'équilibre des niveaux
4. **Sérialisation** : Conversion parallèle vers série

## 8. Étape 4 : Module Principal (Top Level) {#etape4-top-level}

### Architecture du Module `video_top.v`

```verilog
module video_top (
    input           I_clk,           // 27MHz
    input           I_rst_n,         // Reset
    output [3:0]    O_led,           // LEDs de statut
    output          O_tmds_clk_p,    // HDMI Clock+
    output          O_tmds_clk_n,    // HDMI Clock-
    output [2:0]    O_tmds_data_p,   // HDMI Data+
    output [2:0]    O_tmds_data_n    // HDMI Data-
);
```

### Instanciation des Sous-modules

#### 1. PLL pour les Horloges
```verilog
TMDS_rPLL u_tmds_rpll (
    .clkin(I_clk),
    .clkout(serial_clk),
    .lock(pll_lock)
);
```

#### 2. Division d'Horloge
```verilog
CLKDIV u_clkdiv (
    .RESETN(hdmi4_rst_n),
    .HCLKIN(serial_clk),
    .CLKOUT(pix_clk)
);
```

#### 3. Générateur de Motifs
```verilog
testpattern testpattern_inst (
    .I_pxl_clk(pix_clk),
    .I_rst_n(hdmi4_rst_n),
    .I_mode({1'b0,cnt_vs[9:8]}),
    // ... paramètres de résolution ...
    .O_de(tp0_de_in),
    .O_hs(tp0_hs_in),
    .O_vs(tp0_vs_in),
    .O_data_r(tp0_data_r),
    .O_data_g(tp0_data_g),
    .O_data_b(tp0_data_b)
);
```

#### 4. Module DVI TX
```verilog
DVI_TX_Top DVI_TX_Top_inst (
    .I_rst_n(hdmi4_rst_n),
    .I_serial_clk(serial_clk),
    .I_rgb_clk(pix_clk),
    .I_rgb_vs(tp0_vs_in),
    .I_rgb_hs(tp0_hs_in),
    .I_rgb_de(tp0_de_in),
    .I_rgb_r(tp0_data_r),
    .I_rgb_g(tp0_data_g),
    .I_rgb_b(tp0_data_b),
    .O_tmds_clk_p(O_tmds_clk_p),
    .O_tmds_clk_n(O_tmds_clk_n),
    .O_tmds_data_p(O_tmds_data_p),
    .O_tmds_data_n(O_tmds_data_n)
);
```

### Système de Changement de Motifs
```verilog
// Compteur de trames verticales pour changer de motif
always@(posedge pix_clk or negedge hdmi4_rst_n)
begin
    if(!hdmi4_rst_n)
        cnt_vs <= 0;
    else if(vs_r && !tp0_vs_in) // Front descendant de VS
        cnt_vs <= cnt_vs + 1'b1;
end
```

## 9. Étape 5 : Contraintes Physiques et Timing {#etape5-contraintes}

### Contraintes Physiques (`dk_video.cst`)

#### Assignation des Broches HDMI
```tcl
# Horloge HDMI différentielle
IO_LOC "O_tmds_clk_p" G16,H15;
IO_PORT "O_tmds_clk_p" PULL_MODE=NONE DRIVE=3.5;

# Données HDMI différentielles
IO_LOC "O_tmds_data_p[0]" H14,H16;  # Bleu
IO_PORT "O_tmds_data_p[0]" PULL_MODE=NONE DRIVE=3.5;
IO_LOC "O_tmds_data_p[1]" J15,K16;  # Vert
IO_PORT "O_tmds_data_p[1]" PULL_MODE=NONE DRIVE=3.5;
IO_LOC "O_tmds_data_p[2]" K14,K15;  # Rouge
IO_PORT "O_tmds_data_p[2]" PULL_MODE=NONE DRIVE=3.5;
```

#### Signaux de Contrôle
```tcl
# Horloge d'entrée 27MHz
IO_LOC "I_clk" H11;
IO_PORT "I_clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;

# Reset
IO_LOC "I_rst_n" T10;
IO_PORT "I_rst_n" IO_TYPE=LVCMOS33 PULL_MODE=UP;

# LEDs de statut
IO_LOC "O_led[0]" L16;
IO_PORT "O_led[0]" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=8;
```

### Contraintes de Timing (`dk_video.sdc`)
```tcl
# Définition de l'horloge principale
create_clock -name I_clk -period 37.04 [get_ports {I_clk}] -add
```

**Note** : 37.04 ns correspond à 27 MHz (1/27MHz = 37.04ns)

## 10. Compilation et Tests {#compilation}

### Étapes de Compilation

1. **Ouverture du Projet**
   - Ouvrir `dk_video.gprj` dans Gowin EDA
   - Vérifier que tous les fichiers sont présents

2. **Synthèse**
   ```
   Process → Synthesize
   ```

3. **Place & Route**
   ```
   Process → Place & Route
   ```

4. **Génération du Bitstream**
   ```
   Process → Generate Bitstream
   ```

### Tests et Validation

#### Vérifications de Base
- [ ] Compilation sans erreur
- [ ] Timing respecté (pas de violations)
- [ ] Utilisation des ressources acceptable

#### Tests Hardware
- [ ] LEDs clignotent (indique que l'horloge fonctionne)
- [ ] Signal HDMI détecté par l'écran
- [ ] Affichage des motifs de test
- [ ] Changement automatique des motifs

#### Signaux à Observer (avec oscilloscope)
1. **Horloge pixel** (74.25 MHz)
2. **Synchronisations** H/V
3. **Data Enable**
4. **Sorties TMDS** (371.25 MHz)

## 11. Troubleshooting {#troubleshooting}

### Problèmes Courants

#### 1. Pas d'Affichage
**Causes possibles :**
- PLL non verrouillée → Vérifier `pll_lock`
- Mauvaises contraintes timing → Revoir `dk_video.sdc`
- Problème de routing → Vérifier les broches HDMI

**Solutions :**
```verilog
// Debug : afficher le statut du PLL sur LED
assign O_led[0] = pll_lock;
assign O_led[1] = hdmi4_rst_n;
```

#### 2. Image Instable
**Causes possibles :**
- Violations de timing
- Problème de synchronisation d'horloge
- EMI sur les signaux TMDS

**Solutions :**
- Améliorer le routage
- Ajouter des condensateurs de découplage
- Vérifier l'intégrité des signaux

#### 3. Mauvaises Couleurs
**Causes possibles :**
- Inversion des canaux RGB
- Problème d'encodage TMDS

**Solutions :**
```verilog
// Test avec couleurs fixes
assign tp0_data_r = 8'hFF;  // Rouge à 100%
assign tp0_data_g = 8'h00;  // Vert à 0%
assign tp0_data_b = 8'h00;  // Bleu à 0%
```

### Messages d'Erreur Courants

#### "Clock skew violation"
- Ajouter des contraintes de timing plus strictes
- Utiliser des buffers d'horloge appropriés

#### "Setup/Hold violations"
- Réduire la fréquence temporairement
- Optimiser le placement des registres

## 12. Extensions Possibles {#extensions}

### Améliorations Immédiates

#### 1. Support Multi-Résolutions
```verilog
// Paramètres pour différentes résolutions
parameter MODE_800x600  = 2'b00;
parameter MODE_1024x768 = 2'b01;
parameter MODE_1280x720 = 2'b10;
parameter MODE_1920x1080 = 2'b11;
```

#### 2. Interface Utilisateur
- Boutons pour changer manuellement les motifs
- Potentiomètre pour ajuster la luminosité
- Menu OSD (On-Screen Display)

#### 3. Motifs Avancés
```verilog
// Motifs géométriques
- Cercles et ellipses
- Damier animé
- Sprites en mouvement
- Texte scrollant
```

### Projets Avancés

#### 1. Contrôleur de Mémoire Vidéo
- Framebuffer DDR
- Double buffering
- Accélération graphique 2D

#### 2. Interface Caméra
- Acquisition vidéo en temps réel
- Traitement d'image (filtres)
- Compression vidéo

#### 3. Audio HDMI
- Intégration de l'audio I2S
- Synchronisation audio/vidéo
- Support multi-canaux

## Conclusion

Ce tutoriel vous a guidé dans la création complète d'une implémentation HDMI sur FPGA. Vous maîtrisez maintenant :

- L'architecture des signaux vidéo numériques
- La génération d'horloges précises avec PLL
- L'encodage TMDS pour HDMI
- Les contraintes physiques et de timing
- Les techniques de debug hardware

### Ressources Supplémentaires

- **HDMI Specification v1.4** : Document officiel du protocole
- **Gowin EDA User Guide** : Documentation complète de l'outil
- **TMDS Encoding** : Spécifications techniques détaillées
- **Forums FPGA** : Communauté pour l'entraide

### Points Clés à Retenir

1. **Timing Critical** : Les signaux HDMI sont très sensibles au timing
2. **Horloges Multiples** : Bien gérer les domaines d'horloge différents
3. **Contraintes Essentielles** : SDC et CST sont critiques pour le succès
4. **Tests Progressifs** : Valider chaque étape avant de passer à la suivante

Bravo ! Vous avez maintenant une base solide pour vos futurs projets vidéo sur FPGA. 🎉
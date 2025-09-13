#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import sys
import os

def run_simulation():
    """Lance la simulation Icarus Verilog avec gestion d'erreurs"""
    
    print("=== Compilation ===")
    
    # Commande de compilation
    compile_cmd = [
        "iverilog", 
        "-Wall", 
        "-o", "simulation",
        "src/pixel_counters.v", 
        "testbench/tb_pixel_counters_vscode.v"
    ]
    
    try:
        result = subprocess.run(compile_cmd, 
                              capture_output=True, 
                              text=True, 
                              cwd=".")
        
        if result.returncode != 0:
            print("ERREUR de compilation:")
            print(result.stderr)
            print("Stdout:", result.stdout)
            return False
            
        print("Compilation OK")
        
    except FileNotFoundError:
        print("ERREUR: iverilog n'est pas trouve dans le PATH")
        print("Verifiez l'installation d'Icarus Verilog")
        return False
    
    print("=== Simulation ===")
    
    # Commande de simulation
    try:
        result = subprocess.run(["vvp", "simulation"], 
                              capture_output=True, 
                              text=True,
                              cwd=".")
        
        print("Sortie simulation:")
        print(result.stdout)
        
        if result.stderr:
            print("Messages d'erreur:")
            print(result.stderr)
            
    except FileNotFoundError:
        print("ERREUR: vvp n'est pas trouve")
        return False
    
    # Vérifier si le fichier VCD a été créé
    if os.path.exists("waves.vcd"):
        print("Fichier VCD cree avec succes")
        
        # Ouvrir GTKWave si disponible
        try:
            print("Ouverture GTKWave...")
            subprocess.Popen(["gtkwave", "waves.vcd"])
            print("GTKWave lance")
        except FileNotFoundError:
            print("GTKWave non trouve - ouvrez waves.vcd manuellement")
    else:
        print("ATTENTION: Fichier waves.vcd non cree")
    
    return True

def check_files():
    """Vérifie que les fichiers nécessaires existent"""
    
    required_files = [
        "src/pixel_counters.v",
        "testbench/tb_pixel_counters_vscode.v"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print("ERREUR: Fichiers manquants:")
        for file_path in missing_files:
            print(f"  - {file_path}")
        return False
    
    return True

def main():
    """Fonction principale"""
    print("=== Script de Simulation Verilog ===")
    
    # Vérifier les fichiers
    if not check_files():
        print("Verifiez la structure du projet")
        return 1
    
    # Lancer la simulation
    if run_simulation():
        print("=== Simulation terminee avec succes ===")
        return 0
    else:
        print("=== Erreurs durant la simulation ===")
        return 1

if __name__ == "__main__":
    sys.exit(main())
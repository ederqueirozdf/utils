#!/bin/bash

#Script para printar cor no texto para usu�rio

#Color
#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37


BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color



        echo -e "Escreve cor ${RED}VERMELHO${NC} !"
        echo -e "Escreve cor ${BLACK}PRETA${NC} !"
        echo -e "Escreve cor ${GREEN}VERDE${NC} !"
        echo -e "Escreve cor ${ORANGE}LARANJA${NC} !"
        echo -e "Escreve cor ${BLUE}AZUL${NC} !"
        echo -e "Escreve cor ${PURPLE}ROXO${NC} !"
        echo -e "Escreve cor ${CYAN}CIANO${NC} !"
        echo -e "Escreve cor ${GRAY}CINZA${NC} !"

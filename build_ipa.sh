#!/bin/bash

# ============================================
# SCRIPT DE COMPILACIÓN AUTOMÁTICA A .IPA
# LED CAR CONTROL - iOS App
# ============================================
# 
# USO: bash build_ipa.sh
#
# Este script compila automáticamente la app
# y genera un .ipa listo para instalar
#
# ============================================

set -e

# COLORES PARA TERMINAL
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# CONFIGURACIÓN
PROJECT_NAME="LEDCarControl"
SCHEME_NAME="LEDCarControl"
BUILD_CONFIG="Release"
DERIVED_DATA_PATH="build"
EXPORT_PATH="build/ipa"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}COMPILACIÓN AUTOMÁTICA A .IPA${NC}"
echo -e "${BLUE}LED CAR CONTROL${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# VERIFICAR QUE ESTAMOS EN LA CARPETA CORRECTA
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ ERROR: No encuentro ${PROJECT_NAME}.xcodeproj${NC}"
    echo "Asegúrate de ejecutar este script en la carpeta raíz del proyecto"
    exit 1
fi

echo -e "${GREEN}✓ Proyecto encontrado: ${PROJECT_NAME}${NC}"
echo ""

# PASO 1: LIMPIAR COMPILACIONES ANTERIORES
echo -e "${YELLOW}[1/5] Limpiando compilaciones anteriores...${NC}"
rm -rf "$DERIVED_DATA_PATH"
rm -rf "$EXPORT_PATH"
xcodebuild clean -scheme "$SCHEME_NAME" -derivedDataPath "$DERIVED_DATA_PATH" > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Limpeza completada${NC}"
echo ""

# PASO 2: COMPILAR PARA ARCHIVO
echo -e "${YELLOW}[2/5] Compilando para crear archivo...${NC}"
xcodebuild archive \
    -scheme "$SCHEME_NAME" \
    -configuration "$BUILD_CONFIG" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -archivePath "$DERIVED_DATA_PATH/${PROJECT_NAME}.xcarchive" \
    -allowProvisioningUpdates \
    | grep -E "^\s*(Compiling|Linking|Copying|Build)" || true

if [ -d "$DERIVED_DATA_PATH/${PROJECT_NAME}.xcarchive" ]; then
    echo -e "${GREEN}✓ Archivo creado correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: No se pudo crear el archivo${NC}"
    exit 1
fi
echo ""

# PASO 3: CREAR DIRECTORIO DE EXPORTACIÓN
echo -e "${YELLOW}[3/5] Preparando exportación...${NC}"
mkdir -p "$EXPORT_PATH"
echo -e "${GREEN}✓ Directorio de exportación listo${NC}"
echo ""

# PASO 4: EXPORTAR A .IPA
echo -e "${YELLOW}[4/5] Exportando a .ipa...${NC}"
xcodebuild -exportArchive \
    -archivePath "$DERIVED_DATA_PATH/${PROJECT_NAME}.xcarchive" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates \
    > /dev/null 2>&1

if [ -f "$EXPORT_PATH/${PROJECT_NAME}.ipa" ]; then
    echo -e "${GREEN}✓ .ipa exportado correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: No se pudo crear el .ipa${NC}"
    echo "Verifica que ExportOptions.plist esté en la carpeta raíz"
    exit 1
fi
echo ""

# PASO 5: INFORMACIÓN FINAL
echo -e "${YELLOW}[5/5] Finalizando...${NC}"
IPA_SIZE=$(du -h "$EXPORT_PATH/${PROJECT_NAME}.ipa" | cut -f1)
echo -e "${GREEN}✓ Compilación completada${NC}"
echo ""

# RESUMEN
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ ¡ÉXITO! Tu .ipa está listo${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}Ubicación:${NC} $EXPORT_PATH/${PROJECT_NAME}.ipa"
echo -e "${BLUE}Tamaño:${NC} $IPA_SIZE"
echo ""
echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
echo "1. Conecta tu iPhone por USB"
echo "2. Abre Xcode → Window → Devices and Simulators"
echo "3. Selecciona tu iPhone"
echo "4. Arrastra el .ipa a la ventana"
echo ""
echo -e "${BLUE}O simplemente arrastra el .ipa a tu iPhone en Finder${NC}"
echo ""
echo -e "${GREEN}¡La app se instalará en tu iPhone automáticamente!${NC}"
echo ""

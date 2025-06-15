#!/bin/bash

# NexRTC SDK - PlantUML Diagram Extractor
# Bu script tek dosyadaki tüm diagramları ayrı dosyalara çıkarır

set -e

SOURCE_FILE="nexrtc-diagrams.puml"
OUTPUT_DIR="diagrams"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonksiyonlar
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Ana dizin kontrolü
if [ ! -f "$SOURCE_FILE" ]; then
    log_error "Source file '$SOURCE_FILE' not found!"
    log_info "Please ensure nexrtc-diagrams.puml exists in current directory"
    exit 1
fi

# Output dizini oluştur
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    log_info "Created output directory: $OUTPUT_DIR"
fi

log_info "Starting diagram extraction from $SOURCE_FILE"

# Genişletilmiş diagram listesi (sıralı olarak) - Enterprise-ready features dahil
declare -a DIAGRAMS=(
    "architecture"
    "core-engine" 
    "call-lifecycle"
    "fallback-flow"
    "auth-provider"
    "ui-hooks"
    "wrapper-structure"
    "error-handling"
    "telemetry-flow"
    "sdk-package-map"
    "enhanced-security"
    "ai-analytics"
    "accessibility-i18n"
    "edge-computing"
    "advanced-testing"
    "plugin-architecture"
)

# Enterprise kategoriler
declare -A CATEGORIES=(
    ["Core Architecture"]="architecture core-engine call-lifecycle fallback-flow"
    ["Platform Integration"]="wrapper-structure auth-provider ui-hooks"
    ["Infrastructure"]="error-handling telemetry-flow sdk-package-map"
    ["Enterprise Security"]="enhanced-security accessibility-i18n"
    ["AI & Analytics"]="ai-analytics edge-computing"
    ["Development & QA"]="advanced-testing plugin-architecture"
)

# Her diagram için çıkarma işlemi
EXTRACTED_COUNT=0
FAILED_COUNT=0

log_info "🎯 Extracting ${#DIAGRAMS[@]} enterprise-grade diagrams..."

for diagram in "${DIAGRAMS[@]}"; do
    OUTPUT_FILE="${OUTPUT_DIR}/${diagram}.puml"
    
    log_info "Extracting: $diagram"
    
    # AWK script ile diagram çıkarma (geliştirilmiş)
    awk -v diagram="$diagram" '
    BEGIN { 
        printing = 0
        found = 0
        line_count = 0
    }
    /^@startuml/ {
        if ($2 == diagram || ($2 == "" && diagram == "")) {
            printing = 1
            found = 1
            print $0
            line_count++
        }
    }
    /^@enduml/ {
        if (printing) {
            print $0
            line_count++
            printing = 0
            exit
        }
    }
    {
        if (printing) {
            print $0
            line_count++
        }
    }
    END {
        if (!found) {
            print "ERROR: Diagram not found" > "/dev/stderr"
            exit 1
        }
        if (line_count < 5) {
            print "WARNING: Diagram too short" > "/dev/stderr"
            exit 2
        }
    }' "$SOURCE_FILE" > "$OUTPUT_FILE" 2>/tmp/awk_errors

    # Çıkarma sonucu kontrolü
    awk_exit_code=$?
    
    if [ $awk_exit_code -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
        # Dosya boyutu ve içerik kontrolü
        file_size=$(wc -l < "$OUTPUT_FILE")
        if [ $file_size -gt 5 ]; then
            log_success "✓ $diagram.puml created ($file_size lines)"
            ((EXTRACTED_COUNT++))
        else
            log_warning "⚠ $diagram.puml too short ($file_size lines)"
            ((FAILED_COUNT++))
        fi
    elif [ $awk_exit_code -eq 1 ]; then
        log_error "✗ Diagram '$diagram' not found in source file"
        rm -f "$OUTPUT_FILE"
        ((FAILED_COUNT++))
    elif [ $awk_exit_code -eq 2 ]; then
        log_warning "⚠ Diagram '$diagram' found but appears incomplete"
        ((FAILED_COUNT++))
    else
        log_error "✗ Failed to extract $diagram (unknown error)"
        rm -f "$OUTPUT_FILE"
        ((FAILED_COUNT++))
    fi
done

# Kategori bazında organize etme
log_info "📁 Organizing diagrams by categories..."

for category in "${!CATEGORIES[@]}"; do
    category_dir="${OUTPUT_DIR}/${category// /-}"
    mkdir -p "$category_dir"
    
    for diagram in ${CATEGORIES[$category]}; do
        if [ -f "${OUTPUT_DIR}/${diagram}.puml" ]; then
            cp "${OUTPUT_DIR}/${diagram}.puml" "$category_dir/"
        fi
    done
    
    if [ "$(ls -A "$category_dir" 2>/dev/null)" ]; then
        log_success "📂 Created category: $category ($(ls "$category_dir" | wc -l) diagrams)"
    else
        rmdir "$category_dir"
    fi
done

echo ""
log_info "=== EXTRACTION SUMMARY ==="
log_success "Successfully extracted: $EXTRACTED_COUNT diagrams"

if [ $FAILED_COUNT -gt 0 ]; then
    log_warning "Failed extractions: $FAILED_COUNT diagrams"
fi

echo ""
log_info "📊 Generated files in $OUTPUT_DIR/:"
ls -la "$OUTPUT_DIR/" | grep -E "\.(puml|png|svg)$" || log_info "No diagram files found"

# PlantUML kurulum kontrolü ve enterprise özellikleri
echo ""
if command -v plantuml >/dev/null 2>&1; then
    log_success "PlantUML detected! Generating images..."
    
    # PNG ve SVG çıktıları oluştur
    plantuml -tpng "$OUTPUT_DIR/"*.puml 2>/dev/null || log_warning "PNG generation had issues"
    plantuml -tsvg "$OUTPUT_DIR/"*.puml 2>/dev/null || log_warning "SVG generation had issues"
    
    # Çıktı dosyalarını say
    png_count=$(ls "$OUTPUT_DIR/"*.png 2>/dev/null | wc -l)
    svg_count=$(ls "$OUTPUT_DIR/"*.svg 2>/dev/null | wc -l)
    
    if [ $png_count -gt 0 ]; then
        log_success "Generated $png_count PNG images"
    fi
    if [ $svg_count -gt 0 ]; then
        log_success "Generated $svg_count SVG images"
    fi
    
else
    log_warning "PlantUML not found. To install:"
    echo "  # Ubuntu/Debian:"
    echo "  sudo apt-get install plantuml"
    echo ""
    echo "  # macOS:"
    echo "  brew install plantuml"
    echo ""
    echo "  # Or download from: https://plantuml.com/download"
fi

# Documentation generation
echo ""
log_info "📚 Generating documentation index..."

cat > "${OUTPUT_DIR}/README.md" << EOF
# NexRTC SDK - Architecture Diagrams

## 🏗️ Enterprise-Grade WebRTC Architecture

This directory contains comprehensive PlantUML diagrams for the NexRTC SDK architecture.

### 📊 Diagram Categories

$(for category in "${!CATEGORIES[@]}"; do
    echo "#### $category"
    for diagram in ${CATEGORIES[$category]}; do
        if [ -f "${OUTPUT_DIR}/${diagram}.puml" ]; then
            echo "- [\`${diagram}.puml\`](./${diagram}.puml) - $(echo $diagram | sed 's/-/ /g' | sed 's/\b\w/\U&/g')"
        fi
    done
    echo ""
done)

### 🎯 Enterprise Features

- **🔒 Security**: End-to-end encryption, compliance, audit trails
- **🤖 AI Analytics**: Predictive quality, churn analysis, optimization
- **🌍 Global Ready**: I18n, accessibility, cultural adaptation
- **⚡ Edge Computing**: Intelligent server selection, K8s integration
- **🧪 Advanced Testing**: Visual regression, chaos engineering, load testing
- **🔌 Plugin Architecture**: Extensible, event-sourced system

### 🚀 Usage

\`\`\`bash
# Generate PNG images
plantuml -tpng *.puml

# Generate SVG images
plantuml -tsvg *.puml

# Watch for changes
plantuml -gui
\`\`\`

### 📖 VS Code Integration

Install the **PlantUML** extension for live preview and editing support.

---

**Generated on:** $(date)  
**Total Diagrams:** $EXTRACTED_COUNT  
**SDK Version:** Enterprise v2.0
EOF

log_success "📖 Documentation index created: ${OUTPUT_DIR}/README.md"

# Enterprise özellikleri özeti
echo ""
log_info "🎯 Enterprise Architecture Summary:"
echo "   🔒 Security Layer: Enhanced encryption & compliance"
echo "   🤖 AI Analytics: Predictive intelligence & optimization"  
echo "   🌍 Global Ready: Accessibility & internationalization"
echo "   ⚡ Edge Computing: Intelligent distribution & scaling"
echo "   🧪 Advanced Testing: Comprehensive QA infrastructure"
echo "   🔌 Plugin System: Extensible event-driven architecture"

# VS Code workspace önerisi
echo ""
log_info "💡 Development Tips:"
echo "   • Use PlantUML extension in VS Code for live preview"
echo "   • Organize diagrams by feature for better navigation"
echo "   • Run 'plantuml -gui' for interactive editing"
echo "   • Consider version control for diagram evolution"

# Başarı durumu kontrolü
if [ $FAILED_COUNT -eq 0 ]; then
    log_success "🎉 All enterprise diagrams extracted successfully!"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Review generated diagrams for accuracy"
    echo "   2. Generate images with PlantUML"
    echo "   3. Include in technical documentation"
    echo "   4. Share with architecture review team"
    exit 0
else
    log_error "⚠️ Some diagrams failed to extract. Check source file format."
    echo ""
    echo "🔍 Troubleshooting:"
    echo "   1. Verify @startuml/@enduml pairs are correct"
    echo "   2. Check diagram names match exactly"
    echo "   3. Ensure no syntax errors in PlantUML code"
    echo "   4. Validate source file encoding (UTF-8)"
    exit 1
fi#!/bin/bash

# NexRTC SDK - PlantUML Diagram Extractor
# Bu script tek dosyadaki tüm diagramları ayrı dosyalara çıkarır

set -e

SOURCE_FILE="nexrtc-diagrams.puml"
OUTPUT_DIR="diagrams"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonksiyonlar
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Ana dizin kontrolü
if [ ! -f "$SOURCE_FILE" ]; then
    log_error "Source file '$SOURCE_FILE' not found!"
    log_info "Please ensure nexrtc-diagrams.puml exists in current directory"
    exit 1
fi

# Output dizini oluştur
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    log_info "Created output directory: $OUTPUT_DIR"
fi

log_info "Starting diagram extraction from $SOURCE_FILE"

# Diagram listesi (sıralı olarak)
declare -a DIAGRAMS=(
    "architecture"
    "core-engine" 
    "call-lifecycle"
    "fallback-flow"
    "auth-provider"
    "ui-hooks"
    "wrapper-structure"
    "error-handling"
    "telemetry-flow"
    "sdk-package-map"
)

# Her diagram için çıkarma işlemi
EXTRACTED_COUNT=0
FAILED_COUNT=0

for diagram in "${DIAGRAMS[@]}"; do
    OUTPUT_FILE="${OUTPUT_DIR}/${diagram}.puml"
    
    log_info "Extracting diagram: $diagram"
    
    # AWK script ile diagram çıkarma
    awk -v diagram="$diagram" '
    BEGIN { 
        printing = 0
        found = 0
    }
    /^@startuml/ {
        if ($2 == diagram || ($2 == "" && diagram == "")) {
            printing = 1
            found = 1
            print $0
        }
    }
    /^@enduml/ {
        if (printing) {
            print $0
            printing = 0
            exit
        }
    }
    {
        if (printing) {
            print $0
        }
    }
    END {
        if (!found) {
            exit 1
        }
    }' "$SOURCE_FILE" > "$OUTPUT_FILE"
    
    # Çıkarma sonucu kontrolü
    if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
        # Dosya boyutu kontrolü
        file_size=$(wc -l < "$OUTPUT_FILE")
        log_success "✓ $diagram.puml created ($file_size lines)"
        ((EXTRACTED_COUNT++))
    else
        log_error "✗ Failed to extract $diagram"
        rm -f "$OUTPUT_FILE"  # Boş dosyayı sil
        ((FAILED_COUNT++))
    fi
done

echo ""
log_info "=== EXTRACTION SUMMARY ==="
log_success "Successfully extracted: $EXTRACTED_COUNT diagrams"

if [ $FAILED_COUNT -gt 0 ]; then
    log_warning "Failed extractions: $FAILED_COUNT diagrams"
fi

echo ""
log_info "Generated files in $OUTPUT_DIR/:"
ls -la "$OUTPUT_DIR/"

# PlantUML kurulum kontrolü ve öneri
echo ""
if command -v plantuml >/dev/null 2>&1; then
    log_success "PlantUML detected! You can generate images with:"
    echo "  plantuml $OUTPUT_DIR/*.puml"
else
    log_warning "PlantUML not found. To install:"
    echo "  # Ubuntu/Debian:"
    echo "  sudo apt-get install plantuml"
    echo ""
    echo "  # macOS:"
    echo "  brew install plantuml"
    echo ""
    echo "  # Or download from: https://plantuml.com/download"
fi

# VS Code eklenti önerisi
echo ""
log_info "💡 VS Code users: Install 'PlantUML' extension for preview support"

# Başarı durumu kontrolü
if [ $FAILED_COUNT -eq 0 ]; then
    log_success "All diagrams extracted successfully! 🎉"
    exit 0
else
    log_error "Some diagrams failed to extract. Check source file format."
    exit 1
fi
#!/bin/bash

# Check Oracle Forms & Reports Installation
ORACLE_HOME=${ORACLE_HOME:-/u01/app/oracle/product/fmw14.1.2.0}

echo "=== Oracle Forms & Reports Installation Check ==="
echo "ORACLE_HOME: $ORACLE_HOME"
echo "Date: $(date)"
echo ""

# Check basic directories
echo "=== Checking Basic Directory Structure ==="
echo "ORACLE_HOME contents:"
ls -la $ORACLE_HOME/

echo ""
echo "=== Checking for Forms Components ==="

# Check for Forms directories
FORMS_DIRS=(
    "$ORACLE_HOME/forms"
    "$ORACLE_HOME/Forms"
    "$ORACLE_HOME/oracle_forms"
)

for dir in "${FORMS_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ Found Forms directory: $dir"
        ls -la "$dir/"
    else
        echo "❌ Forms directory not found: $dir"
    fi
done

echo ""
echo "=== Checking for Reports Components ==="

# Check for Reports directories
REPORTS_DIRS=(
    "$ORACLE_HOME/reports"
    "$ORACLE_HOME/Reports"
    "$ORACLE_HOME/oracle_reports"
)

for dir in "${REPORTS_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ Found Reports directory: $dir"
        ls -la "$dir/"
    else
        echo "❌ Reports directory not found: $dir"
    fi
done

echo ""
echo "=== Checking for Compiler Tools ==="

# Check for Forms compiler
COMPILER_TOOLS=(
    "$ORACLE_HOME/bin/frmcmp"
    "$ORACLE_HOME/forms/bin/frmcmp"
    "$ORACLE_HOME/oracle_common/bin/frmcmp"
)

for tool in "${COMPILER_TOOLS[@]}"; do
    if [ -f "$tool" ]; then
        echo "✅ Found Forms compiler: $tool"
        ls -la "$tool"
    else
        echo "❌ Forms compiler not found: $tool"
    fi
done

# Check for Reports compiler
REPORTS_TOOLS=(
    "$ORACLE_HOME/bin/rwrun"
    "$ORACLE_HOME/bin/rwbuilder"
    "$ORACLE_HOME/reports/bin/rwrun"
    "$ORACLE_HOME/reports/bin/rwbuilder"
)

for tool in "${REPORTS_TOOLS[@]}"; do
    if [ -f "$tool" ]; then
        echo "✅ Found Reports tool: $tool"
        ls -la "$tool"
    else
        echo "❌ Reports tool not found: $tool"
    fi
done

echo ""
echo "=== Checking Bin Directory ==="
echo "All executables in $ORACLE_HOME/bin/:"
ls -la $ORACLE_HOME/bin/ | grep -E "(frm|rep|rwrun|rwbuilder)" || echo "No Forms/Reports tools found in bin/"

echo ""
echo "=== Checking for Java and WebLogic ==="
echo "Java version:"
java -version 2>&1

echo ""
echo "WebLogic installations:"
ls -la $ORACLE_HOME/wlserver/ 2>/dev/null || echo "WebLogic not found"

echo ""
echo "=== Checking Installation Logs ==="
find /tmp -name "*forms*" -o -name "*reports*" -o -name "*install*" 2>/dev/null | head -10

echo ""
echo "=== Summary ==="
if [ -d "$ORACLE_HOME/forms" ] || [ -d "$ORACLE_HOME/Forms" ]; then
    echo "✅ Forms installation: FOUND"
else
    echo "❌ Forms installation: NOT FOUND"
fi

if [ -d "$ORACLE_HOME/reports" ] || [ -d "$ORACLE_HOME/Reports" ]; then
    echo "✅ Reports installation: FOUND"
else
    echo "❌ Reports installation: NOT FOUND"
fi

# Check for any Forms-related tools
FOUND_TOOLS=0
for tool in "${COMPILER_TOOLS[@]}" "${REPORTS_TOOLS[@]}"; do
    if [ -f "$tool" ]; then
        FOUND_TOOLS=1
        break
    fi
done

if [ $FOUND_TOOLS -eq 1 ]; then
    echo "✅ Development tools: FOUND"
else
    echo "❌ Development tools: NOT FOUND"
fi

echo ""
echo "=== Recommendations ==="
if [ ! -d "$ORACLE_HOME/forms" ] && [ ! -f "$ORACLE_HOME/bin/frmcmp" ]; then
    echo "⚠️  Forms installation appears incomplete"
    echo "   - Try running the Forms installer with different response file"
    echo "   - Check installation logs for specific errors"
    echo "   - Verify installer compatibility with Oracle Linux 8"
fi

echo "=== Check Complete ==="
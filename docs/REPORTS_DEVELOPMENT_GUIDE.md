# Oracle Reports 14c Development Guide

Complete guide for developing, compiling, and deploying Oracle Reports applications using the Docker environment.

## 📁 **Directory Structure**

```
reports_source/           # Source files (.rdf)
applications/reports/     # Compiled reports (.rep)
applications/resources/   # Shared resources (templates, stylesheets)
tns_admin/               # Database connections
reports_config/          # Reports configuration
```

## 🛠️ **Development Workflow**

### **Step 1: Place Source Files**
```bash
# Copy your .rdf files to reports_source directory
cp myreport.rdf ./reports_source/
```

### **Step 2: Configure Database Connection**
Edit `./tns_admin/tnsnames.ora`:
```sql
REPORTSDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = your-db-host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = your-service-name)
    )
  )
```

### **Step 3: Compile Reports**

#### **Convert RDF to REP (Runtime):**
```bash
docker exec -it oracle-forms-14c rwconverter \
  source=/u01/app/oracle/reports_source/myreport.rdf \
  stype=rdffile \
  dtype=repfile \
  dest=/u01/app/oracle/reports_source/myreport.rep
```

#### **Convert to Different Formats:**
```bash
# Convert RDF to JSP
docker exec -it oracle-forms-14c rwconverter \
  source=/u01/app/oracle/reports_source/myreport.rdf \
  stype=rdffile \
  dtype=jspfile \
  dest=/u01/app/oracle/reports_source/myreport.jsp

# Convert RDF to XML
docker exec -it oracle-forms-14c rwconverter \
  source=/u01/app/oracle/reports_source/myreport.rdf \
  stype=rdffile \
  dtype=xmlfile \
  dest=/u01/app/oracle/reports_source/myreport.xml
```

### **Step 4: Test Reports**

#### **Run Report Directly:**
```bash
# Generate PDF output
docker exec -it oracle-forms-14c rwrun \
  report=/u01/app/oracle/reports_source/myreport.rdf \
  userid=username/password@REPORTSDB \
  destype=file \
  desname=/tmp/output.pdf \
  desformat=pdf

# Generate HTML output
docker exec -it oracle-forms-14c rwrun \
  report=/u01/app/oracle/reports_source/myreport.rdf \
  userid=username/password@REPORTSDB \
  destype=file \
  desname=/tmp/output.html \
  desformat=htmlcss
```

#### **Test via Web Interface:**
```bash
# PDF output
http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid=username/password@REPORTSDB&destype=cache&desformat=pdf

# HTML output
http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid=username/password@REPORTSDB&destype=cache&desformat=htmlcss

# With parameters
http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid=username/password@REPORTSDB&destype=cache&desformat=pdf&P_PARAM1=value1&P_PARAM2=value2
```

### **Step 5: Deploy Reports**
```bash
# Move compiled .rep files to deployment directory
docker exec -it oracle-forms-14c cp \
  /u01/app/oracle/reports_source/*.rep \
  /u01/app/oracle/config/domains/forms_domain/autodeploy/reports/
```

## 🔧 **Available Tools**

| Tool | Purpose | Location |
|------|---------|----------|
| `rwrun` | Reports Runtime Engine | `/u01/app/oracle/product/fmw14.1.2.0/bin/rwrun` |
| `rwbuilder` | Reports Builder | `/u01/app/oracle/product/fmw14.1.2.0/bin/rwbuilder` |
| `rwconverter` | Format Converter | `/u01/app/oracle/product/fmw14.1.2.0/bin/rwconverter` |
| `rwserver` | Reports Server | `/u01/app/oracle/product/fmw14.1.2.0/bin/rwserver` |
| `rwclient` | Reports Client | `/u01/app/oracle/product/fmw14.1.2.0/bin/rwclient` |

## 📄 **File Types**

| Extension | Description | Purpose |
|-----------|-------------|---------|
| `.rdf` | Report Definition Files | Source files (editable) |
| `.rep` | Compiled Reports | Runtime files (optimized) |
| `.jsp` | JSP Report files | Web-based reports |
| `.xml` | XML Report definitions | Data exchange format |
| `.tdf` | Template Definition Files | Report templates |
| `.sql` | SQL scripts | Data source queries |

## 📊 **Output Formats**

### **Supported Output Formats:**

| Format | Parameter | Description | Use Case |
|--------|-----------|-------------|----------|
| **PDF** | `desformat=pdf` | Portable Document Format | Print-ready documents |
| **HTML** | `desformat=htmlcss` | HTML with CSS styling | Web display |
| **RTF** | `desformat=rtf` | Rich Text Format | Word processing |
| **Excel** | `desformat=xlsx` | Excel spreadsheet | Data analysis |
| **XML** | `desformat=xml` | XML data format | Data exchange |
| **CSV** | `desformat=delimited` | Comma-separated values | Data import/export |

### **Destination Types:**

| Type | Parameter | Description |
|------|-----------|-------------|
| **Cache** | `destype=cache` | Temporary web cache |
| **File** | `destype=file` | Save to file system |
| **Email** | `destype=mail` | Email delivery |
| **Printer** | `destype=printer` | Direct printing |

## 🎯 **Advanced Features**

### **Parameter Forms:**
```bash
# Enable parameter form
http://localhost:9002/reports/rwservlet?report=myreport.rdf&paramform=yes
```

### **Batch Processing:**
```bash
# Process multiple reports
docker exec -it oracle-forms-14c bash -c '
for report in /u01/app/oracle/reports_source/*.rdf; do
  rwrun report="$report" userid=user/pass@DB destype=file desname="/tmp/$(basename "$report" .rdf).pdf" desformat=pdf
done'
```

### **Custom Templates:**
```bash
# Use custom template
docker exec -it oracle-forms-14c rwrun \
  report=/u01/app/oracle/reports_source/myreport.rdf \
  template=/u01/app/oracle/applications/resources/templates/custom.tdf \
  userid=username/password@REPORTSDB \
  destype=cache \
  desformat=pdf
```

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **Report Not Found:**
```bash
# Check file exists
docker exec -it oracle-forms-14c ls -la /u01/app/oracle/reports_source/

# Check permissions
docker exec -it oracle-forms-14c ls -la /u01/app/oracle/reports_source/myreport.rdf
```

#### **Database Connection Errors:**
```bash
# Test database connection
docker exec -it oracle-forms-14c sqlplus username/password@REPORTSDB

# Check TNS configuration
docker exec -it oracle-forms-14c cat /u01/app/oracle/product/fmw14.1.2.0/network/admin/tnsnames.ora
```

#### **Runtime Errors:**
```bash
# Check Reports server logs
docker exec -it oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/WLS_REPORTS/logs/WLS_REPORTS.log

# Check Reports servlet logs
docker logs oracle-forms-14c | grep -i reports
```

### **Debug Mode:**
```bash
# Enable debug output
docker exec -it oracle-forms-14c rwrun \
  report=/u01/app/oracle/reports_source/myreport.rdf \
  userid=username/password@REPORTSDB \
  destype=file \
  desname=/tmp/debug_output.pdf \
  desformat=pdf \
  debug=yes
```

## 📈 **Performance Optimization**

### **Query Optimization:**
```sql
-- Optimize report queries
-- Use indexes, proper WHERE clauses
-- Avoid SELECT * statements
-- Use bind variables for parameters
```

### **Report Design:**
- **Minimize data fetching**: Only retrieve necessary columns
- **Use summaries**: Implement summary columns for calculations
- **Optimize formatting**: Reduce complex formatting
- **Template reuse**: Use common templates across reports

### **Server Configuration:**
```properties
# Increase cache size in rwservlet.properties
cacheSize=500
maxUsers=50
timeout=120
```

## 🔗 **Integration Examples**

### **Call from Forms:**
```sql
-- PL/SQL in Forms to call report
WEB.SHOW_DOCUMENT('http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid='||:GLOBAL.username||'/'||:GLOBAL.password||'@'||:GLOBAL.database||'&destype=cache&desformat=pdf&P_PARAM1='||:BLOCK.FIELD1);
```

### **Call from Web Application:**
```html
<!-- HTML link to report -->
<a href="http://localhost:9002/reports/rwservlet?report=sales_report.rdf&userid=user/pass@DB&destype=cache&desformat=pdf&P_START_DATE=2024-01-01&P_END_DATE=2024-12-31" target="_blank">
  View Sales Report
</a>
```

### **REST API Integration:**
```bash
# Call via curl
curl "http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid=user/pass@DB&destype=cache&desformat=pdf" -o report.pdf
```

## 📋 **Best Practices**

1. **Version Control**: Keep .rdf files in source control, not .rep files
2. **Database Security**: Use TNS names, never hardcode passwords
3. **Error Handling**: Implement proper error handling in reports
4. **Resource Management**: Optimize queries and limit data retrieval
5. **Template Standardization**: Use consistent templates across reports
6. **Testing**: Test reports with various data scenarios
7. **Documentation**: Document report parameters and business logic
8. **Performance**: Monitor and optimize slow-running reports

## 🔗 **Useful URLs**

- **Reports Server**: http://localhost:9002
- **Reports Servlet**: http://localhost:9002/reports/rwservlet
- **WebLogic Console**: http://localhost:7001/console
- **Reports Help**: http://localhost:9002/reports/rwservlet?help=yes
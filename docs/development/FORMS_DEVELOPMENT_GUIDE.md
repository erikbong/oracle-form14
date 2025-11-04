# Oracle Forms 14c Development Guide

Complete guide for developing, compiling, and deploying Oracle Forms applications using the Docker environment.

## 📁 **Directory Structure**

```
forms_source/           # Source files (.fmb)
applications/forms/     # Compiled applications (.fmx)
applications/resources/ # Shared resources (images, libraries)
tns_admin/             # Database connections
```

## 🛠️ **Development Workflow**

### **Step 1: Place Source Files**
```bash
# Copy your .fmb files to forms_source directory
cp myform.fmb ./forms_source/
```

### **Step 2: Configure Database Connection**
Edit `./tns_admin/tnsnames.ora`:
```sql
MYDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = your-db-host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = your-service-name)
    )
  )
```

### **Step 3: Compile Forms**

#### **Single Form Compilation:**
```bash
docker exec -it oracle-forms-14c frmcmp \
  module=/u01/app/oracle/forms_source/myform.fmb \
  userid=username/password@MYDB \
  output_file=/u01/app/oracle/forms_source/myform.fmx
```

#### **Batch Compilation:**
```bash
docker exec -it oracle-forms-14c frmcmp_batch \
  module_type=form \
  module=/u01/app/oracle/forms_source/*.fmb \
  userid=username/password@MYDB \
  compile_all=yes
```

#### **Advanced Compilation Options:**
```bash
# Compile with specific options
docker exec -it oracle-forms-14c frmcmp \
  module=/u01/app/oracle/forms_source/myform.fmb \
  userid=username/password@MYDB \
  output_file=/u01/app/oracle/forms_source/myform.fmx \
  compile_all=yes \
  window_state=minimize
```

### **Step 4: Deploy Applications**
```bash
# Move compiled .fmx files to deployment directory
docker exec -it oracle-forms-14c cp \
  /u01/app/oracle/forms_source/*.fmx \
  /u01/app/oracle/config/domains/forms_domain/autodeploy/forms/
```

### **Step 5: Test Your Forms**
```bash
# Access via browser
http://localhost:9001/forms/frmservlet?form=forms/myform.fmx&userid=username/password@MYDB
```

## 🔧 **Available Tools**

| Tool | Purpose | Location |
|------|---------|----------|
| `frmcmp` | Forms Compiler | `/u01/app/oracle/product/fmw14.1.2.0/bin/frmcmp` |
| `frmcmp_batch` | Batch Compiler | `/u01/app/oracle/product/fmw14.1.2.0/bin/frmcmp_batch` |
| `frmbld` | Forms Builder | `/u01/app/oracle/product/fmw14.1.2.0/bin/frmbld` |
| `frmctrl` | Forms Controller | `/u01/app/oracle/product/fmw14.1.2.0/bin/frmctrl` |
| `frmweb` | Forms Web | `/u01/app/oracle/product/fmw14.1.2.0/bin/frmweb` |

## 📝 **Common Parameters**

### **frmcmp Parameters:**
- `module=` - Source .fmb file path
- `userid=` - Database connection (user/pass@database)
- `output_file=` - Output .fmx file path
- `compile_all=` - yes/no (compile all objects)
- `window_state=` - minimize/maximize

### **URL Parameters:**
- `form=` - Form name (.fmx file)
- `userid=` - Database connection
- `debug=` - yes/no (enable debugging)
- `record=` - collect/names (record statistics)

## 🚨 **Troubleshooting**

### **Compilation Errors:**
```bash
# Check compilation logs
docker exec -it oracle-forms-14c find /tmp -name "*.err" -exec cat {} \;

# Test database connection
docker exec -it oracle-forms-14c sqlplus username/password@MYDB
```

### **Runtime Errors:**
```bash
# Check Forms server logs
docker logs oracle-forms-14c | grep -i forms

# Check WebLogic logs
docker exec -it oracle-forms-14c tail -f /u01/app/oracle/config/domains/forms_domain/servers/WLS_FORMS/logs/WLS_FORMS.log
```

## 🎯 **Best Practices**

1. **Version Control**: Keep .fmb files in source control, not .fmx
2. **Database Connections**: Use TNS names instead of direct connections
3. **Resource Management**: Place images/icons in `applications/resources/`
4. **Error Handling**: Always check compilation output for errors
5. **Testing**: Test forms thoroughly before production deployment

## 📊 **Performance Tips**

- **Compile once, deploy many**: Keep compiled .fmx files for reuse
- **Batch compilation**: Use `frmcmp_batch` for multiple forms
- **Resource optimization**: Optimize images and minimize form complexity
- **Connection pooling**: Configure proper database connection pools

## 🔗 **Useful Links**

- **Forms Server**: http://localhost:9001
- **WebLogic Console**: http://localhost:7001/console
- **Forms Servlet**: http://localhost:9001/forms/frmservlet
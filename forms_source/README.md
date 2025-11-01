# Forms Source Directory

Place your Oracle Forms source files (.fmb, .mmb, .pll, .olb) in this directory.

## Usage

### Compiling Forms

From your host machine:

```bash
# Compile a form
docker exec oracle-forms-14c frmcmp module=/u01/app/oracle/forms_source/myform.fmb userid=user/pass@FREEPDB1 compile_all=yes

# Compile with output to a different location
docker exec oracle-forms-14c frmcmp module=/u01/app/oracle/forms_source/myform.fmb userid=user/pass@FREEPDB1 module_type=form output_file=/u01/app/oracle/forms_source/myform.fmx
```

### Running Forms

After compilation, access your form via:

```
http://localhost:9001/forms/frmservlet?form=myform.fmx&userid=user/pass@FREEPDB1
```

## Directory Structure

```
forms_source/
├── myform.fmb          # Form module
├── myform.fmx          # Compiled form (generated)
├── mymenu.mmb          # Menu module
├── mylib.pll           # PL/SQL library
└── mylib.olb           # Object library
```

## Notes

- All files in this directory are accessible from the container at `/u01/app/oracle/forms_source`
- Compiled files (.fmx) are generated in the same directory
- Make sure to connect to a valid database connection (see tnsnames.ora)

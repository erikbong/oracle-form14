# Reports Source Directory

Place your Oracle Reports source files (.rdf) in this directory.

## Usage

### Compiling Reports

From your host machine:

```bash
# Compile a report
docker exec oracle-forms-14c rwconverter source=/u01/app/oracle/reports_source/myreport.rdf dtype=rdffile dest=/u01/app/oracle/reports_source/myreport_compiled.rdf
```

### Running Reports

Run a report directly:

```bash
# Generate PDF
docker exec oracle-forms-14c rwrun report=/u01/app/oracle/reports_source/myreport.rdf userid=user/pass@FREEPDB1 destype=file desname=/tmp/output.pdf desformat=pdf

# Generate HTML
docker exec oracle-forms-14c rwrun report=/u01/app/oracle/reports_source/myreport.rdf userid=user/pass@FREEPDB1 destype=file desname=/tmp/output.html desformat=html
```

### Running Reports via Servlet

Access your report via the Reports servlet:

```
http://localhost:9002/reports/rwservlet?report=myreport.rdf&userid=user/pass@FREEPDB1&desformat=pdf&destype=cache
```

## Directory Structure

```
reports_source/
├── myreport.rdf        # Report definition file
├── myreport.rep        # Compiled report (if needed)
└── README.md           # This file
```

## Common Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `report` | Report file path | `myreport.rdf` |
| `userid` | Database credentials | `user/pass@FREEPDB1` |
| `desformat` | Output format | `pdf`, `html`, `htmlcss`, `rtf`, `xml` |
| `destype` | Destination type | `cache`, `file`, `printer` |
| `desname` | Output filename | `/tmp/output.pdf` |
| `paramform` | Show parameter form | `yes`, `no` |

## Notes

- All files in this directory are accessible from the container at `/u01/app/oracle/reports_source`
- Use `FREEPDB1` as the TNS alias for the included Oracle Database 23c Free
- For other databases, add them to `tnsnames.ora` in the `tns_admin` folder
- Reports can be run synchronously or submitted to the Reports Server queue

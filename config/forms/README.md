# Forms Configuration Directory

This directory is for Forms-specific configuration files that you want to externally mount and customize.

## Common Configuration Files

### default.env
Forms runtime environment variables. Example:

```bash
# Forms runtime settings
FORMS_PATH=/home/oracle/forms_source
FORMS_TIMEOUT=30
FORMS_DEBUG=true
```

### formsweb.cfg
Forms servlet configuration. This file controls how Forms applications are served via the web.

Key settings include:
- `baseHTML` - HTML template for Forms
- `archive` - JAR file locations
- `imagePath` - Path to images
- `serverURL` - Forms server URL

### Custom Environment Files
You can create custom environment files for different deployment scenarios:
- `development.env`
- `production.env`
- `testing.env`

## Mounting Configuration Files

To mount a specific configuration file, update `docker-compose.production.yml`:

```yaml
volumes:
  # Example: Mount formsweb.cfg
  - ./config/forms/formsweb.cfg:/u01/app/oracle/middleware/fmw/forms/j2ee/forms.ear/forms.war/WEB-INF/formsweb.cfg:ro

  # Example: Mount default.env
  - ./config/forms/default.env:/u01/app/oracle/middleware/fmw/forms/server/default.env:ro
```

## Usage

1. Place your custom configuration files in this directory
2. Update docker-compose.production.yml to mount them
3. Restart the container:
   ```bash
   docker-compose -f docker-compose.production.yml restart oracle-forms
   ```

## Notes

- Use `:ro` for read-only mounts (recommended for production)
- Use `:rw` for read-write mounts (for files that need to be modified at runtime)
- Always backup your configuration files before making changes

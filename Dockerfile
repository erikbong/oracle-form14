# Use Oracle Linux 8 Slim
FROM oraclelinux:8-slim

# Install required OS packages
RUN microdnf install -y oraclelinux-developer-release-el8 && \
    microdnf update -y && \
    microdnf install -y \
        binutils \
        gcc \
        gcc-c++ \
        glibc \
        glibc-devel \
        ksh \
        libaio \
        libaio-devel \
        make \
        unixODBC \
        unixODBC-devel \
        zlib-devel \
        tar \
        gzip \
        unzip \
        which \
        hostname && \
    microdnf clean all

# Set paths
ENV ORACLE_JDK_HOME=/u01/app/oracle/product/jdk17
ENV OPENJDK_HOME=/usr/lib/jvm/java-11-openjdk
ENV JAVA_HOME=$ORACLE_JDK_HOME
ENV PATH=$JAVA_HOME/bin:$PATH

ENV ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0
ENV DOMAIN_HOME=/u01/app/oracle/config/domains/forms_domain
ENV ADMIN_PORT=7001
ENV FORMS_PORT=9001
ENV REPORTS_PORT=9002

# Create oracle user and inventory
RUN groupadd -g 54321 oinstall && \
    useradd -u 54321 -g oinstall oracle && \
    mkdir -p /u01/app/oracle && \
    mkdir -p /u01/app/oraInventory && \
    mkdir -p $ORACLE_JDK_HOME && \
    chown -R oracle:oinstall /u01 && \
    echo "inventory_loc=/u01/app/oraInventory" > /etc/oraInst.loc && \
    echo "inst_group=oinstall" >> /etc/oraInst.loc

# Create directories
RUN mkdir -p $ORACLE_HOME && \
    mkdir -p /install && \
    mkdir -p /scripts

# Fix ownership BEFORE copying anything
RUN chown -R oracle:oinstall /u01/app/oracle

# Copy installers, JDK, and scripts
COPY install/ /install/
COPY scripts/ /scripts/
COPY response/ /response/

# Extract Oracle JDK 17 as root
RUN cd /install && \
    tar -xzf jdk-17*.tar.gz -C $ORACLE_JDK_HOME --strip-components=1

# Make scripts and .bin installer executable
RUN chmod +x /scripts/*.sh && \
    chmod +x /install/fmw_14.1.2.0.0_fr_linux64.bin

# Switch to oracle user
USER oracle

# Install FMW Infrastructure (WebLogic + JRF) using Oracle JDK 17
RUN echo "=== STARTING FMW INFRASTRUCTURE INSTALLATION ===" && \
    echo "Java version being used:" && \
    java -version && \
    echo "Response file contents:" && \
    cat /response/fmw_infra_install.rsp && \
    echo "Verifying installer exists:" && \
    ls -la /install/fmw_14.1.2.0.0_infrastructure.jar && \
    echo "Starting installation..." && \
    java -jar /install/fmw_14.1.2.0.0_infrastructure.jar \
        -silent \
        -responseFile /response/fmw_infra_install.rsp \
        -invPtrLoc /etc/oraInst.loc \
        -ignoreSysPrereqs \
        -force; \
    INSTALL_EXIT_CODE=$? && \
    echo "=== INSTALLATION EXIT CODE: $INSTALL_EXIT_CODE ===" && \
    echo "=== CHECKING INSTALLATION RESULTS ===" && \
    ls -la $ORACLE_HOME/ && \
    echo "=== CHECKING INSTALLATION LOGS ===" && \
    find /tmp -name "*.log" -exec echo "Found log: {}" \; -exec head -20 {} \; 2>/dev/null && \
    echo "=== CHECKING INVENTORY ===" && \
    ls -la /u01/app/oraInventory/ 2>/dev/null || echo "Inventory directory not found" && \
    echo "=== VERIFYING ORACLE_HOME INSTALLATION ===" && \
    if [ -d "$ORACLE_HOME/oracle_common" ]; then \
        echo "SUCCESS: oracle_common directory found"; \
    else \
        echo "ERROR: oracle_common directory NOT found - installation failed"; \
        echo "Full installation logs:"; \
        find /tmp -name "*.log" -exec cat {} \; 2>/dev/null; \
        exit 1; \
    fi

# DEBUG: Force show logs even if commands fail
RUN echo "=== ORACLE_HOME CONTENT ===" && \
    ls -la $ORACLE_HOME || echo "ORACLE_HOME ls failed" && \
    echo "=== TMP CONTENT ===" && \
    ls -la /tmp/ || echo "tmp ls failed" && \
    echo "=== ORAINST.LOG ===" && \
    cat /tmp/oraInst.log 2>/dev/null || echo "oraInst.log not found" && \
    echo "=== LATEST INSTALL LOG ===" && \
    LOG_FILE=$(find /tmp -name "install*.log" | head -1) && \
    if [ -n "$LOG_FILE" ]; then cat "$LOG_FILE"; else echo "No install.log found"; fi && \
    echo "=== JAVA VERSION ===" && \
    java -version 2>&1

# DEBUG: Check for wlst.sh
RUN find $ORACLE_HOME -name "wlst.sh" 2>/dev/null || echo "wlst.sh NOT FOUND in ORACLE_HOME"
# DEBUG: Check for wlst.sh
RUN find $ORACLE_HOME -name "wlst.sh" 2>/dev/null || echo "wlst.sh NOT FOUND in ORACLE_HOME"

# Switch back to root for domain creation
USER root

# Final DEBUG before WLST
RUN echo "ORACLE_HOME is: $ORACLE_HOME" && \
    test -d "$ORACLE_HOME/oracle_common" || echo "oracle_common missing!" && \
    test -f "$ORACLE_HOME/oracle_common/common/bin/wlst.sh" || echo "wlst.sh missing!"

# Debug: Check what was actually installed
RUN echo "=== CHECKING ACTUAL ORACLE_HOME STRUCTURE ===" && \
    find $ORACLE_HOME -type f -name "wlst.sh" 2>/dev/null || echo "wlst.sh NOT found anywhere" && \
    echo "=== ORACLE_HOME DIRECTORY STRUCTURE ===" && \
    ls -la $ORACLE_HOME/ || echo "ORACLE_HOME empty or missing" && \
    echo "=== CHECKING FOR WEBLOGIC INSTALLATION ===" && \
    find $ORACLE_HOME -type d -name "*weblogic*" -o -name "*wls*" 2>/dev/null || echo "No WebLogic directories found"

# Create domain directory and set permissions
RUN mkdir -p /u01/app/oracle/config/domains && \
    chown -R oracle:oinstall /u01/app/oracle/config

# Find and execute WLST to create domain
RUN echo "=== EXECUTING WLST TO CREATE DOMAIN ===" && \
    if [ -f "$ORACLE_HOME/oracle_common/common/bin/wlst.sh" ]; then \
        echo "Using oracle_common wlst.sh" && \
        $ORACLE_HOME/oracle_common/common/bin/wlst.sh /scripts/createDomain.py && \
        echo "=== DOMAIN CREATION COMPLETED ===" && \
        echo "Verifying domain was created:" && \
        ls -la /u01/app/oracle/config/domains/ && \
        if [ -d "/u01/app/oracle/config/domains/forms_domain" ]; then \
            echo "SUCCESS: forms_domain directory found" && \
            ls -la /u01/app/oracle/config/domains/forms_domain/; \
        else \
            echo "ERROR: forms_domain directory not found" && \
            exit 1; \
        fi; \
    else \
        echo "ERROR: No wlst.sh found" && \
        exit 1; \
    fi && \
    chown -R oracle:oinstall /u01/app/oracle/config

# Expose ports
EXPOSE $ADMIN_PORT $FORMS_PORT $REPORTS_PORT 5556 5557

# Start all servers as oracle user
USER oracle
CMD ["/scripts/startAll.sh"]
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
        hostname \
        motif \
        motif-devel \
        libXext \
        libXtst \
        python39 \
        python39-pip \
        yum && \
    microdnf clean all && \
    yum install -y tigervnc-server xterm xorg-x11-fonts-misc && \
    yum clean all && \
    python3.9 -m pip install --upgrade pip && \
    pip3.9 install flask

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

# Continue as oracle user for Forms installation

# Install Oracle Forms & Reports 14c using the installer help first
RUN echo "=== CHECKING FORMS INSTALLER HELP ===" && \
    /install/fmw_14.1.2.0.0_fr_linux64.bin -help 2>&1 | head -50 || echo "Help not available"

# Try Oracle's recommended approach - no response file first
RUN echo "=== STARTING FORMS & REPORTS INSTALLATION ===" && \
    echo "Verifying Forms installer exists:" && \
    ls -la /install/fmw_14.1.2.0.0_fr_linux64.bin && \
    echo "" && \
    echo "=== ATTEMPT 1: Oracle Default Installation ===" && \
    echo "Using Oracle Home parameter only..." && \
    /install/fmw_14.1.2.0.0_fr_linux64.bin \
        -silent \
        -oh $ORACLE_HOME \
        -invPtrLoc /etc/oraInst.loc \
        -ignoreSysPrereqs \
        -jreLoc $JAVA_HOME \
        -force; \
    ATTEMPT1_EXIT=$? && \
    echo "ATTEMPT 1 EXIT CODE: $ATTEMPT1_EXIT" && \
    if [ $ATTEMPT1_EXIT -eq 0 ]; then \
        echo "✅ Oracle default installation succeeded"; \
    else \
        echo "❌ Oracle default failed, trying with complete response file"; \
        echo "" && \
        echo "=== ATTEMPT 2: Complete Forms Installation ===" && \
        echo "Response file content:" && \
        cat /response/forms_reports_complete.rsp && \
        /install/fmw_14.1.2.0.0_fr_linux64.bin \
            -silent \
            -responseFile /response/forms_reports_complete.rsp \
            -invPtrLoc /etc/oraInst.loc \
            -jreLoc $JAVA_HOME \
            -ignoreSysPrereqs \
            -force; \
        ATTEMPT2_EXIT=$? && \
        echo "ATTEMPT 2 EXIT CODE: $ATTEMPT2_EXIT" && \
        if [ $ATTEMPT2_EXIT -eq 0 ]; then \
            echo "✅ Complete Forms installation succeeded"; \
        else \
            echo "❌ Complete installation failed, trying SOFTWARE_ONLY"; \
            echo "" && \
            echo "=== ATTEMPT 3: SOFTWARE_ONLY Installation ===" && \
            cat /response/forms_reports_software_only.rsp && \
            /install/fmw_14.1.2.0.0_fr_linux64.bin \
                -silent \
                -responseFile /response/forms_reports_software_only.rsp \
                -invPtrLoc /etc/oraInst.loc \
                -jreLoc $JAVA_HOME \
                -ignoreSysPrereqs \
                -force; \
            ATTEMPT3_EXIT=$? && \
            echo "ATTEMPT 3 EXIT CODE: $ATTEMPT3_EXIT" && \
            if [ $ATTEMPT3_EXIT -eq 0 ]; then \
                echo "✅ SOFTWARE_ONLY installation succeeded"; \
            else \
                echo "❌ SOFTWARE_ONLY failed, trying COMPLETE"; \
                echo "" && \
                echo "=== ATTEMPT 4: COMPLETE Installation ===" && \
                cat /response/forms_reports_basic.rsp && \
                /install/fmw_14.1.2.0.0_fr_linux64.bin \
                    -silent \
                    -responseFile /response/forms_reports_basic.rsp \
                    -invPtrLoc /etc/oraInst.loc \
                    -jreLoc $JAVA_HOME \
                    -ignoreSysPrereqs \
                    -force; \
                ATTEMPT4_EXIT=$? && \
                echo "ATTEMPT 4 EXIT CODE: $ATTEMPT4_EXIT" && \
                if [ $ATTEMPT4_EXIT -eq 0 ]; then \
                    echo "✅ COMPLETE installation succeeded"; \
                else \
                    echo "❌ All installation attempts failed"; \
                    echo "Checking error logs for debugging..."; \
                    ls -la /tmp/OraInstall*/install*.log 2>/dev/null || echo "No installation logs found"; \
                fi; \
            fi; \
        fi; \
    fi && \
    echo "" && \
    echo "=== FINAL INSTALLATION CHECK ===" && \
    ls -la $ORACLE_HOME/ && \
    echo "=== SEARCHING FOR FORMS COMPONENTS ===" && \
    ls -la $ORACLE_HOME/bin/ 2>/dev/null | grep -E "(frm|rep)" || echo "No Forms binaries found" && \
    echo "=== SEARCHING FOR FORMS DIRECTORIES ===" && \
    ls -la $ORACLE_HOME/ | grep -iE "(form|report)" || echo "No Forms/Reports directories found"

# Switch back to root for domain creation and final checks
USER root

# Run comprehensive Forms installation check
RUN chmod +x /scripts/checkFormsInstallation.sh && \
    /scripts/checkFormsInstallation.sh

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

# Domain will be created manually using config.sh via VNC
# No automatic domain creation during Docker build

# Copy Reports web gateway
COPY reports_web_gateway.py /scripts/reports_web_gateway.py
RUN chmod +x /scripts/reports_web_gateway.py

# Copy Reports domain configuration script (for reference, not used during build)
COPY scripts/configureReportsDomain.py /scripts/configureReportsDomain.py
RUN chmod +x /scripts/configureReportsDomain.py

# Domain extension will be done via config.sh wizard after VNC connection

# Configure VNC for oracle user
USER oracle
RUN mkdir -p /home/oracle/.vnc && \
    echo "Oracle123" | vncpasswd -f > /home/oracle/.vnc/passwd && \
    chmod 600 /home/oracle/.vnc/passwd && \
    echo '#!/bin/sh' > /home/oracle/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /home/oracle/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /home/oracle/.vnc/xstartup && \
    echo 'export ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0' >> /home/oracle/.vnc/xstartup && \
    echo 'export JAVA_HOME=/u01/app/oracle/product/jdk17' >> /home/oracle/.vnc/xstartup && \
    echo 'export PATH=$ORACLE_HOME/oracle_common/common/bin:$JAVA_HOME/bin:$PATH' >> /home/oracle/.vnc/xstartup && \
    echo 'xrdb $HOME/.Xresources 2>/dev/null || true' >> /home/oracle/.vnc/xstartup && \
    echo 'xsetroot -solid grey 2>/dev/null || true' >> /home/oracle/.vnc/xstartup && \
    echo 'xterm -geometry 100x30+10+10 -ls -title "Oracle Terminal" &' >> /home/oracle/.vnc/xstartup && \
    chmod +x /home/oracle/.vnc/xstartup

# Expose ports (including VNC 5901)
EXPOSE $ADMIN_PORT $FORMS_PORT $REPORTS_PORT 5556 5557 8888 5901

# Start all servers as oracle user
CMD ["/scripts/startAll.sh"]
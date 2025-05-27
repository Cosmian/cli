# Instructions to build a SQL Server 2022 container with systemd and SSH
#
# Build:
# For Apple Silicon Macs, use emulation:
# docker buildx build . --platform linux/amd64 -t sql22_u2204:latest
# For Intel/AMD systems:
# docker buildx build . -t sql22_u2204:latest
#
# Run with proper systemd support:
# docker run -d --name sql22 --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host -p 1433:1433 -p 2222:22 sql22_u2204:latest

FROM ubuntu:22.04

# Update packages
RUN apt-get update && apt-get upgrade -y

# Install systemd for systemctl
RUN apt-get install -y systemd systemd-sysv

# Install openssh-server and related utilities
RUN apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    systemctl enable ssh

# Install vim
RUN apt-get install -y vim

# Install net-tools (ifconfig, telnet, ip address)
RUN apt-get install -y net-tools iputils-ping telnet iproute2

# Install dependencies for SQL Server
RUN apt-get install -y curl gnupg2 software-properties-common

# Import SQL Server public repository GPG keys
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

# Register the SQL Server Ubuntu repository
RUN add-apt-repository "$(curl https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)"

# Install SQL Server
RUN apt-get update && apt-get install -y mssql-server

# Configure SQL Server
RUN mkdir -p /var/opt/mssql/data && \
    chown mssql:mssql /var/opt/mssql/data && \
    mkdir -p /var/opt/mssql/log && \
    chown mssql:mssql /var/opt/mssql/log && \
    mkdir -p /var/opt/mssql/secrets && \
    chown mssql:mssql /var/opt/mssql/secrets

## See doc at https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-ver16&tabs=ubuntu2204

# Add SQL Server tools to PATH
ENV PATH="$PATH:/opt/mssql-tools/bin"

# Clean up apt cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Keep systemd from starting too many processes and configure for container
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

# Create required directories for systemd and set up tmpfs
RUN mkdir -p /run /run/lock /run/systemd /var/lib/systemd && \
    chmod 755 /run /run/lock

# Configure systemd for container environment
RUN systemctl set-default multi-user.target && \
    systemctl mask systemd-firstboot.service systemd-udevd.service

# Create systemd override directory for mssql-server to handle container environment
RUN mkdir -p /etc/systemd/system/mssql-server.service.d && \
    echo '[Service]' > /etc/systemd/system/mssql-server.service.d/container.conf && \
    echo 'Type=notify' >> /etc/systemd/system/mssql-server.service.d/container.conf && \
    echo 'NotifyAccess=all' >> /etc/systemd/system/mssql-server.service.d/container.conf && \
    echo 'KillMode=mixed' >> /etc/systemd/system/mssql-server.service.d/container.conf

# Preserve SSH and SQL Server systemd services
RUN mkdir -p /lib/systemd/system/multi-user.target.wants/ && \
    ln -sf /lib/systemd/system/mssql-server.service /lib/systemd/system/multi-user.target.wants/mssql-server.service && \
    ln -sf /lib/systemd/system/ssh.service /lib/systemd/system/multi-user.target.wants/ssh.service

# Configure systemd to properly handle container environment
RUN mkdir -p /etc/systemd/system.conf.d && \
    echo '[Manager]' > /etc/systemd/system.conf.d/container.conf && \
    echo 'LogLevel=info' >> /etc/systemd/system.conf.d/container.conf && \
    echo 'LogTarget=console' >> /etc/systemd/system.conf.d/container.conf

# Set systemd as entrypoint (PID 1) with container-friendly options
ENTRYPOINT ["/lib/systemd/systemd", "--system", "--unit=multi-user.target", "--log-level=info"]

# Create SQL Server setup service that runs once
RUN echo '[Unit]' > /etc/systemd/system/mssql-server-setup.service && \
    echo 'Description=SQL Server First-Time Setup' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'After=multi-user.target' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'Before=mssql-server.service' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'ConditionPathExists=!/var/opt/mssql/.sql-server-setup-completed' >> /etc/systemd/system/mssql-server-setup.service && \
    echo '' >> /etc/systemd/system/mssql-server-setup.service && \
    echo '[Service]' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'ExecStart=/usr/local/bin/sql-server-setup.sh' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'RemainAfterExit=true' >> /etc/systemd/system/mssql-server-setup.service && \
    echo '' >> /etc/systemd/system/mssql-server-setup.service && \
    echo '[Install]' >> /etc/systemd/system/mssql-server-setup.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/mssql-server-setup.service

# Create SQL Server setup script
RUN echo '#!/bin/bash' > /usr/local/bin/sql-server-setup.sh && \
    echo 'SETUP_FLAG="/var/opt/mssql/.sql-server-setup-completed"' >> /usr/local/bin/sql-server-setup.sh && \
    echo 'echo "Setting up SQL Server for the first time..."' >> /usr/local/bin/sql-server-setup.sh && \
    echo 'export MSSQL_SA_PASSWORD="YourStrong!Passw0rd"' >> /usr/local/bin/sql-server-setup.sh && \
    echo 'export ACCEPT_EULA="Y"' >> /usr/local/bin/sql-server-setup.sh && \
    echo '/opt/mssql/bin/mssql-conf setup accept-eula' >> /usr/local/bin/sql-server-setup.sh && \
    echo 'systemctl enable mssql-server' >> /usr/local/bin/sql-server-setup.sh && \
    echo 'touch "$SETUP_FLAG"' >> /usr/local/bin/sql-server-setup.sh && \
    echo 'echo "SQL Server setup completed!"' >> /usr/local/bin/sql-server-setup.sh && \
    chmod +x /usr/local/bin/sql-server-setup.sh

# Enable the setup service
RUN systemctl enable mssql-server-setup.service

# Set up SSH keys and configuration
RUN ssh-keygen -A && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set SQL Server environment variables
ENV MSSQL_SA_PASSWORD="YourStrong!Passw0rd"
ENV ACCEPT_EULA="Y"
ENV MSSQL_PID="Developer"

# Create a helpful startup message
RUN echo '#!/bin/bash' > /usr/local/bin/startup-info.sh && \
    echo 'echo "=== SQL Server 2022 Container with SystemD ==="' >> /usr/local/bin/startup-info.sh && \
    echo 'echo "SQL Server SA Password: $MSSQL_SA_PASSWORD"' >> /usr/local/bin/startup-info.sh && \
    echo 'echo "SSH: ssh root@localhost -p 2222 (password: password)"' >> /usr/local/bin/startup-info.sh && \
    echo 'echo "SQL Server will be automatically configured on first boot."' >> /usr/local/bin/startup-info.sh && \
    echo 'echo "Check status: systemctl status mssql-server"' >> /usr/local/bin/startup-info.sh && \
    echo 'echo "============================================="' >> /usr/local/bin/startup-info.sh && \
    chmod +x /usr/local/bin/startup-info.sh

# Add startup info to bashrc
RUN echo '/usr/local/bin/startup-info.sh' >> /etc/bash.bashrc


# Expose SQL Server and SSH ports
EXPOSE 1433 22

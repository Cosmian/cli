# SQL Server 2022 with SystemD Container

This Docker container provides SQL Server 2022 running on Ubuntu 22.04 with SystemD support for proper service management.

## Option 1: Standard SQL Server Container (Simple)

For basic SQL Server usage without SystemD:

```bash
docker pull mcr.microsoft.com/mssql/server:2022-latest
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Password@92" \
   -p 1433:1433 --name sql2022 --hostname sql2022 \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest
```

## Option 2: Custom Container with SystemD Support

### Building the Container

```bash
docker buildx build . --platform linux/amd64 -t sql22_u2204:latest
```

### Running the Container

The container requires specific flags to properly support SystemD:

```bash
docker run -d \
  --name sql22 \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cgroupns=host \
  -p 1433:1433 \
  -p 2222:22 \
  sql22_u2204:latest
```

#### Required Docker Flags Explained

- `--privileged`: Required for SystemD to manage services properly
- `-v /sys/fs/cgroup:/sys/fs/cgroup:rw`: Mounts cgroup filesystem for SystemD
- `--cgroupns=host`: Uses host cgroup namespace to avoid permission issues
- `-p 1433:1433`: Exposes SQL Server port
- `-p 2222:22`: Exposes SSH port (mapped to 2222 to avoid conflicts)

### Connecting to the Container

#### SSH Access
```bash
ssh root@localhost -p 2222
# Password: password
```

#### SQL Server Connection
- **Server**: `localhost,1433`
- **Username**: `sa`
- **Password**: `YourStrong!Passw0rd`

### Service Management

Once inside the container, you can manage services using SystemD:

```bash
# Check SQL Server status
systemctl status mssql-server

# Start/stop SQL Server
systemctl start mssql-server
systemctl stop mssql-server

# Check SSH status
systemctl status ssh

# View all services
systemctl list-units --type=service
```

### SQL Server Configuration

SQL Server is automatically configured on first boot with:
- SA Password: `YourStrong!Passw0rd`
- Edition: Developer
- EULA: Accepted

The configuration is handled by a one-time SystemD service (`mssql-server-setup.service`) that runs before the main SQL Server service.

### Troubleshooting

#### Container won't start with SystemD errors
- Ensure you're running with `--privileged` flag
- Verify cgroup mount: `-v /sys/fs/cgroup:/sys/fs/cgroup:rw`
- Check that `--cgroupns=host` is included

#### SQL Server not starting
- Check logs: `journalctl -u mssql-server -f`
- Verify setup completed: `ls -la /var/opt/mssql/.sql-server-setup-completed`
- Manual setup: `/usr/local/bin/sql-server-setup.sh`

#### SSH connection refused
- Verify SSH service: `systemctl status ssh`
- Check if port 2222 is available on host
- Restart SSH: `systemctl restart ssh`

### Container Architecture

This container uses SystemD as PID 1, which allows proper service management including:
- Automatic service startup/shutdown
- Service dependency management
- Proper signal handling
- Standard Linux service management tools

The SQL Server setup is handled by a custom SystemD service that runs once on first boot, ensuring SQL Server is properly configured before the main service starts.


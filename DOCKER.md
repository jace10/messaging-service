# Docker Setup for Messaging Service

This document explains how to run the messaging service using Docker with all dependencies included.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed on your system
- No need to install CMake, C++ compiler, or cpp-httplib locally

### Running the Service

1. **Start all services (database + application):**
   ```bash
   docker-compose up --build
   ```

2. **Start in background:**
   ```bash
   docker-compose up -d --build
   ```

3. **Stop services:**
   ```bash
   docker-compose down
   ```

4. **View logs:**
   ```bash
   # All services
   docker-compose logs -f
   
   # Just the application
   docker-compose logs -f messaging-service
   
   # Just the database
   docker-compose logs -f postgres
   ```

## Services

### Messaging Service Application
- **Container:** `messaging-service-app`
- **Port:** 8080
- **Health Check:** `GET /health`
- **Dependencies:** PostgreSQL database

### PostgreSQL Database
- **Container:** `messaging-service-db`
- **Port:** 5432
- **Database:** `messaging_service`
- **User:** `messaging_user`
- **Password:** `messaging_password`

## API Endpoints

Once running, the service provides these endpoints:

- `GET /health` - Health check
- `POST /api/messages/sms` - Send SMS/MMS
- `POST /api/messages/email` - Send Email
- `POST /api/webhooks/sms` - Incoming SMS/MMS webhook
- `POST /api/webhooks/email` - Incoming Email webhook
- `GET /api/conversations` - Get conversations
- `GET /api/conversations/{id}/messages` - Get messages for a conversation

## Testing the Service

### Health Check
```bash
curl http://localhost:8080/health
```

### Send SMS
```bash
curl -X POST http://localhost:8080/api/messages/sms \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+18045551234",
    "to": "+12016661234",
    "type": "sms",
    "body": "Hello from Docker!",
    "timestamp": "2024-11-01T14:00:00Z"
  }'
```

### Get Conversations
```bash
curl http://localhost:8080/api/conversations
```

## Database Access

### Connect to Database
```bash
docker-compose exec postgres psql -U messaging_user -d messaging_service
```

### View Database Schema
```sql
\dt  -- List tables
\d conversations  -- Describe conversations table
\d messages  -- Describe messages table
```

## Development

### Rebuild After Code Changes
```bash
docker-compose up --build
```

### Run Only Database
```bash
docker-compose up postgres
```

### Clean Up
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: This deletes all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Troubleshooting

### Service Won't Start
1. Check if port 8080 is already in use:
   ```bash
   lsof -i :8080
   ```

2. Check Docker logs:
   ```bash
   docker-compose logs messaging-service
   ```

### Database Connection Issues
1. Ensure PostgreSQL is healthy:
   ```bash
   docker-compose ps
   ```

2. Check database logs:
   ```bash
   docker-compose logs postgres
   ```

### Build Issues
1. Clean Docker cache:
   ```bash
   docker system prune -a
   ```

2. Rebuild without cache:
   ```bash
   docker-compose build --no-cache
   ```

## Environment Variables

The messaging service container supports these environment variables:

- `DB_HOST` - Database host (default: postgres)
- `DB_PORT` - Database port (default: 5432)
- `DB_NAME` - Database name (default: messaging_service)
- `DB_USER` - Database user (default: messaging_user)
- `DB_PASSWORD` - Database password (default: messaging_password)

## Production Considerations

For production deployment, consider:

1. **Security:**
   - Change default database credentials
   - Use Docker secrets for sensitive data
   - Enable SSL/TLS for database connections

2. **Performance:**
   - Use multi-stage Docker builds
   - Optimize container resource limits
   - Use connection pooling

3. **Monitoring:**
   - Add logging to files
   - Implement metrics collection
   - Set up health monitoring

4. **Scaling:**
   - Use Docker Swarm or Kubernetes
   - Implement load balancing
   - Use external database services

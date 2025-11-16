# Environment Variables

The frontend application now supports the following environment variables:

## Frontend Configuration

- `PORT`: Port for the frontend server (default: 3000)

## Backend Configuration (for internal proxy)

- `BACKEND_HOST`: Backend hostname or IP address (default: "backend")
- `BACKEND_PORT`: Backend port (default: "8080")

## Proxy Configuration

The frontend now acts as a proxy for the backend API. All requests to `/api/*` are automatically forwarded to the backend service. This means:

- Frontend calls `/api/orders` → Backend receives `/orders`
- No CORS issues since requests are same-origin
- Backend doesn't need to be exposed externally

## Usage

### Development

Set environment variables before running the server:

```bash
export BACKEND_HOST=localhost
export BACKEND_PORT=8083
export PORT=3000
node server.js
```

### Docker

Pass environment variables in docker run command:

```bash
docker run -e BACKEND_HOST=localhost -e BACKEND_PORT=8083 -p 3000:3000 frontend
```

### Docker Compose

Add to your docker-compose.yml:

```yaml
services:
  frontend:
    build: ./frontend
    environment:
      - BACKEND_HOST=orders-api
      - BACKEND_PORT=8080
      - PORT=3000
    ports:
      - "3000:3000"
```

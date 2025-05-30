#!/bin/bash

echo "🧪 Testing NGINX reverse proxy locally..."

# Build the image
echo "Building Docker image..."
docker build -t preview-proxy-test .

# Run the container
echo "Starting container on port 8080..."
docker run -d --name preview-proxy-test -p 8080:80 preview-proxy-test

# Wait a moment for startup
sleep 3

echo "Testing health endpoint..."
curl -v http://localhost:8080/health

echo ""
echo "Testing with preview domain (should proxy to GCS)..."
curl -v -H "Host: 44.preview.pano.ai" http://localhost:8080/

echo ""
echo "Testing with invalid host (should get 404)..."
curl -v -H "Host: invalid.example.com" http://localhost:8080/

echo ""
echo "Cleaning up..."
docker stop preview-proxy-test
docker rm preview-proxy-test

echo "✅ Local testing complete!" 
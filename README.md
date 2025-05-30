# NGINX Reverse Proxy for Preview Builds

This container runs an NGINX reverse proxy that routes requests from `[PR_NUMBER].preview.pano.ai` to the GCP bucket `fe-usc1-pr-previews/[PR_NUMBER]`.

## Build and Run

Build the Docker image:

```bash
docker build -t preview-proxy -f Dockerfile .
```

Run the container:

```bash
docker run -p 80:80 preview-proxy
```

## Configuration

The NGINX configuration is in `nginx.conf`. It routes requests from any subdomain matching the pattern `[PR_NUMBER].preview.pano.ai` to the corresponding path in the GCP bucket `fe-usc1-pr-previews/[PR_NUMBER]`. The root path will resolve to `index.html`.

For example:

- `44.preview.pano.ai` routes to `fe-usc1-pr-previews/44/index.html`
- `123.preview.pano.ai` routes to `fe-usc1-pr-previews/123/index.html`

To use this setup, you need to:

1. Configure your DNS to point `*.preview.pano.ai` to the server running this container
2. Ensure the GCP bucket `fe-usc1-pr-previews` is publicly accessible
3. If running locally, add to /etc/hosts `127.0.0.1 {prNumber}.preview.pano.ai`. replace `{prNumber}` with your actual pr number

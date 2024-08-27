# Dockerfile to build a lighttpd container with a custom index.html showing version and DEV/QA/PROD environment.

# Use an Alpine base image
FROM alpine:latest

# Set environment variables with default values
ENV ENV=LOCAL
ENV VERSION=SNAPSHOT

# Install lighttpd
RUN apk add --no-cache lighttpd

# Create the directory for lighttpd HTML files
RUN mkdir -p /var/www/localhost/htdocs

# Create a script to generate index.html with environment variables
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'echo "<!DOCTYPE html><html><head><title>Welcome</title></head><body>" > /var/www/localhost/htdocs/index.html' >> /docker-entrypoint.sh && \
    echo 'echo "<h1>Application: DevOps Test</h1>" >> /var/www/localhost/htdocs/index.html' >> /docker-entrypoint.sh && \
    echo 'echo "<h2>Environment: $ENV</h2>" >> /var/www/localhost/htdocs/index.html' >> /docker-entrypoint.sh && \
    echo 'echo "<h2>Version: $VERSION</h2>" >> /var/www/localhost/htdocs/index.html' >> /docker-entrypoint.sh && \
    echo 'echo "</body></html>" >> /var/www/localhost/htdocs/index.html' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Start lighttpd and generate the index.html at startup
CMD ["/bin/sh", "-c", "/docker-entrypoint.sh && lighttpd -D -f /etc/lighttpd/lighttpd.conf"]

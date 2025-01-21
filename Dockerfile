# Use an R base image
FROM rocker/r-ver:4.3.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libudunits2-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    libgit2-dev \   
    libcurl4-openssl-dev \
    libssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libtiff5-dev \
    libjpeg-dev \
    libpng-dev \
    libxt-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    pkg-config \
    build-essential \
    libgdal-dev \
    git

# Install packages
RUN R -e "install.packages(c('plumber', 'devtools', 'systemfonts', 'ragg', 'textshaping', 'pkgdown'))"
RUN R -e "install.packages('gfwr', repos = c('https://globalfishingwatch.r-universe.dev','https://cran.r-project.org'))"
RUN R -e "install.packages('tidyverse')"
RUN R -e "install.packages('janitor')"
RUN R -e "install.packages('sf')"

# Set environment variables
ENV GFW_API_KEY=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImtpZEtleSJ9.eyJkYXRhIjp7Im5hbWUiOiJ0cmF3bF93YXRjaCIsInVzZXJJZCI6MTk3NTYsImFwcGxpY2F0aW9uTmFtZSI6InRyYXdsX3dhdGNoIiwiaWQiOjIxNzIsInR5cGUiOiJ1c2VyLWFwcGxpY2F0aW9uIn0sImlhdCI6MTczNjg3MTQ2OCwiZXhwIjoyMDUyMjMxNDY4LCJhdWQiOiJnZnciLCJpc3MiOiJnZncifQ.kcwlppP-MkoxG8l9wK-Gf5nVD4I3uMQ1JyoQ7x9b3V3iqVy0IpEGaZ4kqJlkgx2VrpEFjc5uuplRyH5GGJ69znElqucoXeOIxvXMOLtpuwlObwUYUNrzB7pCxgpfwbu79XL0xiGnPkGIFd7ti7MbJSeQxjpImf2J9QPrY1Wmr0wn2teqQlAiwehKPe1Se6itXM6PGtIIVYRk5gqiuSttet5_AO6naHYzWF8r1vYqJVsLXYo5Dksp3w8X9iy-uEKUEJtTXI40Nl379e1WQkYHU62HGWc393ruYSNg7PAs1LKbHG7zmCk0A3MXQdqWAi4UujbRiTmpQ1MCJqi7dppALgZNE76sqeP1PtCSBwnOh3jrAI79UGggVqZWJpIdpEIK_C4WMUAEfwa3KvZ8q2KsJg6ZnEeNKmJCNEP07hGAQgdItGKtP9j1fCZVw2l4OMhhcEhsNNT5YV5VFivUh-FHpfl5mM8aemLgd6PgEFdpkRsyI-WnMtnyE2i5ihbDwW_r
ENV GFW_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImtpZEtleSJ9.eyJkYXRhIjp7Im5hbWUiOiJ0cmF3bF93YXRjaCIsInVzZXJJZCI6MTk3NTYsImFwcGxpY2F0aW9uTmFtZSI6InRyYXdsX3dhdGNoIiwiaWQiOjIxNzIsInR5cGUiOiJ1c2VyLWFwcGxpY2F0aW9uIn0sImlhdCI6MTczNjg3MTQ2OCwiZXhwIjoyMDUyMjMxNDY4LCJhdWQiOiJnZnciLCJpc3MiOiJnZncifQ.kcwlppP-MkoxG8l9wK-Gf5nVD4I3uMQ1JyoQ7x9b3V3iqVy0IpEGaZ4kqJlkgx2VrpEFjc5uuplRyH5GGJ69znElqucoXeOIxvXMOLtpuwlObwUYUNrzB7pCxgpfwbu79XL0xiGnPkGIFd7ti7MbJSeQxjpImf2J9QPrY1Wmr0wn2teqQlAiwehKPe1Se6itXM6PGtIIVYRk5gqiuSttet5_AO6naHYzWF8r1vYqJVsLXYo5Dksp3w8X9iy-uEKUEJtTXI40Nl379e1WQkYHU62HGWc393ruYSNg7PAs1LKbHG7zmCk0A3MXQdqWAi4UujbRiTmpQ1MCJqi7dppALgZNE76sqeP1PtCSBwnOh3jrAI79UGggVqZWJpIdpEIK_C4WMUAEfwa3KvZ8q2KsJg6ZnEeNKmJCNEP07hGAQgdItGKtP9j1fCZVw2l4OMhhcEhsNNT5YV5VFivUh-FHpfl5mM8aemLgd6PgEFdpkRsyI-WnMtnyE2i5ihbDwW_r

# Copy the API script into the container
COPY . /app

# Copy the API script into the container
WORKDIR /app

# Expose the port the API will run on
EXPOSE 8080

# Run the Plumber API
CMD ["R", "-e", "plumber::plumb('/app/plumber.R')$run(host='0.0.0.0', port=8080)"]
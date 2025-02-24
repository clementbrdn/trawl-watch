# Use an R base image
FROM rocker/r-ver:4.3.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libudunits2-dev \
    libxml2-dev \
    libsodium-dev \
    libgit2-dev \   
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
    git \
    supervisor \
    cron  

# Install packages
RUN R -e "install.packages(c('plumber', 'devtools', 'systemfonts', 'ragg', 'textshaping', 'pkgdown', 'R.utils'))"
RUN R -e "install.packages('gfwr', repos = c('https://globalfishingwatch.r-universe.dev','https://cran.r-project.org'))"
RUN R -e "install.packages('tidyverse')"
RUN R -e "install.packages('janitor')"
RUN R -e "install.packages('jsonlite')"
RUN R -e "install.packages('sf')"
RUN R -e "install.packages('httr2')"

# Create required directories
RUN mkdir -p /var/log/supervisor

# Copy the API script into the container
COPY . /app
RUN rm /app/crontab /app/supervisord.conf
COPY crontab /etc/cron.d/app-cron
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy the API script into the container
WORKDIR /app

# Ensure proper permissions
RUN chmod 0644 /etc/cron.d/app-cron

# Install the cron job (ensure the user is specified)
RUN crontab /etc/cron.d/app-cron

# Expose API port
EXPOSE 8080

# Start supervisor to manage both services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

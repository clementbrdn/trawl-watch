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

# Copy the API script into the container
COPY . /app

# Copy the API script into the container
WORKDIR /app

# Expose the port the API will run on
EXPOSE 8080

# Run the Plumber API
CMD ["R", "-e", "plumber::plumb('/app/plumber.R')$run(host='0.0.0.0', port=8080)"]
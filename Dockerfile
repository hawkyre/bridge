FROM elixir:1.18.4-otp-27

# Install required packages
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    inotify-tools \
    curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set /app as workdir
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files and install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get

# Copy the rest of the application
COPY . .

# Install assets dependencies and compile
RUN mix assets.setup
RUN mix assets.build

# Compile the application
RUN mix compile

# Expose the port the app runs on
EXPOSE 4000

# Run the Phoenix server
CMD ["mix", "phx.server"] 

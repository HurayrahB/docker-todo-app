# Docker Getting Started Workshop

This repo documents my work through Docker's official [Getting Started Workshop](https://docs.docker.com/get-started/workshop/). The workshop covers containerizing an application, persisting data, using bind mounts for development, connecting multiple containers, and managing everything with Compose.

---

## The App

The app is a simple to-do list built with Node.js and Express. You can add items, check them off, and remove them. Data is stored in a SQLite database, which becomes the central example for understanding persistence: without a volume, every container restart wipes the list clean.

---

## Running It

Make sure you have [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed, then run:

```bash
docker compose up -d --build
```

Then open [http://localhost:3000](http://localhost:3000) in your browser. The app may take a few seconds to start on the first run.

To stop the app:

```bash
docker compose down
```

To stop the app and delete the persisted data volume:

```bash
docker compose down --volumes
```

---

## Project Structure

```bash
getting-started-app/
├── src/                  # Node.js application source
├── Dockerfile            # Instructions for building the app image
├── compose.yaml          # Compose configuration for the full stack
├── .dockerignore         # Files excluded from the Docker build context
└── .gitignore            # Excludes node_modules and other generated files
```

---

## Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

FROM node:24-alpine
WORKDIR /app
COPY . .
RUN npm install --omit=dev
CMD ["node", "src/index.js"]
EXPOSE 3000
```

Each instruction adds a layer to the image, and Docker caches each layer individually. If a layer has not changed since the last build, Docker reuses the cached version and skips it. Instruction order matters because of this: once a layer is invalidated, every layer after it rebuilds too. In a production Dockerfile you would copy `package.json` first, run `npm install`, and then copy the rest of the source so that dependency installation stays cached across routine code changes.

---

## My Learning & Takeaways

## Key Takeaways

Working through this workshop changed how I think about what it means to "run an application." Before Docker, running something locally meant installing dependencies directly on your machine and hoping the environment matched everywhere else. Containers replace that assumption entirely: the environment is defined in code, ships with the app, and runs the same way regardless of what is on the host.

The things that took the most time to internalize were the ones the docs treat as obvious. Layer caching is not just a performance detail, it is something you design your Dockerfile around. The difference between a volume and a bind mount sounds minor until you actually need one instead of the other. And Compose is not just a convenience wrapper around `docker run`, it is where the whole mental model comes together: services, networks, and volumes all declared in one place and reproducible with a single command.

### Part 1: Containerizing the Application

The first step was writing a Dockerfile and running `docker build`. The base image is `node:24-alpine`, a minimal Linux image with Node.js pre-installed, pulled from Docker Hub when it is not already cached locally. Running the container with `-p 127.0.0.1:3000:3000` maps port 3000 on the host to port 3000 inside the container, which is how the browser reaches the app.

### Part 2: Updating the Application

After changing the source code, I had to rebuild the image and replace the running container. Docker does not automatically detect code changes; the image has to be explicitly rebuilt. This reinforced why the `--build` flag exists in `docker compose up`.

### Part 3: Sharing the Application

Images can be pushed to Docker Hub so anyone can pull and run them without having the source code or Dockerfile. This is the same mechanism that makes public base images like `node:24-alpine` available in the first place.

### Part 4: Persisting the Database

By default, a container's filesystem is ephemeral. Any data written inside it disappears when the container is removed. A named volume fixes this by storing data in a location managed by Docker on the host, mounted into the container at a specified path. The SQLite database file is stored in a volume so the to-do list survives restarts.

### Part 5: Using Bind Mounts

A bind mount links a directory on the host machine directly into the container. Unlike a named volume, you control the path on both sides. During development this means you can edit source files on your machine and see the changes reflected inside the container immediately, without rebuilding the image. Running the app with `nodemon` takes advantage of this: nodemon watches for file changes and restarts the server automatically.

### Part 6: Multi-Container Applications

The app was split into two containers: one for the Node.js app and one for a MySQL database. Containers on the same Docker network can reach each other by service name rather than IP address. Docker handles the DNS resolution automatically, so the app container connects to the database using the hostname `mysql` without either container needing a hard-coded IP.

### Part 7: Docker Compose

Compose lets you define the entire application stack in a single `compose.yaml` file, including services, images, ports, volumes, networks, and environment variables. Instead of running long `docker run` commands by hand and setting up networks manually, you bring everything up with one command. The configuration is readable, version-controlled, and reproducible across machines.

### Part 8: Image-Building Best Practices

The workshop covers `docker image history` to inspect layers, multi-stage builds to keep final images lean by separating the build environment from the runtime environment, and `.dockerignore` to exclude files like `node_modules` from the build context so they are not sent to the Docker daemon unnecessarily.

---

## Notes

- `node_modules` is excluded via `.gitignore` and `.dockerignore`. It is generated inside the container by `npm install` and should never be committed to version control.
- On Windows, the line-continuation character `\` used in Docker's documentation does not work in Command Prompt. Use `^` in CMD or a backtick in PowerShell, or put the full command on one line.
- `docker compose up -d --build` forces a rebuild of the image before starting containers. Without `--build`, Compose reuses the cached image even if the Dockerfile or source code changed.

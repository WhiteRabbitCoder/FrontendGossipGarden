# Plant Monitoring API

This project is a FastAPI-based application designed to monitor the environmental conditions of plants. It receives real-time data from IoT sensors via an MQTT broker and exposes a RESTful API to manage plants, define care profiles for different species, and query sensor data.

The application is containerized using Docker for easy setup and deployment.

## Features

-   **Plant Management**: CRUD operations for your plants.
-   **Species Profiles**: Define ideal environmental ranges (temperature, humidity, etc.) for different plant species.
-   **Sensor Data Logging**: Ingests and stores time-series data from sensors.
-   **MQTT Integration**: Subscribes to an MQTT topic to receive real-time sensor data from devices like ESP32.
-   **Database Seeding**: Automatically populates the database with initial sample data for plant species and plants.
-   **Dockerized**: Comes with `Dockerfile` and `docker-compose.yml` for a quick and consistent setup.

## Project Structure

-   **app/**
    -   **core/**
        -   `config.py` - Central configuration (reads .env)
        -   `mqtt_config.py` - MQTT client configuration
    -   **db/**
        -   `base.py` - Imports all SQLModel models
        -   `seed_data.py` - Initial data for the database
        -   `session.py` - Database engine and session management
    -   **plant\_species\_profile/**
        -   `models.py` - Database model for species profiles
        -   `router.py` - API endpoints for species profiles
        -   `schema.py` - Pydantic schemas for species profiles
    -   **plants/**
        -   `models.py` - Database model for plants
        -   `routes.py` - API endpoints for plants
        -   `schemas.py` - Pydantic schemas for plants
    -   **sensor\_data/**
        -   `models.py` - Database model for sensor data
        -   `mqtt_handlers.py` - Logic to handle incoming MQTT messages
        -   `routes.py` - API endpoints for sensor data
        -   `schemas.py` - Pydantic schemas for sensor data
        -   `service.py` - Business logic for saving sensor data
    -   `.gitignore`
    -   `Dockerfile` - Instructions to build the application image
    -   `docker-compose.yml` - Defines services for app and database
    -   `main.py` - Main FastAPI application entrypoint
    -   `requirements.txt` - Python dependencies

## Getting Started

### Prerequisites

-   Docker and Docker Compose

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd <repository-name>
    ```

2.  **Create the environment file:**
    Create a file named `.env` in the project root and add the following environment variables. This file is used by Docker Compose to configure the services.

    ```ini
    # PostgreSQL Settings
    POSTGRES_USER=admin
    POSTGRES_PASSWORD=yoursecretpassword
    POSTGRES_DB=plants_db

    # Application Database URL
    # This must match the PostgreSQL settings above.
    # The hostname 'db' refers to the database service in docker-compose.yml.
    DATABASE_URL=postgresql://admin:yoursecretpassword@db:5432/plants_db
    ```

3.  **Run the application:**
    Use Docker Compose to build and start the containers for the FastAPI application and the PostgreSQL database.

    ```bash
    docker-compose up --build
    ```
    The API will be available at `http://localhost:8000`.

## Environment Variables

The application is configured using environment variables.

| Variable          | Description                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------- |
| `DATABASE_URL`    | The connection string for the PostgreSQL database. Example: `postgresql://USER:PASSWORD@HOST:PORT/DBNAME` |
| `POSTGRES_USER`   | The username for the PostgreSQL database.                                                               |
| `POSTGRES_PASSWORD`| The password for the PostgreSQL database.                                                               |
| `POSTGRES_DB`     | The name of the database to create.                                                                     |

**Note:** The MQTT client credentials are currently hardcoded in `app/core/mqtt_config.py`. For a production environment, it is highly recommended to move these into environment variables as well.

## API Endpoints

The API is structured into different resources.

### Root

-   `GET /`
    -   **Description**: Returns a welcome message to confirm the API is running.
    -   **Response**: `{"message": "Api running..."}`

### Plants (`/plants`)

-   `GET /`
    -   **Description**: Retrieves a list of all registered plants.
-   `GET /{plant_id}`
    -   **Description**: Retrieves a specific plant by its ID.
-   `POST /`
    -   **Description**: Creates a new plant.
    -   **Request Body**:
        ```json
        {
          "name": "My new plant",
          "location": "Office",
          "plant_species_id": 1,
          "visibility": 1
        }
        ```

### Plant Species (`/plant_species`)

-   `GET /`
    -   **Description**: Retrieves a list of all plant species profiles.
-   `GET /{specie_id}`
    -   **Description**: Retrieves a specific species profile by its ID.
-   `POST /`
    -   **Description**: Creates a new plant species profile.
    -   **Request Body**:
        ```json
        {
          "specie_name": "Cactus",
          "personality": "Resilient",
          "min_temperature": 18.0,
          "max_temperature": 35.0,
          "min_humidity": 10.0,
          "max_humidity": 30.0,
          "min_soil_moisture": 5.0,
          "max_soil_moisture": 20.0,
          "min_light": 1000.0,
          "max_light": 5000.0,
          "care_instructions": "Water sparingly and provide plenty of direct sunlight."
        }
        ```

### Sensor Data (`/sensor_data`)

-   `POST /`
    -   **Description**: Saves a new sensor data reading. This is an alternative to using MQTT.
    -   **Request Body**:
        ```json
        {
          "plant_id": 1,
          "timestamp": "2023-10-27T10:00:00Z",
          "sensors": {
            "temperature": 22.5,
            "humidity": 45.0,
            "soil_moisture": 25.0,
            "light": 800.0
          }
        }
        ```

## MQTT Integration

The application includes an MQTT client that automatically connects and subscribes to a topic to receive sensor data.

-   **Topic**: `plantas/esp32_01/sensores`
-   **Action**: On message, the client parses the JSON payload, validates it, and saves the data to the database.
-   **Expected Payload Format**:
    ```json
    {
      "plant_id": 1,
      "timestamp": "2023-10-27T10:00:00Z",
      "sensors": {
        "temperature": 22.5,
        "humidity": 45.0,
        "soil_moisture": 25.0,
        "light": 800.0
      }
    }
    ```
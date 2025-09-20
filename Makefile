.PHONY: setup run test clean help db-up db-down db-logs db-shell build stop check-deps

help:
	@echo "Available commands:"
	@echo "  setup      - Set up the project environment and start database"
	@echo "  build      - Build the C++ application"
	@echo "  run        - Run the application"
	@echo "  stop       - Stop the application"
	@echo "  test       - Run tests"
	@echo "  clean      - Clean up temporary files and stop containers"
	@echo "  check-deps - Check if all required dependencies are installed"
	@echo "  db-up      - Start the PostgreSQL database"
	@echo "  db-down    - Stop the PostgreSQL database"
	@echo "  db-logs    - Show database logs"
	@echo "  db-shell   - Connect to the database shell"
	@echo "  help       - Show this help message"

setup:
	@echo "Setting up the project..."
	@echo "Starting PostgreSQL database..."
	@docker-compose up -d
	@echo "Waiting for database to be ready..."
	@sleep 5
	@echo "Setup complete!"

build:
	@echo "Building C++ application..."
	@mkdir -p build
	@cd build && cmake .. && make -j$$(nproc 2>/dev/null || sysctl -n hw.ncpu)

run:
	@echo "Running the application..."
	@./bin/start.sh

stop:
	@echo "Stopping the application..."
	@./bin/stop.sh

check-deps:
	@echo "Checking dependencies..."
	@./bin/check-deps.sh

test:
	@echo "Running tests..."
	@echo "Starting test database if not running..."
	@docker-compose up -d
	@echo "Running test script..."
	@./bin/test.sh

clean:
	@echo "Cleaning up..."
	@echo "Stopping and removing containers..."
	@docker-compose down -v
	@echo "Removing any temporary files..."
	@rm -rf *.log *.tmp

db-up:
	@echo "Starting PostgreSQL database..."
	@docker-compose up -d

db-down:
	@echo "Stopping PostgreSQL database..."
	@docker-compose down

db-logs:
	@echo "Showing database logs..."
	@docker-compose logs -f postgres

db-shell:
	@echo "Connecting to database shell..."
	@docker-compose exec postgres psql -U messaging_user -d messaging_service
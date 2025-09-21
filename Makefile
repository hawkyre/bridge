console:
	@docker exec -it bridge sh -c 'echo "Application.put_env(:elixir, :ansi_enabled, :true)" > ~/.iex.exs'
	@docker exec -it bridge sh -c 'iex --erl "-kernel shell_history enabled" --cookie bridge --remsh bridge@$$(hostname)'

db:
	@docker exec -it bridge-db psql -U postgres -d bridge_dev

x:
	@docker exec bridge $(filter-out $@,$(MAKECMDGOALS))

up:
	@docker compose up -d

up*:
	@docker compose up

re:
	@docker compose restart bridge

logs:
	@docker compose logs -f bridge

ssh:
	@fly ssh console --pty --select -C "/app/bin/bridge remote"

tests:
	@docker compose --profile test up test --build

test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Please specify a test file. Usage: make test-file FILE=path/to/test_file.exs"; \
		exit 1; \
	fi
	@docker compose run --rm test bash -c "mix deps.get && mix ecto.create && mix ecto.migrate && mix test $(FILE)"